import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import 'api_service.dart';

/// Servicio unificado de datos que permite alternar entre SQLite local y API REST
///
/// Cambiar [useRemoteApi] a true para usar el backend en Railway
/// Cambiar [useRemoteApi] a false para usar SQLite local
class DataService {
  // ⚙️ CONFIGURACIÓN: Cambiar a true para usar el backend remoto
  static const bool useRemoteApi = true;

  // ==================== USUARIOS ====================

  static Future<dynamic> insertarUsuario(String nombre, String foto) async {
    if (useRemoteApi) {
      return await ApiService.insertarUsuario(nombre, foto);
    } else {
      return await DBHelper.insertarUsuario(nombre, foto);
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    if (useRemoteApi) {
      return await ApiService.obtenerUsuarios();
    } else {
      return await DBHelper.obtenerUsuarios();
    }
  }

  static Future<void> eliminarUsuario(int id) async {
    if (useRemoteApi) {
      return await ApiService.eliminarUsuario(id);
    } else {
      return await DBHelper.eliminarUsuario(id);
    }
  }

  static Future<void> actualizarCampoUsuarioBool(
      int userId, String campo, bool valor) async {
    if (useRemoteApi) {
      return await ApiService.actualizarCampoUsuarioBool(userId, campo, valor);
    } else {
      return await DBHelper.actualizarCampoUsuarioBool(userId, campo, valor);
    }
  }

  static Future<List<String>> obtenerOrdenActividades(int userId) async {
    if (useRemoteApi) {
      return await ApiService.obtenerOrdenActividades(userId);
    } else {
      return await DBHelper.obtenerOrdenActividades(userId);
    }
  }

  static Future<void> guardarOrdenActividades(
      int userId, List<String> orden) async {
    if (useRemoteApi) {
      return await ApiService.guardarOrdenActividades(userId, orden);
    } else {
      return await DBHelper.guardarOrdenActividades(userId, orden);
    }
  }

  static Future<List<String>> obtenerActividadesHabilitadas(int userId) async {
    if (useRemoteApi) {
      return await ApiService.obtenerActividadesHabilitadas(userId);
    } else {
      return await DBHelper.obtenerActividadesHabilitadas(userId);
    }
  }

  static Future<void> guardarActividadesHabilitadas(
      int userId, List<String> actividades) async {
    if (useRemoteApi) {
      return await ApiService.guardarActividadesHabilitadas(
          userId, actividades);
    } else {
      return await DBHelper.guardarActividadesHabilitadas(userId, actividades);
    }
  }

  static Future<int> obtenerNumeroRepeticiones({int? userId}) async {
    if (useRemoteApi) {
      return await ApiService.obtenerNumeroRepeticiones(userId: userId);
    } else {
      return await DBHelper.obtenerNumeroRepeticiones(userId: userId);
    }
  }

  // ==================== VOCABULARIO ====================

  static Future<void> insertarVocabulario(
      String nombreImagen, String label, int userId,
      {String silabas = ''}) async {
    if (useRemoteApi) {
      return await ApiService.insertarVocabulario(nombreImagen, label, userId,
          silabas: silabas);
    } else {
      return await DBHelper.insertarVocabulario(nombreImagen, label, userId,
          silabas: silabas);
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerVocabulario(
      {int? userId}) async {
    debugPrint('🔧 DataService.obtenerVocabulario - userId: $userId, useRemoteApi: $useRemoteApi');
    if (useRemoteApi) {
      final result = await ApiService.obtenerVocabulario(userId: userId);
      debugPrint('🔧 DataService.obtenerVocabulario - Resultado API: ${result.length} items');
      return result;
    } else {
      // DBHelper.obtenerVocabulario() no tiene parámetro userId, necesitamos filtrar manualmente
      final todos = await DBHelper.obtenerVocabulario();
      if (userId == null) return todos;
      final filtered = todos.where((v) => v['idUsuario'] == userId).toList();
      debugPrint('🔧 DataService.obtenerVocabulario - Resultado Local: ${filtered.length} items');
      return filtered;
    }
  }

  static Future<void> eliminarVocabulario(int id) async {
    if (useRemoteApi) {
      return await ApiService.eliminarVocabulario(id);
    } else {
      return await DBHelper.eliminarVocabulario(id);
    }
  }

  // ==================== SESIONES ====================

  static Future<int> crearSesionActividad({
    required int userId,
    required String actividad,
    DateTime? inicio,
    String? nivel,
    List<String>? palabras,
  }) async {
    if (useRemoteApi) {
      return await ApiService.crearSesionActividad(
        userId: userId,
        actividad: actividad,
        inicio: inicio,
        nivel: nivel,
        palabras: palabras,
      );
    } else {
      return await DBHelper.crearSesionActividad(
        userId: userId,
        actividad: actividad,
        inicio: inicio,
        nivel: nivel,
        palabras: palabras,
      );
    }
  }

  static Future<void> finalizarSesionActividad(
    int sesionId, {
    DateTime? fin,
    int? aciertos,
    int? errores,
    String? resultado,
    int? duracionMs,
  }) async {
    if (useRemoteApi) {
      return await ApiService.finalizarSesionActividad(
        sesionId,
        fin: fin,
        aciertos: aciertos,
        errores: errores,
        resultado: resultado,
        duracionMs: duracionMs,
      );
    } else {
      return await DBHelper.finalizarSesionActividad(
        sesionId,
        fin: fin,
        aciertos: aciertos,
        errores: errores,
        resultado: resultado,
        duracionMs: duracionMs,
      );
    }
  }

  static Future<void> registrarDetalleVocabulario({
    required int sesionId,
    int? vocabularioId,
    bool mostrada = false,
    bool acierto = false,
    int? tiempoMs,
  }) async {
    if (useRemoteApi) {
      return await ApiService.registrarDetalleVocabulario(
        sesionId: sesionId,
        vocabularioId: vocabularioId,
        mostrada: mostrada,
        acierto: acierto,
        tiempoMs: tiempoMs,
      );
    } else {
      return await DBHelper.registrarDetalleVocabulario(
        sesionId: sesionId,
        vocabularioId: vocabularioId,
        mostrada: mostrada,
        acierto: acierto,
        tiempoMs: tiempoMs,
      );
    }
  }

  static Future<void> borrarTodasLasSesiones() async {
    if (useRemoteApi) {
      return await ApiService.borrarTodasLasSesiones();
    } else {
      return await DBHelper.borrarTodasLasSesiones();
    }
  }

  static Future<void> borrarSesionesUsuario(int userId) async {
    if (useRemoteApi) {
      return await ApiService.borrarSesionesUsuario(userId);
    } else {
      return await DBHelper.borrarSesionesUsuario(userId);
    }
  }

  // ==================== ARCHIVOS ====================

  /// Subir imagen y retornar la URL
  /// - Para API remota: sube a Railway y retorna URL completa
  /// - Para SQLite local: retorna la ruta local del archivo
  static Future<String?> subirImagen(File archivo,
      {String tipo = 'avatar'}) async {
    if (useRemoteApi) {
      return await ApiService.subirImagen(archivo, tipo: tipo);
    } else {
      // En local, simplemente retornamos la ruta del archivo
      return archivo.path;
    }
  }

  /// Obtener el ImageProvider correcto según el tipo de imagen (URL o archivo local)
  /// - Para URLs (modo remoto): retorna NetworkImage
  /// - Para archivos locales: retorna FileImage (requiere path completo)
  static Future<ImageProvider?> obtenerImageProvider(String nombreImagen, {String? localPath}) async {
    if (nombreImagen.isEmpty) return null;

    // Si es una URL, usar NetworkImage
    if (nombreImagen.startsWith('http://') || nombreImagen.startsWith('https://')) {
      debugPrint('🖼️ DataService: Usando NetworkImage para: $nombreImagen');
      return NetworkImage(nombreImagen);
    }

    // Si es archivo local, necesitamos el path
    if (useRemoteApi) {
      // En modo remoto pero nombreImagen no es URL, algo está mal
      debugPrint('⚠️ DataService: Modo remoto pero nombreImagen no es URL: $nombreImagen');
      return null;
    }

    // Modo local - usar FileImage
    if (localPath != null) {
      debugPrint('🖼️ DataService: Usando FileImage para: $localPath/$nombreImagen');
      return FileImage(File('$localPath/vocabulario/$nombreImagen'));
    }

    debugPrint('❌ DataService: No se puede cargar imagen sin localPath en modo local');
    return null;
  }
}
