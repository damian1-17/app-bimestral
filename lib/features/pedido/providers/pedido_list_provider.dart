import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';

class PedidosListProvider extends ChangeNotifier {
  List<PedidoLocalModel> _pedidos   = [];
  bool   _isLoading                 = false;
  bool   _isSyncing                 = false;
  String _syncMsg                   = '';

  List<PedidoLocalModel> get pedidos   => _pedidos;
  bool   get isLoading                 => _isLoading;
  bool   get isSyncing                 => _isSyncing;
  String get syncMsg                   => _syncMsg;

  int get totalPendientes =>
      _pedidos.where((p) => p.estado == EstadoPedido.pendiente).length;

  // ── Cargar desde SQLite ───────────────────────────────────────────────────
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

    // Solo pendientes que tengan idCliente
    final pendientes = _pedidos.where((p) =>
        p.estado == EstadoPedido.pendiente).toList();

    final sinCliente   = pendientes.where((p) => p.idCliente == null).toList();
    final conCliente   = pendientes.where((p) => p.idCliente != null).toList();

    if (pendientes.isEmpty) {
      _syncMsg = 'No hay pedidos pendientes de sincronización.';
      notifyListeners();
      return;
    }

    // Marcar los que no tienen cliente como error inmediatamente
    for (final p in sinCliente) {
      await DatabaseHelper.instance.actualizarEstado(
        p.id!, EstadoPedido.error.valor,
        errorMsg: 'Sin cliente asignado. No se puede sincronizar.',
      );
    }

    _isSyncing = true;
    _syncMsg   = '';
    notifyListeners();

    int exitosos = 0;
    int fallidos = sinCliente.length; // los sin cliente ya son fallidos

    for (final pedido in conCliente) {
      final idFactura = await _enviarPedido(pedido);
      if (idFactura != null) {
        exitosos++;
        // Enviar foto si existe
        if (pedido.fotoPath != null) {
          await _enviarFoto(idFactura: idFactura, fotoPath: pedido.fotoPath!,
              latitud: pedido.latitud, longitud: pedido.longitud);
        }
      } else {
        fallidos++;
      }
    }

    await cargarPedidos();

    if (exitosos > 0 && fallidos == 0) {
      _syncMsg = '✅ $exitosos ${exitosos == 1 ? "pedido sincronizado" : "pedidos sincronizados"} correctamente.';
    } else if (exitosos > 0 && fallidos > 0) {
      _syncMsg = '⚠️ $exitosos sincronizados, $fallidos con problemas.';
    } else if (sinCliente.isNotEmpty && conCliente.isEmpty) {
      _syncMsg = '❌ Los pedidos pendientes no tienen cliente asignado.';
    } else {
      _syncMsg = '❌ No se pudo sincronizar. Verifica tu conexión.';
    }

    _isSyncing = false;
    notifyListeners();
  }

  // ── Enviar pedido a la API (sin foto) ────────────────────────────────────
  Future<int?> _enviarPedido(PedidoLocalModel pedido) async {
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
        await DatabaseHelper.instance.actualizarEstado(
            pedido.id!, EstadoPedido.sincronizado.valor);
        final id = response.data['id'] ??
                   response.data['idFactura'] ??
                   response.data['data']?['id'];
        return id as int?;
      } else {
        final msg = response.data?['message']?.toString() ??
            'Error ${response.statusCode}';
        await DatabaseHelper.instance.actualizarEstado(
            pedido.id!, EstadoPedido.error.valor, errorMsg: msg);
        return null;
      }
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionError
          ? 'Sin conexión a internet'
          : 'Error: ${e.message}';
      await DatabaseHelper.instance.actualizarEstado(
          pedido.id!, EstadoPedido.error.valor, errorMsg: msg);
      return null;
    } catch (e) {
      await DatabaseHelper.instance.actualizarEstado(
          pedido.id!, EstadoPedido.error.valor, errorMsg: e.toString());
      return null;
    }
  }

  // ── Enviar foto por separado al endpoint PATCH ────────────────────────────
  Future<void> _enviarFoto({
    required int     idFactura,
    required String  fotoPath,
    required double? latitud,
    required double? longitud,
  }) async {
    try {
      final file = File(fotoPath);
      if (!await file.exists()) return;

      final bytes      = await file.readAsBytes();
      final fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final body = <String, dynamic>{'fotoBase64': fotoBase64};
      if (latitud  != null) body['latitud']  = latitud;
      if (longitud != null) body['longitud'] = longitud;

      await DioClient.instance
          .patch('facturacion/$idFactura/evidencia', data: body)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      // Si falla la foto no bloqueamos el flujo principal
    }
  }

  void limpiarMensaje() {
    _syncMsg = '';
    notifyListeners();
  }
}