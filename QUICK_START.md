# ⚡ Quick Start - LeoConLula

## 🎯 Cambiar entre Local y Cloud

### 📝 Editar [lib/services/data_service.dart](lib/services/data_service.dart)

```dart
static const bool useRemoteApi = false;  // Local (SQLite)
static const bool useRemoteApi = true;   // Cloud (Railway)
```

---

## 🚀 Backend en Railway

✅ **Estado:** Online
🌐 **URL:** https://worthy-wonder-production-7e0b.up.railway.app
✅ **Health:** https://worthy-wonder-production-7e0b.up.railway.app/health

---

## 📦 Archivos Creados

### Services
- ✅ [lib/services/api_service.dart](lib/services/api_service.dart) - Cliente HTTP para Railway
- ✅ [lib/services/data_service.dart](lib/services/data_service.dart) - Servicio unificado (cambiar aquí)

### Backend
- ✅ [backend/src/index.ts](backend/src/index.ts) - API Express + Prisma
- ✅ [backend/nixpacks.toml](backend/nixpacks.toml) - Config de Railway
- ✅ [backend/prisma/schema.prisma](backend/prisma/schema.prisma) - Esquema PostgreSQL

### Documentación
- ✅ [BACKEND_SETUP.md](BACKEND_SETUP.md) - Guía completa
- ✅ [backend/README.md](backend/README.md) - Documentación del backend
- ✅ Este archivo (QUICK_START.md)

---

## 🧪 Probar Modo Cloud

1. Editar [lib/services/data_service.dart](lib/services/data_service.dart):
   ```dart
   static const bool useRemoteApi = true;
   ```

2. Ejecutar la app:
   ```bash
   flutter run
   ```

3. Crear un usuario desde la app

4. Verificar en Railway que se guardó:
   ```bash
   curl https://worthy-wonder-production-7e0b.up.railway.app/usuarios
   ```

---

## 🔄 Volver a Modo Local

Editar [lib/services/data_service.dart](lib/services/data_service.dart):
```dart
static const bool useRemoteApi = false;
```

---

## 📊 Diferencias Clave

| Característica | Local (SQLite) | Cloud (Railway) |
|---------------|----------------|-----------------|
| Internet | ❌ No necesario | ✅ Requerido |
| Velocidad | ⚡ Instantáneo | 🌐 Latencia de red |
| Sincronización | ❌ No | ✅ Sí |
| Backup | ❌ Manual | ✅ Automático |
| Ubicación | 📱 Dispositivo | ☁️ PostgreSQL |

---

## 🛠️ Comandos Útiles

### Flutter
```bash
flutter run                    # Ejecutar app
flutter clean                  # Limpiar build
flutter pub get                # Instalar dependencias
```

### Backend (local)
```bash
cd backend
npm install                    # Instalar dependencias
npm run dev                    # Desarrollo
npm run build                  # Compilar
npm start                      # Producción
```

### Railway (remoto)
```bash
# Ver logs
# Ve a railway.app → worthy-wonder → Deployments → View Logs

# Health check
curl https://worthy-wonder-production-7e0b.up.railway.app/health
```

---

## ✨ Todo Listo!

Tu app ahora puede funcionar en **2 modos**:

1. **Local** (por defecto) - SQLite en el dispositivo
2. **Cloud** - PostgreSQL en Railway

Cambia entre ellos editando **una sola línea** en [lib/services/data_service.dart](lib/services/data_service.dart) 🎉
