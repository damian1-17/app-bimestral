import 'package:tarea_bimestre/features/productos/models/producto_model.dart';

class CarritoItem {
  final ProductoModel producto;
  int cantidad;

  CarritoItem({required this.producto, this.cantidad = 1});

  double get subtotal => producto.precio * cantidad;
}