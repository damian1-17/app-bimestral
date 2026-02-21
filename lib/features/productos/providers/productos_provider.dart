import 'package:flutter/foundation.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/features/productos/models/producto_model.dart';

/// Lee SIEMPRE desde SQLite local — nunca directo de la API.
/// La API solo se toca al sincronizar (SyncService).
class ProductosProvider extends ChangeNotifier {
  List<ProductoModel> _productos    = [];
  bool   _isLoading                 = false;
  bool   _isLoadingMore             = false;
  String _error                     = '';
  String _search                    = '';
  int    _page                      = 1;
  bool   _hayMas                    = false;
  static const int _limit           = 10;

  List<ProductoModel> get productos => _productos;
  bool   get isLoading              => _isLoading;
  bool   get isLoadingMore          => _isLoadingMore;
  String get error                  => _error;
  bool   get hayMasPaginas          => _hayMas;

  // ── Carga inicial / nueva búsqueda ────────────────────────────────────────
  Future<void> cargarProductos({String search = ''}) async {
    _search    = search;
    _page      = 1;
    _productos = [];
    _isLoading = true;
    _error     = '';
    notifyListeners();

    await _fetchPage();

    _isLoading = false;
    notifyListeners();
  }

  // ── Cargar más ────────────────────────────────────────────────────────────
  Future<void> cargarMas() async {
    if (_isLoadingMore || !_hayMas) return;
    _page++;
    _isLoadingMore = true;
    notifyListeners();

    await _fetchPage();

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Leer desde SQLite ─────────────────────────────────────────────────────
  Future<void> _fetchPage() async {
    try {
      final rows = await DatabaseHelper.instance.obtenerProductos(
        search: _search,
        page:   _page,
        limit:  _limit,
      );

      final nuevos = rows.map((r) => ProductoModel(
        idProducto:  r['idProducto']  as int,
        nombre:      r['nombre']      as String,
        descripcion: r['descripcion'] as String,
        precio:      r['precio']      as double,
        activo:      (r['activo']     as int) == 1,
      )).toList();

      _productos.addAll(nuevos);

      // Verificar si hay más páginas
      final total = await DatabaseHelper.instance.contarProductos(search: _search);
      _hayMas = (_page * _limit) < total;
      _error  = '';

    } catch (e) {
      _error = 'Error al leer productos locales: $e';
    }
  }

  // ── Recargar después de sincronizar ──────────────────────────────────────
  Future<void> recargar() async {
    await cargarProductos(search: _search);
  }
}