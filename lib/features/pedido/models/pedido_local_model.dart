import 'dart:convert';

/// Estados posibles de un pedido local
enum EstadoPedido { pendiente, sincronizado, error }

extension EstadoPedidoExt on EstadoPedido {
  String get valor {
    switch (this) {
      case EstadoPedido.pendiente:    return 'pendiente';
      case EstadoPedido.sincronizado: return 'sincronizado';
      case EstadoPedido.error:        return 'error';
    }
  }

  static EstadoPedido fromString(String s) {
    switch (s) {
      case 'sincronizado': return EstadoPedido.sincronizado;
      case 'error':        return EstadoPedido.error;
      default:             return EstadoPedido.pendiente;
    }
  }
}

class PedidoLocalModel {
  final int?          id;
  final String        nombreCliente;
  final String        cedula;
  final String        direccion;
  final String        telefono;
  final String?       email;
  final String        formaPago;
  final double        descuento;
  final String?       observaciones;
  final double?       latitud;
  final double?       longitud;
  final String?       fotoPath;
  final List<Map<String, dynamic>> items;
  final EstadoPedido  estado;
  final String?       errorMsg;
  final int?          idCliente;
  final DateTime      createdAt;
  final DateTime?     syncedAt;

  const PedidoLocalModel({
    this.id,
    required this.nombreCliente,
    required this.cedula,
    required this.direccion,
    required this.telefono,
    this.email,
    required this.formaPago,
    this.descuento = 0,
    this.observaciones,
    this.latitud,
    this.longitud,
    this.fotoPath,
    required this.items,
    this.estado = EstadoPedido.pendiente,
    this.errorMsg,
    this.idCliente,
    required this.createdAt,
    this.syncedAt,
  });

  // ── Convertir a Map para SQLite ───────────────────────────────────────────
  Map<String, dynamic> toDb() => {
    if (id != null) 'id': id,
    'nombreCliente': nombreCliente,
    'cedula':        cedula,
    'direccion':     direccion,
    'telefono':      telefono,
    'email':         email,
    'formaPago':     formaPago,
    'descuento':     descuento,
    'observaciones': observaciones,
    'latitud':       latitud,
    'longitud':      longitud,
    'fotoPath':      fotoPath,
    'itemsJson':     jsonEncode(items),
    'estado':        estado.valor,
    'errorMsg':      errorMsg,
    'idCliente':     idCliente,
    'createdAt':     createdAt.toIso8601String(),
    'syncedAt':      syncedAt?.toIso8601String(),
  };

  // ── Construir desde SQLite ────────────────────────────────────────────────
  factory PedidoLocalModel.fromDb(Map<String, dynamic> map) => PedidoLocalModel(
    id:            map['id'] as int?,
    nombreCliente: map['nombreCliente'] as String,
    cedula:        map['cedula']        as String,
    direccion:     map['direccion']     as String,
    telefono:      map['telefono']      as String,
    email:         map['email']         as String?,
    formaPago:     map['formaPago']     as String,
    descuento:     (map['descuento'] as num?)?.toDouble() ?? 0,
    observaciones: map['observaciones'] as String?,
    latitud:       (map['latitud']  as num?)?.toDouble(),
    longitud:      (map['longitud'] as num?)?.toDouble(),
    fotoPath:      map['fotoPath']  as String?,
    items:         (jsonDecode(map['itemsJson'] as String) as List)
                       .cast<Map<String, dynamic>>(),
    estado:        EstadoPedidoExt.fromString(map['estado'] as String),
    errorMsg:      map['errorMsg']  as String?,
    idCliente:     map['idCliente'] as int?,
    createdAt:     DateTime.parse(map['createdAt'] as String),
    syncedAt:      map['syncedAt'] != null
                       ? DateTime.parse(map['syncedAt'] as String)
                       : null,
  );
}