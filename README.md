# tarea_bimestre

Aplicación Flutter (proyecto académico) para la gestión de ventas: productos, carrito y pedidos.

## Descripción

`tarea_bimestre` es una app modular escrita en Flutter que cubre un flujo mínimo de venta: autenticación de usuarios, catálogo de productos, carrito de compras, creación y visualización de pedidos, y selección de clientes (incluyendo lectura por QR). La solución combina persistencia local (SQLite), estado gestionado con providers y comunicación HTTP mediante `Dio`.

## Estructura detallada (carpeta `lib`)

- `main.dart`: punto de entrada de la aplicación.
- `core/`
	- `database/database_helper.dart`: utilidades para acceso a la base de datos local (aplicación de esquemas, CRUD básicos).
	- `network/dio_client.dart`: configuración del cliente HTTP (`Dio`), interceptores y base URL.
	- `services/session_service.dart`: manejo de sesión y credenciales en memoria/local.
	- `services/sync_service.dart`: mecanismos de sincronización entre la base local y el backend (puntos de integración).
	- `theme/app_theme.dart`: definición de temas, colores y tipografías usadas en la app.

- `features/`
	- `auth/`
		- `models/user_model.dart`: modelo de usuario.
		- `providers/auth_provider.dart`: lógica de autenticación, estado y expiración de sesión.
		- `screens/login_screen.dart`: UI completa de login.
		- `widgets/login_form.dart`: formulario reutilizable de ingreso.

	- `productos/`
		- `models/producto_model.dart`: modelo de producto.
		- `providers/productos_provider.dart`: carga y filtrado de productos.
		- `screens/productos_screen.dart`: listado y búsqueda.
		- `widgets/producto_card.dart`: tarjeta de producto reutilizable.

	- `carrito/`
		- `models/carrito_item_model.dart`: item del carrito.
		- `providers/carrito_provider.dart`: lógica de añadir/quitar ítems y cálculo de totales.
		- `screens/carrito_screen.dart`: vista del carrito.
		- `widgets/carrito_item_card.dart`: tarjeta de ítem con cantidad y acciones.

	- `pedido/` y `pedidos/`
		- `models/pedido_local_model.dart`: representacion local de una orden.
		- `providers/pedido_provider.dart`, `pedido_list_provider.dart`, `pedidos_list_provider.dart`: creación, edición y listado de pedidos.
		- `screens/crear_pedido_screen.dart`, `mis_pedidos_screen.dart`, `detalle_pedido_screen.dart`: flujos de creación y visualización de pedidos.
		- `widgets/confirmacion_dialog.dart`, `widgets/resumen_carrito_widget.dart`, `widgets/pedido_card.dart`: componentes de UI relacionados.

	- `clientes/`
		- `models/cliente_model.dart`: datos del cliente.
		- `providers/clientes_provider.dart`: búsqueda y selección de clientes.
		- `screens/qr_scanner_screen.dart`: lector de QR para seleccionar clientes.
		- `widgets/selector_cliente_widget.dart`: selector reutilizable.

	- `home/`
		- `screens/home_screen.dart`: pantalla principal y navegación.

## Tecnologías y dependencias clave

- Flutter (SDK) — UI y lógica principal.
- Provider — gestión de estado mediante providers locales por feature.
- Dio — cliente HTTP (`lib/core/network/dio_client.dart`).
- SQLite / sqflite (a través de `database_helper`) — persistencia local.

Comprueba `pubspec.yaml` para la lista completa y versiones exactas de paquetes.

## Funcionalidades implementadas (detallado)

- Autenticación: flujo de login con `auth_provider` y `session_service`.
- Catálogo de productos: modelos, provider y pantalla con tarjetas (`producto_card`).
- Carrito de compras: añadir/eliminar ítems, ajuste de cantidades y cálculo de totales (`carrito_provider`).
- Creación de pedidos: captura del estado del carrito y persistencia en `pedido_local_model`.
- Listado y detalle de pedidos: vistas para revisar pedidos creados localmente.
- Selección de clientes: búsqueda y escaneo por QR para asociar cliente al pedido.
- Persistencia local: capa de acceso implementada en `database_helper`.
- Comunicación HTTP: cliente `Dio` listo para integrar endpoints remotos.

## Cómo ejecutar (rápido)

1. Instala Flutter SDK y configura el entorno según la documentación oficial.
2. Desde la raíz del proyecto ejecuta:

```bash
flutter pub get
flutter run
```

3. Para ejecutar en un emulador o dispositivo específico, usa `flutter run -d <deviceId>`.

## Notas para desarrolladores (técnicas)

- Estado: cada feature expone un `Provider` responsable únicamente de su lógica y estado; esto facilita pruebas unitarias y separación de responsabilidades.
- Red: centraliza la configuración de `Dio` en `lib/core/network/dio_client.dart`. Agrega interceptores para manejo de auth y logging allí.
- Base de datos: `lib/core/database/database_helper.dart` expone métodos de acceso; revisa migraciones y esquemas antes de cambios.
- UI: los widgets están diseñados para ser reutilizables (`producto_card`, `carrito_item_card`, `resumen_carrito_widget`).
- Testing: los providers y servicios pueden testearse de forma aislada inyectando dependencias (por ejemplo, un `Dio` fake o una DB en memoria).

---
Actualizado para reflejar la estructura y funcionalidades presentes en la carpeta `lib/`.
