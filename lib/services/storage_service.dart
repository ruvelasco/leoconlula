import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Use secure storage for mobile, shared preferences for web
  static const _secureStorage = FlutterSecureStorage(
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

  /// Get SharedPreferences instance (for web)
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Save access and refresh tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      if (kIsWeb) {
        // Use SharedPreferences for web (more reliable)
        final prefs = await _prefs;
        await Future.wait([
          prefs.setString(_accessTokenKey, accessToken),
          prefs.setString(_refreshTokenKey, refreshToken),
        ]);
      } else {
        // Use secure storage for mobile
        await Future.wait([
          _secureStorage.write(key: _accessTokenKey, value: accessToken),
          _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
        ]);
      }
      debugPrint('✅ Tokens guardados exitosamente (${kIsWeb ? 'web' : 'móvil'})');
    } catch (e) {
      debugPrint('❌ Error al guardar tokens: $e');
      rethrow;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        return prefs.getString(_accessTokenKey);
      } else {
        return await _secureStorage.read(key: _accessTokenKey);
      }
    } catch (e) {
      debugPrint('❌ Error al leer access token: $e');
      return null;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        return prefs.getString(_refreshTokenKey);
      } else {
        return await _secureStorage.read(key: _refreshTokenKey);
      }
    } catch (e) {
      debugPrint('❌ Error al leer refresh token: $e');
      return null;
    }
  }

  /// Get both tokens
  static Future<Map<String, String>?> getTokens() async {
    try {
      String? accessToken;
      String? refreshToken;

      if (kIsWeb) {
        final prefs = await _prefs;
        accessToken = prefs.getString(_accessTokenKey);
        refreshToken = prefs.getString(_refreshTokenKey);
      } else {
        final results = await Future.wait([
          _secureStorage.read(key: _accessTokenKey),
          _secureStorage.read(key: _refreshTokenKey),
        ]);
        accessToken = results[0];
        refreshToken = results[1];
      }

      if (accessToken != null && refreshToken != null) {
        debugPrint('✅ Tokens encontrados en storage');
        return {
          'access': accessToken,
          'refresh': refreshToken,
        };
      }
      debugPrint('⚠️ No se encontraron tokens en storage');
      return null;
    } catch (e) {
      debugPrint('❌ Error al leer tokens: $e');
      return null;
    }
  }

  /// Save user data (optional, for offline access)
  static Future<void> saveUserData(String userData) async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        await prefs.setString(_userDataKey, userData);
      } else {
        await _secureStorage.write(key: _userDataKey, value: userData);
      }
      debugPrint('✅ Datos de usuario guardados');
    } catch (e) {
      debugPrint('❌ Error al guardar datos de usuario: $e');
    }
  }

  /// Get user data
  static Future<String?> getUserData() async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        return prefs.getString(_userDataKey);
      } else {
        return await _secureStorage.read(key: _userDataKey);
      }
    } catch (e) {
      debugPrint('❌ Error al leer datos de usuario: $e');
      return null;
    }
  }

  /// Clear all tokens and user data
  static Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        await Future.wait([
          prefs.remove(_accessTokenKey),
          prefs.remove(_refreshTokenKey),
          prefs.remove(_userDataKey),
        ]);
      } else {
        await Future.wait([
          _secureStorage.delete(key: _accessTokenKey),
          _secureStorage.delete(key: _refreshTokenKey),
          _secureStorage.delete(key: _userDataKey),
        ]);
      }
      debugPrint('✅ Todos los datos de autenticación eliminados');
    } catch (e) {
      debugPrint('❌ Error al eliminar datos: $e');
      rethrow;
    }
  }

  /// Clear only tokens (keep user data)
  static Future<void> clearTokens() async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        await Future.wait([
          prefs.remove(_accessTokenKey),
          prefs.remove(_refreshTokenKey),
        ]);
      } else {
        await Future.wait([
          _secureStorage.delete(key: _accessTokenKey),
          _secureStorage.delete(key: _refreshTokenKey),
        ]);
      }
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
