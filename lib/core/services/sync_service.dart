import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';

enum SyncStatus { idle, syncing, success, error }

/// Servicio de sincronización manual.
/// Descarga todos los productos activos de la API y los guarda en SQLite.
class SyncService extends ChangeNotifier {
  SyncStatus _status  = SyncStatus.idle;
  String     _message = '';
  DateTime?  _lastSync;

  SyncStatus get status   => _status;
  String     get message  => _message;
  DateTime?  get lastSync => _lastSync;
  bool get isSyncing      => _status == SyncStatus.syncing;

  /// Descarga todos los productos de la API (todas las páginas) y los guarda en SQLite.
  Future<bool> sincronizarProductos() async {
    if (_status == SyncStatus.syncing) return false;

    _status  = SyncStatus.syncing;
    _message = 'Sincronizando productos...';
    notifyListeners();

    try {
      final productos = await _fetchAllProductos();

      if (productos.isEmpty) {
        _setResult(SyncStatus.error, 'No se encontraron productos en el servidor.');
        return false;
      }

      await DatabaseHelper.instance.guardarProductos(productos);

      _lastSync = DateTime.now();
      _setResult(
        SyncStatus.success,
        '${productos.length} productos sincronizados correctamente.',
      );
      return true;

    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionError
          ? 'Sin conexión a internet.'
          : 'Error de red: ${e.message}';
      _setResult(SyncStatus.error, msg);
      return false;
    } catch (e) {
      _setResult(SyncStatus.error, 'Error inesperado: $e');
      return false;
    }
  }

  // Descarga todas las páginas de productos activos
  Future<List<Map<String, dynamic>>> _fetchAllProductos() async {
    final allProductos = <Map<String, dynamic>>[];
    int page       = 1;
    int totalPages = 1;

    do {
      final response = await DioClient.instance.get(
        'productos',
        queryParameters: {
          'activo':    true,
          'page':      page,
          'limit':     50,
          'sortBy':    'nombre',
          'sortOrder': 'ASC',
        },
      );

      if (response.statusCode != 200) break;

      final data = response.data;
      final lista = (data['data'] as List).map((e) {
        final p = e as Map<String, dynamic>;
        return {
          'idProducto':  p['idProducto'] as int,
          'nombre':      p['nombre']     as String,
          'descripcion': p['descripcion'] as String? ?? '',
          'precio':      double.tryParse(p['precio'].toString()) ?? 0.0,
          'activo':      (p['activo'] as bool? ?? false) ? 1 : 0,
          'updatedAt':   p['updatedAt']  as String? ?? '',
        };
      }).toList();

      allProductos.addAll(lista);
      totalPages = data['totalPages'] as int? ?? 1;
      page++;

    } while (page <= totalPages);

    return allProductos;
  }

  void _setResult(SyncStatus status, String message) {
    _status  = status;
    _message = message;
    notifyListeners();
  }

  void resetStatus() {
    _status  = SyncStatus.idle;
    _message = '';
    notifyListeners();
  }
}