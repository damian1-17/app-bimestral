import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/core/services/session_service.dart';
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

    // Cargar usuario local inmediatamente
    _user = await SessionService.getUser();

    // Verificar con el servidor (con timeout corto para no bloquear)
    try {
      final response = await DioClient.instance
          .get('auth/check')
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 &&
          response.data['authenticated'] == true) {
        _status = AuthStatus.authenticated;
      } else {
        await _clearLocalSession();
        return;
      }
    } catch (_) {
      // Sin red o timeout → confiar en sesión local (modo offline)
      _status = AuthStatus.authenticated;
    }

    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await DioClient.instance.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );

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

        await SessionService.saveSession(user);
        _user   = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
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

    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _setError('Tiempo de espera agotado. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.connectionError) {
        _setError('Sin conexión a internet.');
      } else {
        _setError('Error de red: ${e.message}');
      }
    } catch (e) {
      _setError('Error inesperado: $e');
    } finally {
      _setLoading(false);
    }

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
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}