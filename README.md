# tarea_bimestre

Aplicación Flutter para la gestión de pedidos y carrito — proyecto de ejemplo/bimestre.

## Resumen

Esta aplicación implementa un flujo básico de comercio/venta: autenticación de usuario, gestión de productos, carrito de compras, creación y listado de pedidos, selección/escaneo de clientes y sincronización con servicios remotos.

## Estructura principal (carpeta `lib`)

- `core/`
	- `database/`: `database_helper.dart` — helpers para almacenamiento local (SQLite).
	- `network/`: `dio_client.dart` — cliente HTTP con Dio.
	- `services/`: `session_service.dart`, `sync_service.dart` — manejo de sesión y sincronización.
	- `theme/`: `app_theme.dart` — configuración de temas de la app.

- `features/`
	- `auth/`: pantalla de login, `auth_provider.dart`, `user_model.dart`, `login_form.dart`.
	- `productos/`: listado de productos, `productos_provider.dart`, `producto_model.dart`, `producto_card.dart`.
	- `carrito/`: `carrito_provider.dart`, modelos y widgets para el carrito y su resumen.
	- `pedido/` y `pedidos/`: creación de pedidos, listado y detalle, providers y modelos locales.
	- `clientes/`: selección/escaneo de clientes (QR) y proveedor de datos.
	- `home/`: pantalla principal de la aplicación.

## Funcionalidades implementadas

- Autenticación de usuario (pantalla de login).
- Gestión de productos y visualización en tarjetas.
- Carrito de compras con resumen y manejo de ítems.
- Creación y listado de pedidos (persistencia local para órdenes locales).
- Selección/escaneo de clientes mediante pantalla/QR.
- Servicios para sesión, sincronización y cliente HTTP.
- Acceso a base de datos local mediante `database_helper`.

## Ejecutar la aplicación

1. Asegúrate de tener instalado Flutter SDK y configurado el entorno.
2. Desde la raíz del proyecto ejecutar:

```bash
flutter pub get
flutter run
```

Para ejecutar en un emulador o dispositivo conectado, usa `flutter run` con el target deseado.

## Notas para desarrolladores

- La arquitectura usa providers para el estado (`*_provider.dart`).
- Revisa `lib/core/network/dio_client.dart` para configurar endpoints y timeouts.
- La persistencia local y sincronización se encuentran en `lib/core/database` y `lib/core/services`.

## Próximos pasos sugeridos

- Integrar APIs remotas y pruebas de integración.
- Añadir manejo de errores y estados de carga más robustos.
- Tests unitarios para providers y servicios.

---
Actualizado según la estructura y archivos presentes en `lib/`.
