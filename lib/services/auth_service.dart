import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/login_response.dart';

class AuthService {
  static const String baseUrl =
      'https://worthy-wonder-production-7e0b.up.railway.app';

  /// Register a new user
  static Future<LoginResponse> register({
    required String email,
    required String password,
    required String nombre,
    required String role, // PROFESOR or PADRE
  }) async {
    try {
      debugPrint('📝 Registrando usuario: $email ($role)');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nombre': nombre,
          'role': role,
        }),
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Usuario registrado exitosamente');
        return LoginResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error'] ?? 'Error al registrar usuario';
        debugPrint('❌ Error en registro: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Error en register: $e');
      rethrow;
    }
  }

  /// Login user
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Iniciando sesión: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Login exitoso');
        return LoginResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage =
            error['error'] ?? 'Email o contraseña incorrectos';
        debugPrint('❌ Error en login: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      rethrow;
    }
  }

  /// Refresh access token
  static Future<LoginResponse> refreshToken(String refreshToken) async {
    try {
      debugPrint('🔄 Refrescando access token');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Token refrescado exitosamente');

        // El endpoint de refresh devuelve solo tokens, no user
        // Necesitamos obtener el usuario actual
        final user = await getCurrentUser(data['accessToken'] as String);

        return LoginResponse(
          user: user,
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error'] ?? 'Error al refrescar token';
        debugPrint('❌ Error en refresh: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Error en refreshToken: $e');
      rethrow;
    }
  }

  /// Logout user
  static Future<void> logout(String refreshToken) async {
    try {
      debugPrint('👋 Cerrando sesión');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Sesión cerrada exitosamente');
      } else {
        debugPrint('⚠️ Advertencia en logout: ${response.body}');
        // No lanzamos excepción aquí, solo advertencia
      }
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
      // No relanzamos el error para permitir logout local incluso si falla el servidor
    }
  }

  /// Get current authenticated user
  static Future<AuthUser> getCurrentUser(String accessToken) async {
    try {
      debugPrint('👤 Obteniendo usuario actual');

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        debugPrint('✅ Usuario obtenido: ${userData['nombre']}');
        return AuthUser.fromJson(userData);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error'] ?? 'Error al obtener usuario';
        debugPrint('❌ Error en getCurrentUser: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Error en getCurrentUser: $e');
      rethrow;
    }
  }

  /// Validate password strength
  static Map<String, dynamic> validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('Mínimo 8 caracteres');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('Al menos una mayúscula');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('Al menos una minúscula');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('Al menos un número');
    }

    return {
      'valid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
