# Integración con Flutter

Guía para migrar la app Flutter de SQLite local a la API REST.

## 📦 Dependencias Necesarias

Agrega a `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2  # Para guardar token/config
```

## 🔧 Servicio API

Crea `lib/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://tu-proyecto.up.railway.app';
  // Para desarrollo local: 'http://localhost:8080'
  
  // Usuarios
  static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error al obtener usuarios');
  }

  static Future<Map<String, dynamic>> crearUsuario(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Error al crear usuario');
  }

  static Future<void> eliminarUsuario(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/usuarios/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar usuario');
    }
  }

  static Future<Map<String, dynamic>> actualizarCampos(int id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$id/campos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al actualizar usuario');
  }

  // Orden de actividades
  static Future<List<String>> obtenerOrdenActividades(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/$userId/orden-actividades'));
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Error al obtener orden');
  }

  static Future<void> guardarOrdenActividades(int userId, List<String> orden) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$userId/orden-actividades'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'orden': orden}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al guardar orden');
    }
  }

  // Actividades habilitadas
  static Future<List<String>> obtenerActividadesHabilitadas(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/$userId/actividades-habilitadas'));
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }
    throw Exception('Error al obtener actividades habilitadas');
  }

  static Future<void> guardarActividadesHabilitadas(int userId, List<String> actividades) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$userId/actividades-habilitadas'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'actividades': actividades}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al guardar actividades');
    }
  }

  // Vocabulario
  static Future<List<Map<String, dynamic>>> obtenerVocabulario(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/vocabulario?userId=$userId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error al obtener vocabulario');
  }

  static Future<Map<String, dynamic>> crearVocabulario(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vocabulario'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Error al crear vocabulario');
  }

  // Sesiones
  static Future<Map<String, dynamic>> crearSesion({
    required int userId,
    required String actividad,
    required int inicioAt,
    String? nivel,
    List<String>? palabras,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sesiones'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'actividad': actividad,
        'inicio_at': inicioAt,
        'nivel': nivel,
        'palabras': palabras,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Error al crear sesión');
  }

  static Future<void> finalizarSesion({
    required int sesionId,
    required int finAt,
    required int aciertos,
    required int errores,
    required String resultado,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sesiones/$sesionId/finalizar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fin_at': finAt,
        'aciertos': aciertos,
        'errores': errores,
        'resultado': resultado,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al finalizar sesión');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerSesiones({
    int? userId,
    String? actividad,
  }) async {
    String url = '$baseUrl/sesiones?';
    if (userId != null) url += 'userId=$userId&';
    if (actividad != null) url += 'actividad=$actividad';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error al obtener sesiones');
  }

  static Future<void> borrarSesionesUsuario(int userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/sesiones?userId=$userId'));
    if (response.statusCode != 204) {
      throw Exception('Error al borrar sesiones');
    }
  }

  // Upload de archivos
  static Future<Map<String, dynamic>> subirImagen(String filePath, {String type = 'avatar'}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload?type=$type'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al subir imagen');
  }
}
```

## 🔄 Migración de DBHelper

### Antes (SQLite):
```dart
final usuarios = await DBHelper.obtenerUsuarios();
```

### Después (API):
```dart
final usuarios = await ApiService.obtenerUsuarios();
```

### Ejemplo completo en previo_juego.dart:

```dart
Future<void> _cargarConfiguracionActividades() async {
  try {
    final orden = await ApiService.obtenerOrdenActividades(widget.userId);
    final habilitadas = await ApiService.obtenerActividadesHabilitadas(widget.userId);
    setState(() {
      ordenActividades = orden;
      actividadesHabilitadas = habilitadas;
    });
    _cargarProgresoActividades();
  } catch (e) {
    print('Error cargando configuración: $e');
    // Usar valores por defecto si falla
    setState(() {
      ordenActividades = [
        'aprendizaje',
        'discriminacion',
        'discriminacion_inversa',
        'silabas',
        'arrastre',
        'doble',
        'silabas_orden',
        'silabas_distrac',
      ];
      actividadesHabilitadas = ordenActividades;
    });
  }
}
```

## 📱 Manejo de Errores

```dart
try {
  await ApiService.crearUsuario(data);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Usuario creado correctamente')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  );
}
```

## 🖼️ Upload de Imágenes

```dart
Future<void> _cambiarFotoUsuario() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    try {
      // Subir imagen al servidor
      final result = await ApiService.subirImagen(
        pickedFile.path,
        type: 'avatar',
      );
      
      // Actualizar usuario con la nueva foto
      await ApiService.actualizarCampos(userId, {
        'foto': result['filename'],
      });
      
      setState(() {
        fotoUsuario = result['url']; // URL completa de la imagen
      });
    } catch (e) {
      print('Error subiendo imagen: $e');
    }
  }
}
```

## 💾 Caché Offline (Opcional)

Para mantener funcionalidad offline:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> guardarCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  static Future<dynamic> obtenerCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }
}

// Uso:
Future<List<Map<String, dynamic>>> obtenerUsuariosConCache() async {
  try {
    // Intentar obtener de la API
    final usuarios = await ApiService.obtenerUsuarios();
    // Guardar en caché
    await CacheService.guardarCache('usuarios', usuarios);
    return usuarios;
  } catch (e) {
    // Si falla, usar caché
    final cache = await CacheService.obtenerCache('usuarios');
    if (cache != null) {
      return List<Map<String, dynamic>>.from(cache);
    }
    throw Exception('No hay conexión y no hay caché');
  }
}
```

## 🔐 Configuración de Desarrollo vs Producción

```dart
class Config {
  static const bool isDevelopment = bool.fromEnvironment('dart.vm.product') == false;
  static String get baseUrl => isDevelopment
      ? 'http://localhost:8080'
      : 'https://tu-proyecto.up.railway.app';
}

// Actualiza ApiService:
static String get baseUrl => Config.baseUrl;
```

## ✅ Checklist de Migración

- [ ] Agregar dependencia `http` a pubspec.yaml
- [ ] Crear `api_service.dart`
- [ ] Reemplazar `DBHelper.obtenerUsuarios()` → `ApiService.obtenerUsuarios()`
- [ ] Reemplazar `DBHelper.obtenerOrdenActividades()` → `ApiService.obtenerOrdenActividades()`
- [ ] Reemplazar `DBHelper.obtenerActividadesHabilitadas()` → `ApiService.obtenerActividadesHabilitadas()`
- [ ] Actualizar manejo de imágenes (usar URLs en lugar de paths locales)
- [ ] Agregar manejo de errores con try-catch
- [ ] Probar en desarrollo local primero
- [ ] Actualizar baseUrl a producción
- [ ] (Opcional) Implementar caché offline

---

## 🧪 Testing

```bash
# Desarrollo local - backend
cd backend
npm run dev

# Flutter
flutter run -d chrome --dart-define=BASE_URL=http://localhost:8080
```
