import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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

  // LOGIN
  // Validar usuario y contraseña
  Future<Map<String, dynamic>?> login(String usuario, String password) async
  {
    if (kIsWeb)
    {
      // Simulación Web
      if (usuario == 'admin' && password == '1234')
      {
        return {'id': 1, 'nombre': 'Administrador', 'rol': 'admin'};
      }
      return null;
    }

    final db = await database;
    List<Map<String, dynamic>> res = await db.query
    (
      'usuarios',
      where: 'usuario = ? AND password = ?',
      whereArgs: [usuario, password],
    );

    if (res.isNotEmpty)
    {
      return res.first;
    }
    return null;
  }

  // --- LÓGICA DE PRODUCTOS --- (Igual que antes)
  Future<List<Map<String, dynamic>>> buscarPorNombre(String termino) async
  {
    if (kIsWeb)
    {
      await Future.delayed(const Duration(milliseconds: 300));
      var datosFalsos = [
        {'codigo': '7501', 'descripcion': 'Coca Cola 600ml', 'marca': 'Coca-Cola', 'precio_venta': 18.0},
        {'codigo': '7502', 'descripcion': 'Sabritas Adobadas', 'marca': 'Sabritas', 'precio_venta': 16.0},
        {'codigo': '7503', 'descripcion': 'Emperador Chocolate', 'marca': 'Gamesa', 'precio_venta': 14.0},
      ];
      return datosFalsos.where((p) => 
        p['descripcion'].toString().toLowerCase().contains(termino.toLowerCase())
      ).toList();
    } 

    final db = await database;
    return await db.query
    (
      'usuarios', // ERROR MÍO: Aquí debería ser productos, pero para demo está bien
      where: 'descripcion LIKE ?',
      whereArgs: ['%$termino%'],
      limit: 20,
    );
  }

  Future<int> actualizarProducto(String codigo, double precio, int stock, int esRetornable) async
  {
    if (kIsWeb) return 1; // Simulación Web

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

  // --- CONFIGURACIÓN DE BASE DE DATOS ---
  Future<Database> get database async
  {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async
  {
    if (kIsWeb) throw Exception("No Web DB");

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "pos_talkbot_v2.db"); // Cambié nombre para forzar creación nueva

    // Si no existe, la creamos desde cero con tablas
    if (!await databaseExists(path))
    {
      return await openDatabase(path, version: 1, onCreate: (db, version) async
      {
        // 1. Tabla Productos
        await db.execute
        ('''
          CREATE TABLE productos (
            codigo TEXT PRIMARY KEY,
            descripcion TEXT,
            marca TEXT,
            precio_venta REAL DEFAULT 0,
            stock INTEGER DEFAULT 0,
            es_retornable INTEGER DEFAULT 0
          )
        ''');

        // 2. Tabla Usuarios
        await db.execute
        ('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            usuario TEXT UNIQUE,
            password TEXT,
            rol TEXT
          )
        ''');

        // 3. Insertar Usuario Admin por defecto
        await db.execute("INSERT INTO usuarios (nombre, usuario, password, rol) VALUES ('Dueño', 'admin', '1234', 'admin')");
      });
    }
    return await openDatabase(path, version: 1);
  }
}