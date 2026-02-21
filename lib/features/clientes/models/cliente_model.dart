class ClienteModel {
  final int          idUsuario;
  final String       nombre;
  final String       cedula;
  final String       email;
  final String       estado;
  final List<String> roles;

  const ClienteModel({
    required this.idUsuario,
    required this.nombre,
    required this.cedula,
    required this.email,
    required this.estado,
    this.roles = const [],
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    // roles puede venir como List<String> o List<Map> con objeto completo
    List<String> parsedRoles = [];
    if (json['roles'] != null) {
      final raw = json['roles'] as List<dynamic>;
      parsedRoles = raw.map((r) {
        if (r is String) return r;
        if (r is Map) return r['nombre']?.toString() ?? '';
        return '';
      }).where((s) => s.isNotEmpty).toList();
    }

    return ClienteModel(
      idUsuario: json['idUsuario'] as int,
      nombre:    json['nombre']    as String? ?? '',
      cedula:    json['cedula']    as String? ?? '',
      email:     json['email']     as String? ?? '',
      estado:    json['estado']    as String? ?? '',
      roles:     parsedRoles,
    );
  }
}