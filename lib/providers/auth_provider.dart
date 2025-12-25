import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/auth_user.dart';
import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  AuthUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = true;
  String? _error;

  // Getters
  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize authentication state from storage
  Future<void> initialize() async {
    try {
      debugPrint('🔐 Inicializando AuthProvider...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to load tokens from secure storage
      final tokens = await StorageService.getTokens();

      if (tokens == null) {
        debugPrint('⚠️ No hay tokens almacenados');
        _isLoading = false;
        notifyListeners();
        return;
      }

      _accessToken = tokens['access'];
      _refreshToken = tokens['refresh'];

      // Check if access token is expired
      if (_accessToken != null && JwtDecoder.isExpired(_accessToken!)) {
        debugPrint('⚠️ Access token expirado, intentando refresh...');

        if (_refreshToken != null) {
          try {
            // Try to refresh the token
            final response = await AuthService.refreshToken(_refreshToken!);
            _accessToken = response.accessToken;
            _refreshToken = response.refreshToken;
            _currentUser = response.user;

            // Save new tokens
            await StorageService.saveTokens(
              accessToken: _accessToken!,
              refreshToken: _refreshToken!,
            );

            // Save user data
            await StorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

            debugPrint('✅ Token refrescado exitosamente');
          } catch (e) {
            debugPrint('❌ Error al refrescar token: $e');
            await _clearAuthState();
          }
        } else {
          await _clearAuthState();
        }
      } else {
        // Access token is still valid, load user data
        try {
          // Try to get user from storage first
          final userData = await StorageService.getUserData();

          if (userData != null) {
            _currentUser = AuthUser.fromJson(
              jsonDecode(userData) as Map<String, dynamic>,
            );
            debugPrint('✅ Usuario cargado desde storage: ${_currentUser!.nombre}');
          } else {
            // Fetch from API if not in storage
            _currentUser = await AuthService.getCurrentUser(_accessToken!);
            await StorageService.saveUserData(jsonEncode(_currentUser!.toJson()));
            debugPrint('✅ Usuario cargado desde API: ${_currentUser!.nombre}');
          }
        } catch (e) {
          debugPrint('❌ Error al cargar usuario: $e');
          await _clearAuthState();
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error en initialize: $e');
      _error = e.toString();
      _isLoading = false;
      await _clearAuthState();
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Intentando login para: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await AuthService.login(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;

      // Save tokens and user data
      await StorageService.saveTokens(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
      await StorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

      debugPrint('✅ Login exitoso: ${_currentUser!.nombre}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String nombre,
    required String role,
  }) async {
    try {
      debugPrint('📝 Intentando registro para: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await AuthService.register(
        email: email,
        password: password,
        nombre: nombre,
        role: role,
      );

      _currentUser = response.user;
      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;

      // Save tokens and user data
      await StorageService.saveTokens(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
      await StorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

      debugPrint('✅ Registro exitoso: ${_currentUser!.nombre}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error en register: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      debugPrint('👋 Cerrando sesión...');

      // Try to revoke refresh token on server
      if (_refreshToken != null) {
        try {
          await AuthService.logout(_refreshToken!);
        } catch (e) {
          debugPrint('⚠️ Error al revocar token en servidor: $e');
          // Continue with local logout even if server call fails
        }
      }

      await _clearAuthState();

      debugPrint('✅ Sesión cerrada exitosamente');
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
      // Ensure local state is cleared even if there's an error
      await _clearAuthState();
    }
  }

  /// Get valid access token (auto-refresh if expired)
  Future<String?> getValidAccessToken() async {
    try {
      // Check if we have a token
      if (_accessToken == null) {
        debugPrint('⚠️ No hay access token');
        return null;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(_accessToken!)) {
        debugPrint('⚠️ Access token expirado, refrescando...');

        if (_refreshToken == null) {
          debugPrint('❌ No hay refresh token disponible');
          await _clearAuthState();
          return null;
        }

        try {
          // Refresh the token
          final response = await AuthService.refreshToken(_refreshToken!);
          _accessToken = response.accessToken;
          _refreshToken = response.refreshToken;
          _currentUser = response.user;

          // Save new tokens
          await StorageService.saveTokens(
            accessToken: _accessToken!,
            refreshToken: _refreshToken!,
          );
          await StorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

          debugPrint('✅ Token refrescado exitosamente');
          notifyListeners();

          return _accessToken;
        } catch (e) {
          debugPrint('❌ Error al refrescar token: $e');
          await _clearAuthState();
          return null;
        }
      }

      // Token is still valid
      return _accessToken;
    } catch (e) {
      debugPrint('❌ Error en getValidAccessToken: $e');
      return null;
    }
  }

  /// Clear authentication state
  Future<void> _clearAuthState() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _error = null;

    await StorageService.clearAll();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
