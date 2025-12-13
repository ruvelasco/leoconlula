# 🚀 Guía de Despliegue en Railway

## Paso a Paso Completo

### 1️⃣ Preparación del Repositorio

Asegúrate de que tu backend tenga estos archivos:

```
backend/
├── src/index.ts          ✅ API principal
├── prisma/schema.prisma  ✅ Esquema de BD
├── package.json          ✅ Dependencias
├── tsconfig.json         ✅ Config TypeScript
├── railway.json          ✅ Config Railway
├── .env.example          ✅ Ejemplo de variables
├── Dockerfile            ✅ (opcional)
└── README.md             ✅ Documentación
```

### 2️⃣ Crear Proyecto en Railway

1. Ve a https://railway.app
2. Click "Start a New Project"
3. Selecciona "Deploy from GitHub repo"
4. Autoriza acceso a GitHub
5. Selecciona tu repositorio `leoconlula`

### 3️⃣ Agregar Base de Datos PostgreSQL

1. En tu proyecto, click el botón **"+ New"**
2. Selecciona **"Database"**
3. Elige **"Add PostgreSQL"**
4. Railway creará automáticamente la base de datos
5. La variable `DATABASE_URL` se configura automáticamente

### 4️⃣ Configurar el Servicio Backend

1. Click **"+ New"** nuevamente
2. Selecciona **"GitHub Repo"**
3. Elige tu repo y la rama (main/master)
4. Railway detectará automáticamente que es un proyecto Node.js

#### Configurar Root Directory

Si tu backend está en una carpeta:
1. Click en tu servicio backend
2. Ve a **"Settings"**
3. En **"Root Directory"** pon: `backend`
4. Guarda los cambios

### 5️⃣ Variables de Entorno

Railway configura `DATABASE_URL` automáticamente. Agrega las demás:

1. Click en tu servicio backend
2. Ve a la pestaña **"Variables"**
3. Click **"+ New Variable"**
4. Agrega:

```
PORT = 8080
NODE_ENV = production
BASE_URL = https://tu-servicio.up.railway.app
```

**Nota:** El `BASE_URL` lo obtienes después del primer deploy. Puedes agregarlo después.

### 6️⃣ Primer Deploy

1. Railway comenzará a construir automáticamente
2. Verás los logs en tiempo real
3. El proceso:
   - Instala dependencias (`npm install`)
   - Compila TypeScript (`npm run build`)
   - Genera cliente Prisma (`npx prisma generate`)
   - Ejecuta el servidor (`npx prisma db push && node dist/index.js`)

### 7️⃣ Obtener URL del Servicio

1. Una vez desplegado, ve a tu servicio
2. Click en **"Settings"**
3. En **"Networking"**, click **"Generate Domain"**
4. Railway te dará una URL como: `https://leoconlula-backend-production.up.railway.app`

### 8️⃣ Actualizar BASE_URL

1. Copia la URL generada
2. Ve a **"Variables"**
3. Actualiza `BASE_URL` con tu URL real
4. Railway redesplegará automáticamente

### 9️⃣ Verificar Funcionamiento

Prueba tu API:

```bash
# Health check
curl https://tu-servicio.up.railway.app/health

# Obtener usuarios
curl https://tu-servicio.up.railway.app/usuarios

# Deberías recibir respuestas JSON
```

### 🔟 Configurar en Flutter

En tu app Flutter, actualiza `api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'https://tu-servicio.up.railway.app';
  // ...
}
```

---

## 🔄 Redeploy Automático

Railway redespliega automáticamente cuando:
- Haces push a tu rama de GitHub
- Cambias variables de entorno
- Actualizas configuraciones

---

## 📊 Monitoreo

### Ver Logs
1. Click en tu servicio
2. Ve a la pestaña **"Deployments"**
3. Click en el deployment activo
4. Verás los logs en tiempo real

### Métricas
Railway muestra:
- CPU usage
- Memory usage
- Network traffic
- Request metrics

---

## 🐛 Solución de Problemas

### Error: "Application failed to respond"

**Causa:** El puerto no está configurado correctamente.

**Solución:**
1. Verifica que `PORT=8080` esté en las variables
2. Asegúrate de que tu código usa `process.env.PORT`

```typescript
const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;
```

### Error: "Prisma client not generated"

**Causa:** El cliente de Prisma no se generó en el build.

**Solución:**
Verifica que `railway.json` tenga:
```json
{
  "build": {
    "buildCommand": "npm run build && npx prisma generate"
  }
}
```

### Error: "DATABASE_URL not found"

**Causa:** La base de datos no está conectada al servicio.

**Solución:**
1. Asegúrate de haber creado la base de datos PostgreSQL
2. En el servicio backend, ve a **"Settings"** → **"Connect"**
3. Conecta la base de datos PostgreSQL
4. Railway agregará automáticamente `DATABASE_URL`

### Error: "Table does not exist"

**Causa:** Las tablas no se crearon en PostgreSQL.

**Solución:**
El comando de start debe ejecutar `prisma db push`:
```json
{
  "deploy": {
    "startCommand": "npx prisma db push && node dist/index.js"
  }
}
```

### Build muy lento

**Optimización:**
1. Railway usa caché de npm automáticamente
2. Las builds incrementales son más rápidas
3. Para builds desde cero: 2-3 minutos es normal

---

## 💰 Costos

Railway ofrece:
- **$5 gratis/mes** para hobby projects
- **Pay as you go** después
- Calcula ~$5-10/mes para una app pequeña con PostgreSQL

---

## 🔐 Seguridad

### Variables Sensibles
- ✅ Usa variables de entorno para secretos
- ❌ NO hardcodees claves en el código
- ✅ Agrega `.env` a `.gitignore`

### HTTPS
- ✅ Railway proporciona HTTPS automáticamente
- ✅ Certificados SSL gratis

### CORS
El backend ya tiene CORS habilitado:
```typescript
app.use(cors());
```

---

## 📈 Escalado

Railway escala automáticamente dentro de tu plan.

Para apps grandes:
1. Ve a **"Settings"** → **"Resources"**
2. Ajusta CPU/RAM según necesites
3. Costos aumentan proporcionalmente

---

## 🔄 Rollback

Si algo sale mal:
1. Ve a **"Deployments"**
2. Encuentra el deployment anterior que funcionaba
3. Click **"Redeploy"**

---

## 📞 Soporte

- [Documentación Railway](https://docs.railway.app)
- [Discord de Railway](https://discord.gg/railway)
- [Documentación Prisma](https://www.prisma.io/docs)

---

## ✅ Checklist Final

- [ ] Proyecto creado en Railway
- [ ] PostgreSQL agregado
- [ ] Variables de entorno configuradas
- [ ] Root directory configurado (si aplica)
- [ ] Primer deploy exitoso
- [ ] URL generada
- [ ] BASE_URL actualizada
- [ ] Health check funcionando
- [ ] Endpoints probados
- [ ] Flutter configurado con nueva URL
- [ ] App funcionando end-to-end

¡Listo! Tu backend está en producción 🎉
