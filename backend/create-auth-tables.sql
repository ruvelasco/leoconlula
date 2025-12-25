-- Crear enum UserRole
CREATE TYPE "UserRole" AS ENUM ('PROFESOR', 'PADRE', 'ADMIN');

-- Crear tabla AuthUser
CREATE TABLE "AuthUser" (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    "passwordHash" TEXT NOT NULL,
    nombre TEXT NOT NULL,
    role "UserRole" NOT NULL DEFAULT 'PROFESOR',
    foto TEXT,
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "emailVerificationToken" TEXT,
    "passwordResetToken" TEXT,
    "passwordResetExpires" TIMESTAMP(3),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastLogin" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para AuthUser
CREATE INDEX "AuthUser_email_idx" ON "AuthUser"(email);
CREATE INDEX "AuthUser_role_idx" ON "AuthUser"(role);

-- Crear tabla RefreshToken
CREATE TABLE "RefreshToken" (
    id SERIAL PRIMARY KEY,
    token TEXT NOT NULL UNIQUE,
    "userId" INTEGER NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "AuthUser"(id) ON DELETE CASCADE
);

-- Crear índices para RefreshToken
CREATE INDEX "RefreshToken_token_idx" ON "RefreshToken"(token);
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- Crear tabla EstudianteAsignacion
CREATE TABLE "EstudianteAsignacion" (
    id SERIAL PRIMARY KEY,
    "authUserId" INTEGER NOT NULL,
    "estudianteId" INTEGER NOT NULL,
    role TEXT NOT NULL DEFAULT 'TUTOR',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdBy" INTEGER,
    CONSTRAINT "EstudianteAsignacion_authUserId_fkey" FOREIGN KEY ("authUserId") REFERENCES "AuthUser"(id) ON DELETE CASCADE,
    CONSTRAINT "EstudianteAsignacion_estudianteId_fkey" FOREIGN KEY ("estudianteId") REFERENCES "Estudiante"(id) ON DELETE CASCADE
);

-- Crear constraint único e índices para EstudianteAsignacion
CREATE UNIQUE INDEX "EstudianteAsignacion_authUserId_estudianteId_key" ON "EstudianteAsignacion"("authUserId", "estudianteId");
CREATE INDEX "EstudianteAsignacion_authUserId_idx" ON "EstudianteAsignacion"("authUserId");
CREATE INDEX "EstudianteAsignacion_estudianteId_idx" ON "EstudianteAsignacion"("estudianteId");

-- Agregar campos opcionales a Estudiante
ALTER TABLE "Estudiante" ADD COLUMN IF NOT EXISTS "fechaNacimiento" TIMESTAMP(3);
ALTER TABLE "Estudiante" ADD COLUMN IF NOT EXISTS "notas" TEXT;

-- Crear índices en tablas existentes (si no existen)
CREATE INDEX IF NOT EXISTS "Vocabulario_estudianteId_idx" ON "Vocabulario"("estudianteId");
CREATE INDEX IF NOT EXISTS "ActividadSesion_estudianteId_idx" ON "ActividadSesion"("estudianteId");
CREATE INDEX IF NOT EXISTS "ActividadSesion_actividad_idx" ON "ActividadSesion"(actividad);
CREATE INDEX IF NOT EXISTS "SesionVocabulario_sesionId_idx" ON "SesionVocabulario"("sesionId");
CREATE INDEX IF NOT EXISTS "Estudiante_nombre_idx" ON "Estudiante"(nombre);

-- Verificar tablas creadas
SELECT
    'AuthUser' as tabla,
    COUNT(*) as total
FROM "AuthUser"
UNION ALL
SELECT
    'RefreshToken' as tabla,
    COUNT(*) as total
FROM "RefreshToken"
UNION ALL
SELECT
    'EstudianteAsignacion' as tabla,
    COUNT(*) as total
FROM "EstudianteAsignacion";
