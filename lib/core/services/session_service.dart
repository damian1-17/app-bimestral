import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea_bimestre/features/auth/models/user_model.dart';

/// Persiste los datos del usuario en SharedPreferences.
/// Los tokens viven exclusivamente en las cookies de DioClient.
class SessionService {
  static const _keyLoggedIn = 'is_logged_in';
  static const _keyUser     = 'user_data';

  // ── Guardar ───────────────────────────────────────────────────────────────

  static Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUser, user.toJsonString());
  }

  // ── Leer ──────────────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyUser);
    if (str == null) return null;
    return UserModel.fromJsonString(str);
  }

  // ── Limpiar ───────────────────────────────────────────────────────────────

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}