

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';

class PedidosListProvider extends ChangeNotifier {
  List<PedidoLocalModel> _pedidos       = [];
  bool                   _isLoading     = false;
  bool                   _isSyncing     = false;
  String                 _syncMsg       = '';

  List<PedidoLocalModel> get pedidos    => _pedidos;
  bool                   get isLoading  => _isLoading;
  bool                   get isSyncing  => _isSyncing;
  String                 get syncMsg    => _syncMsg;

  int get totalPendientes =>
      _pedidos.where((p) => p.estado == EstadoPedido.pendiente).length;

  // ── Cargar todos los pedidos desde SQLite ─────────────────────────────────
  Future<void> cargarPedidos() async {
    _isLoading = true;
    notifyListeners();

    final rows = await DatabaseHelper.instance.obtenerPedidos();
    _pedidos   = rows.map(PedidoLocalModel.fromDb).toList();

    _isLoading = false;
    notifyListeners();
  }

  // ── Sincronización manual ─────────────────────────────────────────────────
  Future<void> sincronizar() async {
    if (_isSyncing) return;

    final pendientes = _pedidos
        .where((p) => p.estado == EstadoPedido.pendiente)
        .toList();

    if (pendientes.isEmpty) {
      _syncMsg = 'No hay pedidos pendientes de sincronización.';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncMsg   = '';
    notifyListeners();

    int exitosos = 0;
    int fallidos = 0;

    for (final pedido in pendientes) {
      final ok = await _enviarPedido(pedido);
      if (ok) { exitosos++; } else { fallidos++; }
    }

    // Recargar lista desde SQLite con estados actualizados
    await cargarPedidos();

    _isSyncing = true; // mantener true hasta asignar mensaje
    if (exitosos > 0 && fallidos == 0) {
      _syncMsg = '✅ $exitosos ${exitosos == 1 ? "pedido sincronizado" : "pedidos sincronizados"} correctamente.';
    } else if (exitosos > 0 && fallidos > 0) {
      _syncMsg = '⚠️ $exitosos sincronizados, $fallidos con error.';
    } else {
      _syncMsg = '❌ No se pudo sincronizar. Verifica tu conexión.';
    }

    _isSyncing = false;
    notifyListeners();
  }

  // ── Enviar un pedido a la API ─────────────────────────────────────────────
  Future<bool> _enviarPedido(PedidoLocalModel pedido) async {
    try {
      // Convertir foto a base64 si existe y el archivo sigue en disco
      String? fotoBase64;
      if (pedido.fotoPath != null) {
        final file = File(pedido.fotoPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

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

      if (pedido.idCliente   != null) body['idCliente']     = pedido.idCliente;
      if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty)
                                       body['observaciones'] = pedido.observaciones;
      if (pedido.latitud     != null)  body['latitud']       = pedido.latitud;
      if (pedido.longitud    != null)  body['longitud']      = pedido.longitud;
      if (fotoBase64         != null)  body['fotoBase64']    = fotoBase64;

      final response = await DioClient.instance
          .post('facturacion/directa', data: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await DatabaseHelper.instance.actualizarEstado(
            pedido.id!, EstadoPedido.sincronizado.valor);
        return true;
      } else {
        final msg = response.data?['message']?.toString() ??
            'Error ${response.statusCode}';
        await DatabaseHelper.instance.actualizarEstado(
            pedido.id!, EstadoPedido.error.valor, errorMsg: msg);
        return false;
      }
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionError
          ? 'Sin conexión a internet'
          : 'Error de red: ${e.message}';
      await DatabaseHelper.instance.actualizarEstado(
          pedido.id!, EstadoPedido.error.valor, errorMsg: msg);
      return false;
    } catch (e) {
      await DatabaseHelper.instance.actualizarEstado(
          pedido.id!, EstadoPedido.error.valor, errorMsg: e.toString());
      return false;
    }
  }

  void limpiarMensaje() {
    _syncMsg = '';
    notifyListeners();
  }
}