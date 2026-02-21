import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';

enum PedidoStatus { idle, loading, success, error }

class PedidoProvider extends ChangeNotifier {
  PedidoStatus _status     = PedidoStatus.idle;
  String       _error      = '';
  String       _successMsg = '';

  PedidoStatus get status     => _status;
  String       get error      => _error;
  String       get successMsg => _successMsg;

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
      final itemsMap = items.map((i) => {
        'idProducto':     i.producto.idProducto,
        'nombreProducto': i.producto.nombre,
        'cantidad':       i.cantidad,
        'precioUnitario': i.producto.precio,
        'descuento':      0,
      }).toList();

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
        estado:        EstadoPedido.pendiente,
        idCliente:     cliente?.idUsuario,
        createdAt:     DateTime.now(),
      );

      // 1️⃣ Guardar siempre en SQLite primero
      final localId = await DatabaseHelper.instance.insertarPedido(
          pedidoLocal.toDb());

      // 2️⃣ Validar que tiene idCliente antes de intentar sincronizar
      if (cliente == null) {
        await DatabaseHelper.instance.actualizarEstado(
          localId,
          EstadoPedido.error.valor,
          errorMsg: 'Sin cliente asignado. Selecciona un cliente para sincronizar.',
        );
        _successMsg = 'Pedido guardado localmente. Asigna un cliente para poder sincronizarlo.';
        _status = PedidoStatus.success;
        notifyListeners();
        return true;
      }

      // 3️⃣ Intentar sincronizar con la API (sin foto)
      final idFactura = await _sincronizarSinFoto(
          localId: localId, pedido: pedidoLocal);

      // 4️⃣ Si se creó la factura, enviar foto por separado
      if (idFactura != null && foto != null) {
        await _enviarFoto(localId: localId, idFactura: idFactura, foto: foto,
            latitud: latitud, longitud: longitud);
      }

      if (idFactura != null) {
        _successMsg = 'Pedido creado y sincronizado exitosamente.';
      } else {
        _successMsg = 'Pedido guardado. Se sincronizará cuando haya conexión.';
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

  /// Crea la factura sin foto. Retorna el idFactura si fue exitoso, null si falló.
  Future<int?> _sincronizarSinFoto({
    required int              localId,
    required PedidoLocalModel pedido,
  }) async {
    try {
      final body = <String, dynamic>{
        'idCliente':     pedido.idCliente,
        'nombreCliente': pedido.nombreCliente,
        'cedula':        pedido.cedula,
        'direccion':     pedido.direccion,
        'telefono':      pedido.telefono,
        'email':         pedido.email ?? '',
        'formaPago':     pedido.formaPago,
        'detalles':      pedido.items,
        'descuento':     pedido.descuento,
      };

      if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty)
        body['observaciones'] = pedido.observaciones;
      if (pedido.latitud  != null) body['latitud']  = pedido.latitud;
      if (pedido.longitud != null) body['longitud'] = pedido.longitud;

      final response = await DioClient.instance
          .post('facturacion/directa', data: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Guardar estado sincronizado (la foto se sube aparte)
        await DatabaseHelper.instance.actualizarEstado(
            localId, EstadoPedido.sincronizado.valor);
        // Extraer id de la factura creada para subir la foto
        final id = response.data['id'] ??
                   response.data['idFactura'] ??
                   response.data['data']?['id'];
        return id as int?;
      } else {
        final msg = response.data?['message']?.toString() ??
            'Error ${response.statusCode}';
        await DatabaseHelper.instance.actualizarEstado(
            localId, EstadoPedido.error.valor, errorMsg: msg);
        return null;
      }
    } catch (_) {
      // Sin conexión → queda pendiente (no es error, se reintentará)
      return null;
    }
  }

  /// Envía la foto al endpoint PATCH /facturacion/{id}/evidencia
  Future<void> _enviarFoto({
    required int     localId,
    required int     idFactura,
    required File    foto,
    required double? latitud,
    required double? longitud,
  }) async {
    try {
      // Comprimir a base64
      final bytes     = await foto.readAsBytes();
      final fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final body = <String, dynamic>{'fotoBase64': fotoBase64};
      if (latitud  != null) body['latitud']  = latitud;
      if (longitud != null) body['longitud'] = longitud;

      await DioClient.instance
          .patch('facturacion/$idFactura/evidencia', data: body)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      // Si falla la foto no bloqueamos — el pedido ya quedó sincronizado
    }
  }

  void reset() {
    _status     = PedidoStatus.idle;
    _error      = '';
    _successMsg = '';
    notifyListeners();
  }
}