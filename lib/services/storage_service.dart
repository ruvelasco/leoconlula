import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Save access and refresh tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
      debugPrint('✅ Tokens guardados exitosamente');
    } catch (e) {
      debugPrint('❌ Error al guardar tokens: $e');
      rethrow;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error al leer access token: $e');
      return null;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error al leer refresh token: $e');
      return null;
    }
  }

  /// Get both tokens
  static Future<Map<String, String>?> getTokens() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _accessTokenKey),
        _storage.read(key: _refreshTokenKey),
      ]);

      final accessToken = results[0];
      final refreshToken = results[1];

      if (accessToken != null && refreshToken != null) {
        return {
          'access': accessToken,
          'refresh': refreshToken,
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error al leer tokens: $e');
      return null;
    }
  }

  /// Save user data (optional, for offline access)
  static Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: _userDataKey, value: userData);
      debugPrint('✅ Datos de usuario guardados');
    } catch (e) {
      debugPrint('❌ Error al guardar datos de usuario: $e');
    }
  }

  /// Get user data
  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userDataKey);
    } catch (e) {
      debugPrint('❌ Error al leer datos de usuario: $e');
      return null;
    }
  }

  /// Clear all tokens and user data
  static Future<void> clearAll() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userDataKey),
      ]);
      debugPrint('✅ Todos los datos de autenticación eliminados');
    } catch (e) {
      debugPrint('❌ Error al eliminar datos: $e');
      rethrow;
    }
  }

  /// Clear only tokens (keep user data)
  static Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
      debugPrint('✅ Tokens eliminados');
    } catch (e) {
      debugPrint('❌ Error al eliminar tokens: $e');
      rethrow;
    }
  }

  /// Check if user is logged in (has tokens)
  static Future<bool> hasValidTokens() async {
    final tokens = await getTokens();
    return tokens != null &&
        tokens['access'] != null &&
        tokens['refresh'] != null;
  }
}
