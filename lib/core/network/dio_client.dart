import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente HTTP con manejo manual de cookies.
/// Extrae Set-Cookie de las respuestas y las reenvía en cada request.
class DioClient {
  DioClient._();

  static const String baseUrl    = 'https://security-module.onrender.com/api/v1/';
  static const String _cookieKey = 'session_cookies';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers:        {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  )..interceptors.addAll([
      _CookieInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestBody:  true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);

  static Dio get instance => _dio;

  /// Limpia las cookies guardadas (llamar al hacer logout)
  static Future<void> clearCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }
}

/// Interceptor que persiste y reenvía cookies de sesión manualmente
class _CookieInterceptor extends Interceptor {
  static const String _cookieKey = 'session_cookies';

  // Antes de cada request: leer cookies guardadas y adjuntarlas
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final cookies = prefs.getString(_cookieKey);
      if (cookies != null && cookies.isNotEmpty) {
        options.headers['Cookie'] = cookies;
      }
    } catch (_) {}
    handler.next(options);
  }

  // Después de cada response: extraer y guardar Set-Cookie
  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      final rawCookies = response.headers['set-cookie'];
      if (rawCookies != null && rawCookies.isNotEmpty) {
        // Extraer solo "nombre=valor" (sin Path, HttpOnly, etc.)
        final nuevas = rawCookies
            .map((c) => c.split(';').first.trim())
            .toList();

        // Combinar con cookies existentes (sin duplicar por nombre)
        final prefs      = await SharedPreferences.getInstance();
        final existentes = prefs.getString(_cookieKey) ?? '';
        final mapa       = <String, String>{};

        // Cargar existentes
        if (existentes.isNotEmpty) {
          for (final c in existentes.split('; ')) {
            final parts = c.split('=');
            if (parts.length >= 2) {
              mapa[parts[0]] = parts.sublist(1).join('=');
            }
          }
        }

        // Sobreescribir con nuevas
        for (final c in nuevas) {
          final parts = c.split('=');
          if (parts.length >= 2) {
            mapa[parts[0]] = parts.sublist(1).join('=');
          }
        }

        final cookieStr = mapa.entries.map((e) => '${e.key}=${e.value}').join('; ');
        await prefs.setString(_cookieKey, cookieStr);
      }
    } catch (_) {}
    handler.next(response);
  }
}