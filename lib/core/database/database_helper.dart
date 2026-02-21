import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'tarea_bimestre.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── usuarios ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE usuarios (
        idUsuario   INTEGER PRIMARY KEY,
        nombre      TEXT    NOT NULL,
        cedula      TEXT    NOT NULL,
        email       TEXT    NOT NULL,
        estado      TEXT    NOT NULL,
        roles       TEXT    NOT NULL
      )
    ''');

    // ── productos ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE productos (
        idProducto  INTEGER PRIMARY KEY,
        nombre      TEXT    NOT NULL,
        descripcion TEXT    NOT NULL,
        precio      REAL    NOT NULL,
        activo      INTEGER NOT NULL DEFAULT 1,
        updatedAt   TEXT    NOT NULL
      )
    ''');

    // ── clientes ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE clientes (
        idCliente   INTEGER PRIMARY KEY,
        nombre      TEXT    NOT NULL,
        cedula      TEXT    NOT NULL,
        direccion   TEXT    NOT NULL DEFAULT '',
        telefono    TEXT    NOT NULL DEFAULT '',
        email       TEXT,
        updatedAt   TEXT    NOT NULL
      )
    ''');

    // ── pedidos ───────────────────────────────────────────────────────────────
    // Columnas alineadas exactamente con PedidoLocalModel.toDb()
    await db.execute('''
      CREATE TABLE pedidos (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nombreCliente TEXT    NOT NULL,
        cedula        TEXT    NOT NULL,
        direccion     TEXT    NOT NULL,
        telefono      TEXT    NOT NULL,
        email         TEXT,
        formaPago     TEXT    NOT NULL,
        descuento     REAL    NOT NULL DEFAULT 0,
        observaciones TEXT,
        latitud       REAL,
        longitud      REAL,
        fotoPath      TEXT,
        itemsJson     TEXT    NOT NULL,
        estado        TEXT    NOT NULL DEFAULT 'pendiente',
        errorMsg      TEXT,
        idCliente     INTEGER,
        createdAt     TEXT    NOT NULL,
        syncedAt      TEXT
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USUARIOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> guardarUsuario(Map<String, dynamic> usuario) async {
    final database = await db;
    await database.insert('usuarios', usuario,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String email) async {
    final database = await db;
    final rows = await database.query('usuarios',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> eliminarUsuarios() async {
    final database = await db;
    await database.delete('usuarios');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> guardarProductos(List<Map<String, dynamic>> productos) async {
    final database = await db;
    final batch    = database.batch();
    batch.delete('productos');
    for (final p in productos) {
      batch.insert('productos', p,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerProductos({
    String search = '',
    int page      = 1,
    int limit     = 10,
  }) async {
    final database = await db;
    final offset   = (page - 1) * limit;
    if (search.isEmpty) {
      return database.query('productos',
          where: 'activo = 1', orderBy: 'nombre ASC',
          limit: limit, offset: offset);
    } else {
      return database.query('productos',
          where: 'activo = 1 AND nombre LIKE ?',
          whereArgs: ['%$search%'],
          orderBy: 'nombre ASC', limit: limit, offset: offset);
    }
  }

  Future<int> contarProductos({String search = ''}) async {
    final database = await db;
    final result   = await database.rawQuery(
      search.isEmpty
          ? 'SELECT COUNT(*) as total FROM productos WHERE activo = 1'
          : "SELECT COUNT(*) as total FROM productos WHERE activo = 1 AND nombre LIKE '%$search%'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> tieneProductos() async => (await contarProductos()) > 0;

  // ══════════════════════════════════════════════════════════════════════════
  // CLIENTES
  // ══════════════════════════════════════════════════════════════════════════

  /// Reemplaza todos los clientes con datos frescos de la API
  Future<void> guardarClientes(List<Map<String, dynamic>> clientes) async {
    final database = await db;
    final batch    = database.batch();
    batch.delete('clientes');
    for (final c in clientes) {
      batch.insert('clientes', c,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerClientes({
    String search = '',
  }) async {
    final database = await db;
    if (search.isEmpty) {
      return database.query('clientes', orderBy: 'nombre ASC');
    } else {
      return database.query('clientes',
          where: 'nombre LIKE ? OR cedula LIKE ? OR telefono LIKE ?',
          whereArgs: ['%$search%', '%$search%', '%$search%'],
          orderBy: 'nombre ASC');
    }
  }

  Future<bool> tieneClientes() async {
    final database = await db;
    final result   = await database
        .rawQuery('SELECT COUNT(*) as total FROM clientes');
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PEDIDOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Inserta un pedido. Acepta el Map completo de PedidoLocalModel.toDb().
  /// El campo 'detalle' es ignorado si viene embebido (los items van en itemsJson).
  Future<int> insertarPedido(Map<String, dynamic> pedidoMap) async {
    final database = await db;
    // Limpiar claves que no existen en la tabla
    final row = Map<String, dynamic>.from(pedidoMap)..remove('detalle');
    return database.insert('pedidos', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerPedidos() async {
    final database = await db;
    return database.query('pedidos', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> obtenerPedidosPendientes() async {
    final database = await db;
    return database.query('pedidos',
        where: "estado = 'pendiente'", orderBy: 'createdAt ASC');
  }

  Future<void> actualizarEstado(
    int    idPedido,
    String estado, {
    String? errorMsg,
  }) async {
    final database = await db;
    final values   = <String, dynamic>{'estado': estado};
    if (estado   == 'sincronizado') values['syncedAt'] = DateTime.now().toIso8601String();
    if (errorMsg != null)           values['errorMsg'] = errorMsg;

    await database.update('pedidos', values,
        where: 'id = ?', whereArgs: [idPedido]);
  }

  Future<void> eliminarPedido(int idPedido) async {
    final database = await db;
    await database.delete('pedidos', where: 'id = ?', whereArgs: [idPedido]);
  }
}