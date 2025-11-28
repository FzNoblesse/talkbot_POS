import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper
{
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper()
  {
    return _instance;
  }

  // Obtener la base de datos
  Future<Database> get database async
  {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
Future<Database> _initDatabase() async {
    if (kIsWeb) throw Exception("Web no soportada en modo producción");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "tienda_produccion_final.db"); 

    bool exists = await databaseExists(path);
    if (!exists) {
      print("📦 Copiando base de datos inicial...");
      try {
        ByteData data = await rootBundle.load("assets/pos_talkbot.db");
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print("✅ Base de datos copiada.");
      } catch (e) {
        print("⚠ Error copiando asset: $e");
      }
    }
    return await openDatabase(
      path, 
      version: 1, 
      onOpen: (db) async {
        try { await db.execute("ALTER TABLE productos ADD COLUMN precio_venta REAL DEFAULT 0"); } catch (e) { /* Ya existía */ }
        try { await db.execute("ALTER TABLE productos ADD COLUMN precio_compra REAL DEFAULT 0"); } catch (e) { /* Ya existía */ }
        try { await db.execute("ALTER TABLE productos ADD COLUMN stock INTEGER DEFAULT 0"); } catch (e) { /* Ya existía */ }
        try { await db.execute("ALTER TABLE productos ADD COLUMN es_retornable INTEGER DEFAULT 0"); } catch (e) { /* Ya existía */ }
        
        // Asegurar tabla USUARIOS
        await db.execute('''
          CREATE TABLE IF NOT EXISTS usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            usuario TEXT UNIQUE,
            password TEXT,
            rol TEXT
          )
        ''');

        var admin = await db.query('usuarios', where: 'usuario = ?', whereArgs: ['Administrador']);
        if (admin.isEmpty) {
           await db.execute("INSERT INTO usuarios (nombre, usuario, password, rol) VALUES ('Admin', 'Administrador', '1234', 'Administrador')");
        }
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT,
            total REAL,
            metodo_pago TEXT,
            usuario_id INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS detalle_ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            venta_id INTEGER,
            producto_codigo TEXT,
            cantidad INTEGER,
            precio_unitario REAL,
            subtotal REAL
          )
        ''');
      },
    );
  }

  // Login
  Future<Map<String, dynamic>?> login(String usuario, String password) async
  {
    final db = await database;
    List<Map<String, dynamic>> res = await db.query
    (
      'usuarios',
      where: 'usuario = ? AND password = ?',
      whereArgs: [usuario, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  // Buscador
  Future<List<Map<String, dynamic>>> buscarPorNombre(String termino) async
  {
    final db = await database;
    return await db.query
    (
      'productos',
      where: 'descripcion LIKE ?',
      whereArgs: ['%$termino%'],
      limit: 50,
    );
  }

  // Actualizar producto
  Future<int> actualizarProducto(String codigo, double precio, int stock, int esRetornable) async
  {
    final db = await database;
    return await db.update
    (
      'productos',
      {
        'precio_venta': precio,
        'stock': stock,
        'es_retornable': esRetornable,
      },
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
  }

  // Registrar una venta
  Future<int> insertarVenta(double total, String metodoPago, int usuarioId, List<Map<String, dynamic>> carrito) async
  {
    final db = await database;
    int ventaId = 0;

    await db.transaction((txn) async
    {
      // Guardar Ticket
      ventaId = await txn.insert('ventas',
      {
        'fecha': DateTime.now().toIso8601String(),
        'total': total,
        'metodo_pago': metodoPago,
        'usuario_id': usuarioId
      });

      // Guardar productos del Ticket
      for (var item in carrito)
      {
        await txn.insert('detalle_ventas',
        {
          'venta_id': ventaId,
          'producto_codigo': item['codigo'],
          'cantidad': item['cantidad'],
          'precio_unitario': item['precio_venta'] ?? 0,
          'subtotal': (item['precio_venta'] ?? 0) * (item['cantidad'] ?? 1)
        });
        
        // Restar del inventario
        // await txn.rawUpdate('UPDATE productos SET stock = stock - ? WHERE codigo = ?', [item['cantidad'], item['codigo']]);
      }
    });
    return ventaId;
  }

  Future<List<Map<String, dynamic>>> obtenerProductos({int limite = 50, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'productos',
      orderBy: 'descripcion ASC',
      limit: limite,
      offset: offset,
    );
  }

  // CREAR NUEVO PRODUCTO
  Future<int> crearProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.insert(
      'productos', 
      producto,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // ELIMINAR PRODUCTO
  Future<int> eliminarProducto(String codigo) async {
    final db = await database;
    return await db.delete('productos', where: 'codigo = ?', whereArgs: [codigo]);
  }  
}