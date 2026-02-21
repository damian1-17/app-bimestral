import 'dart:convert';

class UserModel {
  final int?         idUsuario;
  final String?      nombre;
  final String?      cedula;
  final String?      email;
  final String?      estado;
  final List<String> roles;

  const UserModel({
    this.idUsuario,
    this.nombre,
    this.cedula,
    this.email,
    this.estado,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    idUsuario: json['idUsuario'] as int?,
    nombre:    json['nombre']    as String?,
    cedula:    json['cedula']    as String?,
    email:     json['email']     as String?,
    estado:    json['estado']    as String?,
    roles:     (json['roles'] as List<dynamic>?)
                   ?.map((e) => e.toString())
                   .toList() ??
               [],
  );

  Map<String, dynamic> toJson() => {
    'idUsuario': idUsuario,
    'nombre':    nombre,
    'cedula':    cedula,
    'email':     email,
    'estado':    estado,
    'roles':     roles,
  };

  // Serialización para SharedPreferences
  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  bool get isActive => estado == 'activo';
}