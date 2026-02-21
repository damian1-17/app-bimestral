import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';

class ClientesProvider extends ChangeNotifier {
  List<ClienteModel> _clientes     = [];
  bool   _isLoading                = false;
  String _error                    = '';

  List<ClienteModel> get clientes  => _clientes;
  bool   get isLoading             => _isLoading;
  String get error                 => _error;

  Future<void> buscarClientes({String search = ''}) async {
    _isLoading = true;
    _error     = '';
    _clientes  = [];
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page':      1,
        'limit':     10,
        'estado':    'activo',
        'sortBy':    'nombre',
        'sortOrder': 'ASC',
      };
      if (search.isNotEmpty) params['search'] = search;

      final response = await DioClient.instance.get(
        'usuarios',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _clientes = data
            .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error ${response.statusCode} al buscar clientes.';
      }
    } on DioException catch (e) {
      _error = e.type == DioExceptionType.connectionError
          ? 'Sin conexión.'
          : 'Error de red: ${e.message}';
    } catch (e) {
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}