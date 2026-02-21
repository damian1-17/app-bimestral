import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

enum UbicacionError {
  servicioDesactivado,
  permisoDenegado,
  permisoPermanente,
  timeout,
  desconocido,
}

class UbicacionResult {
  final double? latitud;
  final double? longitud;
  final UbicacionError? error;
  bool get ok => latitud != null;

  const UbicacionResult({this.latitud, this.longitud, this.error});
}

Future<UbicacionResult> obtenerUbicacion() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const UbicacionResult(error: UbicacionError.servicioDesactivado);
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        return const UbicacionResult(error: UbicacionError.permisoDenegado);
      }
    }
    if (perm == LocationPermission.deniedForever) {
      return const UbicacionResult(error: UbicacionError.permisoPermanente);
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(const Duration(seconds: 15));

    return UbicacionResult(latitud: pos.latitude, longitud: pos.longitude);

  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('time')) {
      return const UbicacionResult(error: UbicacionError.timeout);
    }
    return const UbicacionResult(error: UbicacionError.desconocido);
  }
}

String mensajeUbicacionError(UbicacionError error) {
  switch (error) {
    case UbicacionError.servicioDesactivado:
      return 'GPS desactivado. Actívalo en ajustes.';
    case UbicacionError.permisoDenegado:
      return 'Permiso de ubicación denegado.';
    case UbicacionError.permisoPermanente:
      return 'Permiso bloqueado. Ve a Ajustes > Aplicaciones.';
    case UbicacionError.timeout:
      return 'Tiempo agotado. Verifica señal GPS.';
    case UbicacionError.desconocido:
      return 'No se pudo obtener la ubicación.';
  }
}