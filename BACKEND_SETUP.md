# 🚀 Configuración del Backend - LeoConLula

Este proyecto puede funcionar con **dos modos de almacenamiento de datos**:

1. **SQLite Local** (por defecto) - Base de datos local en el dispositivo
2. **API REST Remota** - Backend en Railway con PostgreSQL

## 📋 Cambiar entre Local y Remoto

Para cambiar el modo de almacenamiento, edita el archivo:

**[lib/services/data_service.dart](lib/services/data_service.dart)**

```dart
class DataService {
  // ⚙️ CONFIGURACIÓN: Cambiar a true para usar el backend remoto
  static const bool useRemoteApi = false;  // 👈 CAMBIAR AQUÍ

  // false = SQLite local (por defecto)
  // true  = API REST en Railway
}
```

### ✅ Modo Local (SQLite)
```dart
static const bool useRemoteApi = false;
```
- ✅ Funciona sin conexión a Internet
- ✅ Datos almacenados en el dispositivo
- ✅ Más rápido (sin latencia de red)
- ❌ Datos no sincronizados entre dispositivos

### ☁️ Modo Remoto (Railway)
```dart
static const bool useRemoteApi = true;
```
- ✅ Datos en la nube (PostgreSQL)
- ✅ Sincronización entre dispositivos
- ✅ Backup automático
- ❌ Requiere conexión a Internet
- ❌ Latencia de red

---

## 🌐 Backend en Railway

### URL de Producción
```
https://worthy-wonder-production-7e0b.up.railway.app
```

### Endpoints Disponibles

#### 👤 Usuarios
- `GET /usuarios` - Obtener todos los usuarios
- `POST /usuarios` - Crear usuario
- `DELETE /usuarios/:id` - Eliminar usuario
- `PATCH /usuarios/:id/campos` - Actualizar campos
- `GET /usuarios/:id/orden-actividades` - Obtener orden de actividades
- `PATCH /usuarios/:id/orden-actividades` - Actualizar orden
- `GET /usuarios/:id/actividades-habilitadas` - Obtener actividades habilitadas
- `PATCH /usuarios/:id/actividades-habilitadas` - Actualizar actividades

#### 📚 Vocabulario
- `GET /vocabulario?userId=X` - Obtener vocabulario
- `POST /vocabulario` - Crear palabra
- `DELETE /vocabulario/:id` - Eliminar palabra

#### 📊 Sesiones
- `GET /sesiones?userId=X&actividad=Y` - Obtener sesiones
- `POST /sesiones` - Crear sesión
- `PATCH /sesiones/:id/finalizar` - Finalizar sesión
- `POST /sesiones/:id/detalle` - Agregar detalle
- `DELETE /sesiones/:id` - Eliminar sesión
- `DELETE /sesiones?userId=X` - Eliminar sesiones de usuario

#### 📁 Archivos
- `POST /upload?type=avatar` - Subir imagen de avatar
- `POST /upload?type=vocabulario` - Subir imagen de vocabulario
- `GET /uploads/avatars/:filename` - Obtener avatar
- `GET /uploads/vocabulario/:filename` - Obtener imagen

#### ✅ Health Check
- `GET /health` - Estado del servidor

---

## 🛠️ Estructura del Proyecto

### Backend (Node.js + Express + Prisma)
```
backend/
├── src/
│   └── index.ts           # API principal
├── prisma/
│   └── schema.prisma      # Esquema de PostgreSQL
├── nixpacks.toml          # Configuración de Railway
├── package.json
└── README.md
```

### Frontend Flutter - Servicios de Datos
```
lib/services/
├── data_service.dart      # 🎯 Servicio unificado (CAMBIAR AQUÍ)
├── api_service.dart       # Comunicación HTTP con Railway
```

```
lib/helpers/
└── db_helper.dart         # SQLite local (legacy)
```

---

## 🔄 Migración de Datos

Si quieres migrar datos de SQLite local a Railway:

### Opción 1: Exportar/Importar manualmente
1. Ejecuta la app en modo local
2. Extrae los datos necesarios
3. Cambia a modo remoto
4. Inserta los datos via API

### Opción 2: Script de migración
Puedes crear un script Dart que:
1. Lee todos los datos de SQLite
2. Los envía al backend via HTTP
3. Verifica la migración

---

## 📱 Comportamiento de Imágenes

### Modo Local
- Imágenes guardadas en `getApplicationDocumentsDirectory()/avatars`
- Imágenes guardadas en `getApplicationDocumentsDirectory()/vocabulario`
- Rutas locales en la base de datos

### Modo Remoto
- Imágenes subidas a Railway via `POST /upload`
- URLs completas retornadas: `https://worthy-wonder-production-7e0b.up.railway.app/uploads/...`
- Las imágenes se sirven desde Railway

---

## 🧪 Pruebas

### Probar el backend
```bash
# Health check
curl https://worthy-wonder-production-7e0b.up.railway.app/health

# Obtener usuarios
curl https://worthy-wonder-production-7e0b.up.railway.app/usuarios

# Crear usuario
curl -X POST https://worthy-wonder-production-7e0b.up.railway.app/usuarios \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Test", "foto": "test.png"}'
```

### Probar la app Flutter
1. Cambia `useRemoteApi = true` en [lib/services/data_service.dart](lib/services/data_service.dart)
2. Ejecuta `flutter run`
3. Crea un usuario desde la app
4. Verifica en Railway que se creó correctamente

---

## 🔒 Seguridad

- ✅ CORS habilitado para todas las origins
- ✅ Helmet para headers seguros
- ✅ Validación de tipos de archivo (solo imágenes)
- ✅ Límites de tamaño (5MB imágenes, 10MB JSON)
- ⚠️ No hay autenticación implementada (agregar JWT si es necesario)

---

## 📞 Soporte

### Logs de Railway
1. Ve a [railway.app](https://railway.app)
2. Selecciona tu proyecto `worthy-wonder`
3. Click en "Deployments" → "View Logs"

### Reiniciar Servicio
1. Ve al servicio backend en Railway
2. Click en "Settings" → "Restart"

### Variables de Entorno en Railway
```
DATABASE_URL=postgresql://... (auto-configurado por Railway)
PORT=8080
NODE_ENV=production
BASE_URL=https://worthy-wonder-production-7e0b.up.railway.app
```

---

## 📊 Esquema de Base de Datos

Tanto SQLite como PostgreSQL usan el **mismo esquema**:

### Usuario
- `id`, `nombre`, `foto`, `fuente`, `tipo`, `voz`
- `leer_palabras`, `refuerzo_acierto`, `refuerzo_error`
- `ayudas_visuales`, `modo_infantil`, `numero_repeticiones`
- `orden_actividades`, `actividades_habilitadas`

### Vocabulario
- `id`, `nombreImagen`, `label`, `silabas`
- `usuarioId` (o `idUsuario` en SQLite)

### ActividadSesion
- `id`, `userId` (o `user_id`), `actividad`
- `inicio_at`, `fin_at`, `duracion_ms`
- `aciertos`, `errores`, `nivel`, `resultado`
- `palabra1`, `palabra2`, `palabra3`

### SesionVocabulario
- `id`, `sesionId` (o `sesion_id`), `vocabularioId`
- `mostrada`, `acierto`, `tiempo_ms`

**Nota:** Los nombres de columnas son ligeramente diferentes entre SQLite (snake_case) y el API (camelCase), pero `DataService` maneja la conversión automáticamente.

---

## ✨ Ventajas de Esta Arquitectura

1. **Flexibilidad**: Cambia entre local y remoto con una sola línea
2. **Desarrollo**: Usa SQLite durante desarrollo sin conexión
3. **Producción**: Usa Railway para usuarios finales
4. **Testing**: Prueba ambos modos sin cambiar código
5. **Migración gradual**: Migra usuarios poco a poco

---

**Última actualización:** 2025-12-13
**Backend URL:** https://worthy-wonder-production-7e0b.up.railway.app
**Modo actual:** Local (SQLite)
