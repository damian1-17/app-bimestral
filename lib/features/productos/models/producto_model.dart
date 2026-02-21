class ProductoModel {
  final int    idProducto;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool   activo;

  const ProductoModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.activo,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) => ProductoModel(
    idProducto:  json['idProducto'] as int,
    nombre:      json['nombre']     as String,
    descripcion: json['descripcion'] as String? ?? '',
    precio:      double.tryParse(json['precio'].toString()) ?? 0.0,
    activo:      json['activo']     as bool? ?? false,
  );
}