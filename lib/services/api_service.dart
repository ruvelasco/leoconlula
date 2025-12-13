import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // URL del backend en Railway
  static const String baseUrl = 'https://worthy-wonder-production-7e0b.up.railway.app';

  // Headers comunes
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ==================== USUARIOS ====================

  /// Crear un nuevo usuario
  static Future<Map<String, dynamic>> insertarUsuario(String nombre, String foto) async {
    try {
      debugPrint('📤 API: Creando usuario "$nombre" con foto "$foto"');
      debugPrint('📍 URL: $baseUrl/usuarios');

      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre,
          'foto': foto,
        }),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Usuario creado con ID: ${result['id']}');
        return result;
      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al crear usuario: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Excepción en insertarUsuario: $e');
      rethrow;
    }
  }

  /// Obtener todos los usuarios
  static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    try {
      debugPrint('📤 API: Obteniendo usuarios...');
      final response = await http.get(Uri.parse('$baseUrl/usuarios'));

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} usuarios obtenidos');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener usuarios: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Excepción en obtenerUsuarios: $e');
      return [];
    }
  }

  /// Eliminar un usuario
  static Future<void> eliminarUsuario(int id) async {
    try {
      debugPrint("Eliminando usuario con id: $id");
      final response = await http.delete(Uri.parse('$baseUrl/usuarios/$id'));

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar usuario: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en eliminarUsuario: $e');
      rethrow;
    }
  }

  /// Actualizar un campo específico del usuario
  static Future<void> actualizarCampoUsuarioBool(int userId, String campo, bool valor) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/usuarios/$userId/campos'),
        headers: _headers,
        body: jsonEncode({campo: valor}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar campo: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en actualizarCampoUsuarioBool: $e');
      rethrow;
    }
  }

  /// Obtener el orden de actividades de un usuario
  static Future<List<String>> obtenerOrdenActividades(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/$userId/orden-actividades'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Error al obtener orden actividades: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en obtenerOrdenActividades: $e');
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

  /// Guardar el orden de actividades de un usuario
  static Future<void> guardarOrdenActividades(int userId, List<String> orden) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/usuarios/$userId/orden-actividades'),
        headers: _headers,
        body: jsonEncode({'orden': orden}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al guardar orden actividades: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en guardarOrdenActividades: $e');
      rethrow;
    }
  }

  /// Obtener las actividades habilitadas de un usuario
  static Future<List<String>> obtenerActividadesHabilitadas(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/$userId/actividades-habilitadas'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Error al obtener actividades habilitadas: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en obtenerActividadesHabilitadas: $e');
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

  /// Guardar las actividades habilitadas de un usuario
  static Future<void> guardarActividadesHabilitadas(int userId, List<String> actividades) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/usuarios/$userId/actividades-habilitadas'),
        headers: _headers,
        body: jsonEncode({'actividades': actividades}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al guardar actividades habilitadas: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en guardarActividadesHabilitadas: $e');
      rethrow;
    }
  }

  // ==================== VOCABULARIO ====================

  /// Insertar una nueva palabra al vocabulario
  static Future<void> insertarVocabulario(String nombreImagen, String label, int userId, {String silabas = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vocabulario'),
        headers: _headers,
        body: jsonEncode({
          'nombreImagen': nombreImagen,
          'label': label,
          'usuarioId': userId,
          'silabas': silabas,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al insertar vocabulario: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en insertarVocabulario: $e');
      rethrow;
    }
  }

  /// Obtener todo el vocabulario (opcionalmente filtrado por usuario)
  static Future<List<Map<String, dynamic>>> obtenerVocabulario({int? userId}) async {
    try {
      final uri = userId != null
          ? Uri.parse('$baseUrl/vocabulario?userId=$userId')
          : Uri.parse('$baseUrl/vocabulario');

      debugPrint('📤 API: Obteniendo vocabulario...');
      debugPrint('📍 URL: $uri');
      debugPrint('📍 userId parameter: $userId');

      final response = await http.get(uri);

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} vocabulario items obtenidos');
        if (data.isNotEmpty) {
          debugPrint('📊 Primer item: ${data.first}');
        }
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener vocabulario: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error en obtenerVocabulario: $e');
      return [];
    }
  }

  /// Eliminar una palabra del vocabulario
  static Future<void> eliminarVocabulario(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/vocabulario/$id'));

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar vocabulario: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en eliminarVocabulario: $e');
      rethrow;
    }
  }

  // ==================== SESIONES ====================

  /// Crear una nueva sesión de actividad
  static Future<int> crearSesionActividad({
    required int userId,
    required String actividad,
    DateTime? inicio,
    String? nivel,
    List<String>? palabras,
  }) async {
    try {
      final inicioMs = (inicio ?? DateTime.now()).millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse('$baseUrl/sesiones'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'actividad': actividad,
          'inicio_at': inicioMs,
          'nivel': nivel,
          'palabras': palabras ?? [],
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int;
      } else {
        throw Exception('Error al crear sesión: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en crearSesionActividad: $e');
      rethrow;
    }
  }

  /// Finalizar una sesión de actividad
  static Future<void> finalizarSesionActividad(
    int sesionId, {
    DateTime? fin,
    int? aciertos,
    int? errores,
    String? resultado,
    int? duracionMs,
  }) async {
    try {
      final finMs = fin?.millisecondsSinceEpoch;

      final response = await http.patch(
        Uri.parse('$baseUrl/sesiones/$sesionId/finalizar'),
        headers: _headers,
        body: jsonEncode({
          if (finMs != null) 'fin_at': finMs,
          if (aciertos != null) 'aciertos': aciertos,
          if (errores != null) 'errores': errores,
          if (resultado != null) 'resultado': resultado,
          if (duracionMs != null) 'duracion_ms': duracionMs,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al finalizar sesión: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en finalizarSesionActividad: $e');
      rethrow;
    }
  }

  /// Registrar detalle de vocabulario en una sesión
  static Future<void> registrarDetalleVocabulario({
    required int sesionId,
    int? vocabularioId,
    bool mostrada = false,
    bool acierto = false,
    int? tiempoMs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sesiones/$sesionId/detalle'),
        headers: _headers,
        body: jsonEncode({
          'vocabularioId': vocabularioId,
          'mostrada': mostrada,
          'acierto': acierto,
          'tiempo_ms': tiempoMs,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al registrar detalle: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en registrarDetalleVocabulario: $e');
      rethrow;
    }
  }

  /// Obtener sesiones (con filtros opcionales)
  static Future<List<Map<String, dynamic>>> obtenerSesiones({int? userId, String? actividad}) async {
    try {
      String url = '$baseUrl/sesiones';
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (actividad != null) params['actividad'] = actividad;

      final uri = Uri.parse(url).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener sesiones: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en obtenerSesiones: $e');
      return [];
    }
  }

  /// Borrar todas las sesiones de un usuario
  static Future<void> borrarSesionesUsuario(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sesiones?userId=$userId'),
      );

      if (response.statusCode != 204) {
        throw Exception('Error al borrar sesiones: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en borrarSesionesUsuario: $e');
      rethrow;
    }
  }

  /// Borrar todas las sesiones
  static Future<void> borrarTodasLasSesiones() async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/sesiones'));

      if (response.statusCode != 204) {
        throw Exception('Error al borrar todas las sesiones: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en borrarTodasLasSesiones: $e');
      rethrow;
    }
  }

  /// Obtener número de repeticiones de un usuario
  static Future<int> obtenerNumeroRepeticiones({int? userId}) async {
    try {
      final usuarios = await obtenerUsuarios();
      Map<String, dynamic>? usuario;

      if (userId != null) {
        usuario = usuarios.firstWhere(
          (u) => u['id'] == userId,
          orElse: () => {},
        );
      }

      if (usuario == null || usuario.isEmpty) {
        if (usuarios.isNotEmpty) {
          usuario = usuarios.first;
        }
      }

      if (usuario != null && usuario['numero_repeticiones'] != null) {
        return int.tryParse(usuario['numero_repeticiones'].toString()) ?? 5;
      }
      return 5;
    } catch (e) {
      debugPrint('Error en obtenerNumeroRepeticiones: $e');
      return 5;
    }
  }

  // ==================== UPLOAD DE ARCHIVOS ====================

  /// Subir una imagen (avatar o vocabulario)
  static Future<String?> subirImagen(File archivo, {String tipo = 'avatar'}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload?type=$tipo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          archivo.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        throw Exception('Error al subir imagen: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en subirImagen: $e');
      return null;
    }
  }
}
