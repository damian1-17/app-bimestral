import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/productos/models/producto_model.dart';

class ProductosProvider extends ChangeNotifier {
  List<ProductoModel> _productos  = [];
  bool   _isLoading   = false;
  bool   _isLoadingMore = false;
  String _error       = '';
  String _search      = '';
  int    _page        = 1;
  int    _totalPages  = 1;
  static const int _limit = 10;

  List<ProductoModel> get productos    => _productos;
  bool   get isLoading                 => _isLoading;
  bool   get isLoadingMore             => _isLoadingMore;
  String get error                     => _error;
  bool   get hayMasPaginas             => _page < _totalPages;

  // ── Carga inicial / nueva búsqueda ────────────────────────────────────────
  Future<void> cargarProductos({String search = ''}) async {
    _search   = search;
    _page     = 1;
    _productos = [];
    _isLoading = true;
    _error     = '';
    notifyListeners();

    await _fetchPage();

    _isLoading = false;
    notifyListeners();
  }

  // ── Cargar más (paginación) ───────────────────────────────────────────────
  Future<void> cargarMas() async {
    if (_isLoadingMore || !hayMasPaginas) return;
    _page++;
    _isLoadingMore = true;
    notifyListeners();

    await _fetchPage();

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Llamada real a la API ─────────────────────────────────────────────────
  Future<void> _fetchPage() async {
    try {
      final queryParams = <String, dynamic>{
        'activo': true,
        'page':   _page,
        'limit':  _limit,
        'sortBy': 'nombre',
        'sortOrder': 'ASC',
      };
      if (_search.isNotEmpty) queryParams['search'] = _search;

      final response = await DioClient.instance.get(
        'productos',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final lista = (data['data'] as List)
            .map((e) => ProductoModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _productos.addAll(lista);
        _totalPages = data['totalPages'] as int? ?? 1;
        _error = '';
      } else {
        _error = 'Error ${response.statusCode} al cargar productos.';
      }
    } on DioException catch (e) {
      _error = e.type == DioExceptionType.connectionError
          ? 'Sin conexión a internet.'
          : 'Error de red: ${e.message}';
    } catch (e) {
      _error = 'Error inesperado: $e';
    }
  }
}