import 'package:flutter/foundation.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';
import 'dart:io';

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
        estado:        EstadoPedido.pendiente, // ← siempre pendiente
        idCliente:     cliente?.idUsuario,
        createdAt:     DateTime.now(),
      );

      // Guardar en SQLite — queda pendiente hasta sync manual
      await DatabaseHelper.instance.insertarPedido(pedidoLocal.toDb());

      _successMsg = 'Pedido guardado. Ve a "Mis Pedidos" para sincronizarlo.';

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

  void reset() {
    _status     = PedidoStatus.idle;
    _error      = '';
    _successMsg = '';
    notifyListeners();
  }
}