import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton que gestiona la base de datos SQLite local.
/// Tabla principal: pedidos — guarda todo el pedido serializado en JSON
/// para poder recrearlo y sincronizarlo con la API sin perder datos.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Inicializar BD ────────────────────────────────────────────────────────
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'pedidos.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pedidos (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        nombreCliente   TEXT    NOT NULL,
        cedula          TEXT    NOT NULL,
        direccion       TEXT    NOT NULL,
        telefono        TEXT    NOT NULL,
        email           TEXT,
        formaPago       TEXT    NOT NULL,
        descuento       REAL    NOT NULL DEFAULT 0,
        observaciones   TEXT,
        latitud         REAL,
        longitud        REAL,
        fotoPath        TEXT,
        itemsJson       TEXT    NOT NULL,
        estado          TEXT    NOT NULL DEFAULT 'pendiente',
        errorMsg        TEXT,
        idCliente       INTEGER,
        createdAt       TEXT    NOT NULL,
        syncedAt        TEXT
      )
    ''');
  }

  // ── INSERT ────────────────────────────────────────────────────────────────
  Future<int> insertarPedido(Map<String, dynamic> pedido) async {
    final db = await database;
    return db.insert('pedidos', pedido,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── SELECT todos ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> obtenerPedidos() async {
    final db = await database;
    return db.query('pedidos', orderBy: 'createdAt DESC');
  }

  // ── SELECT pendientes ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final db = await database;
    return db.query('pedidos',
        where: 'estado = ?', whereArgs: ['pendiente'],
        orderBy: 'createdAt ASC');
  }

  // ── UPDATE estado ─────────────────────────────────────────────────────────
  Future<void> actualizarEstado(int id, String estado, {String? errorMsg}) async {
    final db = await database;
    final data = <String, dynamic>{'estado': estado};
    if (estado == 'sincronizado') data['syncedAt'] = DateTime.now().toIso8601String();
    if (errorMsg != null)         data['errorMsg'] = errorMsg;
    await db.update('pedidos', data, where: 'id = ?', whereArgs: [id]);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> eliminarPedido(int id) async {
    final db = await database;
    await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  }
}