# LeoConLula Backend API 🚀

API REST completa con Node.js, Express, TypeScript, Prisma y PostgreSQL.

## 📝 Endpoints Disponibles

### Health Check
- `GET /health` → Estado del servidor

### 👤 Usuarios
- `POST /usuarios` → Crear usuario
- `GET /usuarios` → Obtener todos los usuarios
- `DELETE /usuarios/:id` → Eliminar usuario
- `PATCH /usuarios/:id/campos` → Actualizar campos
- `GET /usuarios/:id/orden-actividades` → Obtener orden de actividades
- `PATCH /usuarios/:id/orden-actividades` → Actualizar orden de actividades
- `GET /usuarios/:id/actividades-habilitadas` → Obtener actividades habilitadas
- `PATCH /usuarios/:id/actividades-habilitadas` → Actualizar actividades habilitadas

### 📚 Vocabulario
- `POST /vocabulario` → Crear palabra
- `GET /vocabulario?userId=X` → Obtener vocabulario (filtrado por usuario)
- `DELETE /vocabulario/:id` → Eliminar palabra

### 📊 Sesiones
- `POST /sesiones` → Crear sesión
- `GET /sesiones?userId=X&actividad=Y` → Obtener sesiones (con filtros opcionales)
- `PATCH /sesiones/:id/finalizar` → Finalizar sesión
- `POST /sesiones/:id/detalle` → Agregar detalle de vocabulario
- `DELETE /sesiones/:id` → Eliminar sesión
- `DELETE /sesiones?userId=X` → Eliminar sesiones de un usuario

### 📁 Archivos
- `POST /upload?type=avatar` → Subir imagen (avatar o vocabulario)
- `GET /uploads/avatars/:filename` → Obtener avatar
- `GET /uploads/vocabulario/:filename` → Obtener imagen de vocabulario

---

## 🛠️ Desarrollo Local

### Instalación
```bash
cd backend
npm install
```

### Configuración
```bash
cp .env.example .env
# Edita .env con tu DATABASE_URL de PostgreSQL
```

### Ejecutar
```bash
# Generar cliente Prisma
npx prisma generate

# Sincronizar esquema con BD
npm run db:push

# Desarrollo (hot-reload)
npm run dev

# Producción
npm run build
npm start
```

Servidor disponible en `http://localhost:8080`

---

## 🚢 Deploy en Railway

### 1. Crear Proyecto
1. Ve a [railway.app](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Conecta tu repositorio

### 2. Agregar PostgreSQL
1. Click "+ New" → "Database" → "PostgreSQL"
2. Railway configura automáticamente `DATABASE_URL`

### 3. Variables de Entorno
Agrega en tu servicio backend:
```
PORT=8080
NODE_ENV=production
BASE_URL=https://tu-proyecto.up.railway.app
```

### 4. Deploy Automático
Railway detectará `railway.json` y desplegará automáticamente.

El comando de start ejecuta:
```bash
npx prisma db push && node dist/index.js
```

---

## 📦 Estructura

```
backend/
├── prisma/
│   └── schema.prisma       # Esquema de BD
├── src/
│   └── index.ts            # API principal
├── uploads/                # Archivos subidos
│   ├── avatars/
│   └── vocabulario/
├── .env.example
├── railway.json            # Config de Railway
├── package.json
└── README.md
```

---

## 📊 Esquema de Base de Datos

### Usuario
- `id`, `nombre`, `foto`, `fuente`, `tipo`, `voz`
- `leer_palabras`, `refuerzo_acierto`, `refuerzo_error`
- `ayudas_visuales`, `modo_infantil`, `numero_repeticiones`
- `orden_actividades`, `actividades_habilitadas`

### Vocabulario
- `id`, `nombreImagen`, `label`, `silabas`, `usuarioId`

### ActividadSesion
- `id`, `userId`, `actividad`, `inicio_at`, `fin_at`
- `duracion_ms`, `aciertos`, `errores`, `nivel`, `resultado`
- `palabra1`, `palabra2`, `palabra3`

### SesionVocabulario
- `id`, `sesionId`, `vocabularioId`
- `mostrada`, `acierto`, `tiempo_ms`

---

## 🔒 Seguridad
- Helmet para headers seguros
- CORS habilitado
- Validación de tipos de archivo (solo imágenes)
- Límites de tamaño (5MB imágenes, 10MB JSON)

---

## 🔄 Migración desde SQLite
1. El esquema Prisma replica exactamente la estructura SQLite
2. Sustituir llamadas a `DBHelper` por peticiones HTTP
3. Los endpoints mantienen la misma lógica y estructura de datos

---

## 📞 Comandos Útiles
```bash
npm run dev          # Desarrollo
npm run build        # Compilar TypeScript
npm start            # Producción
npm run db:push      # Sincronizar esquema
npm run db:studio    # GUI de Prisma
```
