# Instrucciones de Migración: Sistema de Autenticación

## ⚠️ IMPORTANTE: Hacer backup de la base de datos antes de continuar

```bash
# En Railway, hacer backup de la base de datos PostgreSQL
# O exportar los datos manualmente
```

## Paso 1: Configurar Variables de Entorno

Actualizar las variables de entorno en Railway:

```bash
# Agregar nuevas variables en Railway → Variables
JWT_SECRET=<generar-una-clave-secreta-fuerte-minimo-32-caracteres>
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d
BCRYPT_ROUNDS=12
```

Para generar un JWT_SECRET seguro:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Paso 2: Actualizar .env local (opcional, para desarrollo)

Si vas a probar en local, actualiza el archivo `.env`:

```env
DATABASE_URL=<tu-url-de-railway>
JWT_SECRET=<el-mismo-secret-de-railway>
# ... resto de variables
```

## Paso 3: Ejecutar Migración SQL Manual (CRÍTICO)

**Opción A: Desde Railway Dashboard**
1. Ir a Railway → Tu Base de Datos PostgreSQL → Data
2. Ejecutar el script SQL de `migration-script.sql`

**Opción B: Desde línea de comandos**
```bash
# Conectarse a la base de datos de Railway
psql <DATABASE_URL>

# O copiar el contenido de migration-script.sql y ejecutarlo
```

El script hace lo siguiente:
- Renombra tabla `Usuario` → `Estudiante`
- Renombra columna `usuarioId` → `estudianteId` en Vocabulario
- Renombra columna `userId` → `estudianteId` en ActividadSesion

## Paso 4: Aplicar Migración de Prisma

```bash
cd backend

# Generar migración
npx prisma migrate dev --name add_authentication

# O en producción (Railway)
npx prisma migrate deploy
```

## Paso 5: Generar Prisma Client

```bash
npx prisma generate
```

## Paso 6: Crear Usuario Administrador Inicial (Opcional)

Puedes crear un usuario admin inicial de dos formas:

**Opción A: Via SQL**
```sql
-- Generar hash de contraseña en Node
-- node -e "const bcrypt = require('bcrypt'); bcrypt.hash('tuContraseña123', 12).then(console.log)"

INSERT INTO "AuthUser" (email, "passwordHash", nombre, role, "emailVerified", "isActive", "createdAt", "updatedAt")
VALUES (
  'admin@leoconlula.com',
  '<hash-generado-arriba>',
  'Administrador',
  'ADMIN',
  true,
  true,
  NOW(),
  NOW()
);
```

**Opción B: Via API (después del deploy)**
```bash
curl -X POST https://tu-app.railway.app/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@leoconlula.com",
    "password": "TuContraseñaSegura123!",
    "nombre": "Administrador",
    "role": "PROFESOR"
  }'
```

## Paso 7: Compilar y Deploy

```bash
# Compilar TypeScript
npm run build

# Push a Git (Railway auto-deploy)
git add .
git commit -m "feat: add authentication system"
git push
```

## Paso 8: Asignar Estudiantes Existentes al Usuario Admin

Después de crear el usuario admin, asignar todos los estudiantes existentes:

```sql
-- Obtener el ID del usuario admin
SELECT id FROM "AuthUser" WHERE email = 'admin@leoconlula.com';

-- Asumiendo que el ID es 1, asignar todos los estudiantes
INSERT INTO "EstudianteAsignacion" ("authUserId", "estudianteId", role, "createdAt", "createdBy")
SELECT 1, id, 'TUTOR', NOW(), 1
FROM "Estudiante";
```

## Paso 9: Verificación

```bash
# Test de health check
curl https://tu-app.railway.app/health

# Test de login
curl -X POST https://tu-app.railway.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@leoconlula.com",
    "password": "TuContraseñaSegura123!"
  }'

# Deberías recibir accessToken y refreshToken
```

## Paso 10: Probar Endpoints Protegidos

```bash
# Usar el accessToken recibido
curl https://tu-app.railway.app/api/estudiantes \
  -H "Authorization: Bearer <tu-access-token>"
```

## Rollback (en caso de problemas)

Si algo sale mal:

1. **Restaurar backup de base de datos**
2. **Revertir código:**
   ```bash
   git revert HEAD
   git push
   ```

## Notas Importantes

1. **Compatibilidad retroactiva**: Los endpoints legacy (`/usuarios`, `/vocabulario` con `userId`) seguirán funcionando pero ahora requieren autenticación
2. **Flutter app**: Necesitará actualización para usar el nuevo sistema de auth
3. **Migraciones futuras**: Todas las nuevas migraciones se harán con `npx prisma migrate dev`

## Problemas Comunes

### Error: "Environment variable not found: JWT_SECRET"
- Asegúrate de haber agregado JWT_SECRET en las variables de Railway

### Error: "Table Usuario does not exist"
- Ejecuta primero el `migration-script.sql` ANTES de la migración de Prisma

### Error: "Constraint violation"
- Verifica que no haya datos huérfanos en la base de datos
- Asegúrate de que todas las foreign keys son válidas

## Contacto

Si encuentras problemas durante la migración, revisa los logs en Railway o contacta al equipo de desarrollo.
