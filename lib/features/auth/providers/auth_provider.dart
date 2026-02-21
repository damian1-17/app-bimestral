import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/database/database_helper.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/core/services/session_service.dart';
import 'package:tarea_bimestre/core/services/sync_service.dart';
import 'package:tarea_bimestre/features/auth/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status       = AuthStatus.unknown;
  UserModel? _user;
  String?    _errorMessage;
  bool       _isLoading    = false;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoading    => _isLoading;

  // ── Verificar sesión al arrancar ──────────────────────────────────────────
  Future<void> checkSession() async {
    final loggedIn = await SessionService.isLoggedIn();

    if (!loggedIn) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Cargar usuario desde SharedPreferences
    _user   = await SessionService.getUser();
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password, {SyncService? syncService}) async {
    _setLoading(true);
    _errorMessage = null;

    // 1. Intentar login online
    try {
      final response = await DioClient.instance
          .post('auth/login', data: {'email': email, 'password': password})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        if (userData == null) {
          _setError('Respuesta inesperada del servidor.');
          return false;
        }

        final user = UserModel.fromJson(userData as Map<String, dynamic>);
        if (!user.isActive) {
          _setError('Tu cuenta está inactiva. Contacta al administrador.');
          return false;
        }

        // Guardar sesión
        await SessionService.saveSession(user);
        await DatabaseHelper.instance.guardarUsuario({
          'idUsuario': user.idUsuario,
          'nombre':    user.nombre,
          'cedula':    user.cedula,
          'email':     user.email,
          'estado':    user.estado,
          'roles':     user.roles.join(','),
        });

        _user   = user;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Sincronizar productos en segundo plano (login online = primera sync)
        if (syncService != null) {
          syncService.sincronizarProductos();
        }

        return true;

      } else if (response.statusCode == 401) {
        _setError('Correo o contraseña incorrectos.');
      } else if (response.statusCode == 400) {
        _setError('Datos inválidos. Verifica tu correo.');
      } else if (response.statusCode == 403) {
        _setError('Acceso denegado.');
      } else {
        _setError('Error ${response.statusCode}. Intenta nuevamente.');
      }

      return false;

    } on DioException catch (e) {
      // Sin red — intentar login offline
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return await _loginOffline(email);
      }
      _setError('Error de red: ${e.message}');
      return false;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return await _loginOffline(email);
      }
      _setError('Error inesperado: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login offline: verificar sesión previa guardada ───────────────────────
  Future<bool> _loginOffline(String email) async {
    final userData = await DatabaseHelper.instance.obtenerUsuario(email);

    if (userData != null) {
      final roles = (userData['roles'] as String).split(',');
      _user = UserModel(
        idUsuario: userData['idUsuario'] as int,
        nombre:    userData['nombre']    as String,
        cedula:    userData['cedula']    as String,
        email:     userData['email']     as String,
        estado:    userData['estado']    as String,
        roles:     roles,
      );

      await SessionService.saveSession(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();

      _setError('Sin internet — sesión local cargada.');
      return true;
    }

    _setError('Sin internet y no hay sesión guardada para este usuario.');
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await DioClient.instance
          .post('auth/logout')
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    await _clearLocalSession();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _clearLocalSession() async {
    await SessionService.clearSession();
    await DioClient.clearCookies();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading    = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}