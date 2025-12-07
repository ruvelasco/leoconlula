import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = kIsWeb ? 'leoconlula.db' : join(await getDatabasesPath(), 'leoconlula.db');
    return await openDatabase(
      dbPath,
      version: 5, // Versión con orden y actividades habilitadas
      onCreate: (db, version) async {
        await _createMainTables(db);
        await _createTrackingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTrackingTables(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE usuarios ADD COLUMN numero_repeticiones INTEGER DEFAULT 5",
          );
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE actividad_sesiones ADD COLUMN palabra1 TEXT");
          await db.execute("ALTER TABLE actividad_sesiones ADD COLUMN palabra2 TEXT");
          await db.execute("ALTER TABLE actividad_sesiones ADD COLUMN palabra3 TEXT");
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE usuarios ADD COLUMN orden_actividades TEXT DEFAULT 'aprendizaje,discriminacion,discriminacion_inversa,silabas,arrastre,doble,silabas_orden,silabas_distrac'",
          );
          await db.execute(
            "ALTER TABLE usuarios ADD COLUMN actividades_habilitadas TEXT DEFAULT 'aprendizaje,discriminacion,discriminacion_inversa,silabas,arrastre,doble,silabas_orden,silabas_distrac'",
          );
        }
      },
    );
  }

  static Future<void> _createMainTables(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        foto TEXT,
        fuente TEXT DEFAULT 'ARIAL',
        tipo TEXT DEFAULT 'MAYÚSCULAS',
        voz TEXT DEFAULT 'MONICA',
        leer_palabras INTEGER DEFAULT 1,
        refuerzo_acierto INTEGER DEFAULT 1,
        refuerzo_error INTEGER DEFAULT 1,
        ayudas_visuales INTEGER DEFAULT 0,
        modo_infantil INTEGER DEFAULT 0,
        numero_repeticiones INTEGER DEFAULT 5,
        orden_actividades TEXT DEFAULT 'aprendizaje,discriminacion,discriminacion_inversa,silabas,arrastre,doble,silabas_orden,silabas_distrac',
        actividades_habilitadas TEXT DEFAULT 'aprendizaje,discriminacion,discriminacion_inversa,silabas,arrastre,doble,silabas_orden,silabas_distrac'
      )
    ''');
    await db.execute('''
      CREATE TABLE vocabulario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombreImagen TEXT,
        label TEXT,
        silabas TEXT,
        idUsuario INTEGER,
        acierto INTEGER DEFAULT 0,
        errores INTEGER DEFAULT 0
      );
    ''');
  }

  // Tablas para seguimiento de sesiones y detalle por vocabulario
  static Future<void> _createTrackingTables(Database db) async {
    await db.execute('''
      CREATE TABLE actividad_sesiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        actividad TEXT NOT NULL,
        inicio_at INTEGER NOT NULL,
        fin_at INTEGER,
        duracion_ms INTEGER,
        aciertos INTEGER DEFAULT 0,
        errores INTEGER DEFAULT 0,
        nivel TEXT,
        resultado TEXT,
        palabra1 TEXT,
        palabra2 TEXT,
        palabra3 TEXT,
        FOREIGN KEY(user_id) REFERENCES usuarios(id)
      );
    ''');
    await db.execute('''
      CREATE TABLE sesion_vocabulario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_id INTEGER NOT NULL,
        vocabulario_id INTEGER,
        mostrada INTEGER DEFAULT 0,
        acierto INTEGER DEFAULT 0,
        tiempo_ms INTEGER,
        FOREIGN KEY(sesion_id) REFERENCES actividad_sesiones(id),
        FOREIGN KEY(vocabulario_id) REFERENCES vocabulario(id)
      );
    ''');
  }

  // Métodos para la tabla usuarios
  static Future<int> insertarUsuario(String nombre, String foto) async {
    final db = await database;
    return await db.insert(
      'usuarios',
      {
        'nombre': nombre,
        'foto': foto,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  static Future<void> eliminarUsuario(int id) async {
    debugPrint("Eliminando usuario con id: $id");
    final db = await database;
    await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> actualizarCampoUsuarioBool(int userId, String campo, bool valor) async {
    final db = await database;
    await db.update(
      'usuarios',
      {campo: valor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Métodos para la tabla vocabulario
  static Future<void> insertarVocabulario(String nombreImagen, String label, int userId, {String silabas = ''}) async {
    final db = await database;
    await db.insert(
      'vocabulario',
      {
        'nombreImagen': nombreImagen,
        'label': label,
        'idUsuario': userId,
        'silabas': silabas,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerVocabulario() async {
    final db = await database;
    return await db.query('vocabulario');
  }

  static Future<void> eliminarVocabulario(int id) async {
    final db = await database;
    await db.delete('vocabulario', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para seguimiento de sesiones
  static Future<int> crearSesionActividad({
    required int userId,
    required String actividad,
    DateTime? inicio,
    String? nivel,
    List<String>? palabras,
  }) async {
    final db = await database;
    final inicioMs = (inicio ?? DateTime.now()).millisecondsSinceEpoch;
    final palabrasLim = (palabras ?? []).take(3).toList();
    return await db.insert(
      'actividad_sesiones',
      {
        'user_id': userId,
        'actividad': actividad,
        'inicio_at': inicioMs,
        'nivel': nivel,
        if (palabrasLim.isNotEmpty) 'palabra1': palabrasLim.elementAtOrNull(0),
        if (palabrasLim.length > 1) 'palabra2': palabrasLim.elementAtOrNull(1),
        if (palabrasLim.length > 2) 'palabra3': palabrasLim.elementAtOrNull(2),
      },
    );
  }

  static Future<void> finalizarSesionActividad(
    int sesionId, {
    DateTime? fin,
    int? aciertos,
    int? errores,
    String? resultado,
    int? duracionMs,
  }) async {
    final db = await database;
    final finMs = fin?.millisecondsSinceEpoch;

    // Si no llega duracion y tenemos fin, intenta calcularla con inicio.
    int? duracionCalculada = duracionMs;
    if (duracionCalculada == null && finMs != null) {
      final sesion = await db.query(
        'actividad_sesiones',
        columns: ['inicio_at'],
        where: 'id = ?',
        whereArgs: [sesionId],
        limit: 1,
      );
      if (sesion.isNotEmpty && sesion.first['inicio_at'] != null) {
        duracionCalculada =
            finMs - int.parse(sesion.first['inicio_at'].toString());
      }
    }

    await db.update(
      'actividad_sesiones',
      {
        if (finMs != null) 'fin_at': finMs,
        if (duracionCalculada != null) 'duracion_ms': duracionCalculada,
        if (aciertos != null) 'aciertos': aciertos,
        if (errores != null) 'errores': errores,
        if (resultado != null) 'resultado': resultado,
      },
      where: 'id = ?',
      whereArgs: [sesionId],
    );
  }

  static Future<void> registrarDetalleVocabulario({
    required int sesionId,
    int? vocabularioId,
    bool mostrada = false,
    bool acierto = false,
    int? tiempoMs,
  }) async {
    final db = await database;
    await db.insert(
      'sesion_vocabulario',
      {
        'sesion_id': sesionId,
        'vocabulario_id': vocabularioId,
        'mostrada': mostrada ? 1 : 0,
        'acierto': acierto ? 1 : 0,
        'tiempo_ms': tiempoMs,
      },
    );
  }

  static Future<int> obtenerNumeroRepeticiones({int? userId}) async {
    final db = await database;
    Map<String, dynamic>? usuario;
    if (userId != null) {
      final res = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (res.isNotEmpty) usuario = res.first;
    }
    if (usuario == null) {
      final res = await db.query('usuarios', limit: 1);
      if (res.isNotEmpty) usuario = res.first;
    }
    if (usuario != null && usuario['numero_repeticiones'] != null) {
      return int.tryParse(usuario['numero_repeticiones'].toString()) ?? 5;
    }
    return 5;
  }

  /// Borra todas las sesiones de actividades de la base de datos
  static Future<void> borrarTodasLasSesiones() async {
    final db = await database;
    await db.delete('sesion_vocabulario');
    await db.delete('actividad_sesiones');
  }

  /// Borra las sesiones de un usuario específico
  static Future<void> borrarSesionesUsuario(int userId) async {
    final db = await database;
    // Primero obtenemos los IDs de las sesiones del usuario
    final sesiones = await db.query(
      'actividad_sesiones',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final sesionIds = sesiones.map((s) => s['id'] as int).toList();

    // Borramos los detalles de vocabulario de esas sesiones
    if (sesionIds.isNotEmpty) {
      await db.delete(
        'sesion_vocabulario',
        where: 'sesion_id IN (${sesionIds.join(',')})',
      );
    }

    // Borramos las sesiones del usuario
    await db.delete(
      'actividad_sesiones',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Guarda el orden de actividades para un usuario
  static Future<void> guardarOrdenActividades(int userId, List<String> orden) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'orden_actividades': orden.join(',')},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene el orden de actividades de un usuario
  static Future<List<String>> obtenerOrdenActividades(int userId) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      columns: ['orden_actividades'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (res.isNotEmpty && res.first['orden_actividades'] != null) {
      return (res.first['orden_actividades'] as String).split(',');
    }
    return [
      'aprendizaje',
      'discriminacion',
      'discriminacion_inversa',
      'silabas',
      'arrastre',
      'doble',
      'silabas_orden',
      'silabas_distrac',
    ];
  }

  /// Guarda las actividades habilitadas para un usuario
  static Future<void> guardarActividadesHabilitadas(int userId, List<String> actividades) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'actividades_habilitadas': actividades.join(',')},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene las actividades habilitadas de un usuario
  static Future<List<String>> obtenerActividadesHabilitadas(int userId) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      columns: ['actividades_habilitadas'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (res.isNotEmpty && res.first['actividades_habilitadas'] != null) {
      return (res.first['actividades_habilitadas'] as String).split(',');
    }
    return [
      'aprendizaje',
      'discriminacion',
      'discriminacion_inversa',
      'silabas',
      'arrastre',
      'doble',
      'silabas_orden',
      'silabas_distrac',
    ];
  }
}
