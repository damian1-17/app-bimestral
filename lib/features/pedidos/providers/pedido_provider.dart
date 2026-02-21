import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';
// import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';
// import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';



import 'package:tarea_bimestre/features/pedidos/models/pedido_local_model.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';


enum PedidoStatus { idle, loading, success, error }

class PedidoProvider extends ChangeNotifier {
  PedidoStatus _status     = PedidoStatus.idle;
  String       _error      = '';
  String       _successMsg = '';

  PedidoStatus get status     => _status;
  String       get error      => _error;
  String       get successMsg => _successMsg;

  /// Guarda el pedido en SQLite (siempre) y luego intenta sincronizar con la API.
  /// Si no hay internet, queda en estado "pendiente".
  Future<bool> crearPedido({
    required ClienteModel?     cliente,
    required String            nombreCliente,
    required String            cedula,
    required String            direccion,
    required String            telefono,
    required String            email,
    required String            formaPago,
    required List<CarritoItem> items,
    required double            descuentoGlobal,
    required String?           observaciones,
    required double?           latitud,
    required double?           longitud,
    required File?             foto,
  }) async {
    _status = PedidoStatus.loading;
    _error  = '';
    notifyListeners();

    try {
      // 1️⃣ Convertir foto a base64 si existe
      String? fotoBase64;
      if (foto != null) {
        final bytes = await foto.readAsBytes();
        fotoBase64  = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // 2️⃣ Serializar items del carrito
      final itemsMap = items.map((i) => {
        'idProducto':     i.producto.idProducto,
        'nombreProducto': i.producto.nombre,
        'cantidad':       i.cantidad,
        'precioUnitario': i.producto.precio,
        'descuento':      0,
      }).toList();

      // 3️⃣ Construir el modelo local
      final pedidoLocal = PedidoLocalModel(
        nombreCliente: nombreCliente,
        cedula:        cedula,
        direccion:     direccion,
        telefono:      telefono,
        email:         email.isNotEmpty ? email : null,
        formaPago:     formaPago,
        descuento:     descuentoGlobal,
        observaciones: observaciones,
        latitud:       latitud,
        longitud:      longitud,
        fotoPath:      foto?.path,
        items:         itemsMap,
        estado:        EstadoPedido.pendiente,   // siempre empieza pendiente
        idCliente:     cliente?.idUsuario,
        createdAt:     DateTime.now(),
      );

      // 4️⃣ Guardar en SQLite — SIEMPRE, con o sin internet
      final localId = await DatabaseHelper.instance.insertarPedido(
        pedidoLocal.toDb(),
      );

      // 5️⃣ Intentar sincronizar con la API
      final sincronizado = await _sincronizarConApi(
        localId:   localId,
        pedido:    pedidoLocal,
        fotoBase64: fotoBase64,
      );

      if (sincronizado) {
        _successMsg = 'Pedido creado y sincronizado exitosamente.';
      } else {
        _successMsg = 'Pedido guardado localmente. Se sincronizará cuando haya conexión.';
      }

      _status = PedidoStatus.success;
      notifyListeners();
      return true;

    } catch (e) {
      _error  = 'Error al guardar el pedido: $e';
      _status = PedidoStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Intenta enviar el pedido a la API. Retorna true si tuvo éxito.
  Future<bool> _sincronizarConApi({
    required int              localId,
    required PedidoLocalModel pedido,
    required String?          fotoBase64,
  }) async {
    try {
      final body = <String, dynamic>{
        'nombreCliente': pedido.nombreCliente,
        'cedula':        pedido.cedula,
        'direccion':     pedido.direccion,
        'telefono':      pedido.telefono,
        'email':         pedido.email ?? '',
        'formaPago':     pedido.formaPago,
        'detalles':      pedido.items,
        'descuento':     pedido.descuento,
      };

      if (pedido.idCliente  != null) body['idCliente']     = pedido.idCliente;
      if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty)
                                      body['observaciones'] = pedido.observaciones;
      if (pedido.latitud    != null)  body['latitud']       = pedido.latitud;
      if (pedido.longitud   != null)  body['longitud']      = pedido.longitud;
      if (fotoBase64        != null)  body['fotoBase64']    = fotoBase64;

      final response = await DioClient.instance
          .post('facturacion/directa', data: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await DatabaseHelper.instance.actualizarEstado(
            localId, EstadoPedido.sincronizado.valor);
        return true;
      } else {
        final msg = response.data['message']?.toString() ??
            'Error ${response.statusCode}';
        await DatabaseHelper.instance.actualizarEstado(
            localId, EstadoPedido.error.valor, errorMsg: msg);
        return false;
      }
    } catch (_) {
      // Sin internet u otro error → queda en pendiente (no marcamos error)
      return false;
    }
  }

  void reset() {
    _status     = PedidoStatus.idle;
    _error      = '';
    _successMsg = '';
    notifyListeners();
  }
}