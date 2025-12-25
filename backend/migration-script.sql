-- Script de Migración: Renombrar Usuario → Estudiante
-- IMPORTANTE: Este script debe ejecutarse ANTES de aplicar la migración de Prisma

-- 1. Renombrar tabla Usuario a Estudiante
ALTER TABLE "Usuario" RENAME TO "Estudiante";

-- 2. Renombrar columnas de foreign keys en Vocabulario
ALTER TABLE "Vocabulario" RENAME COLUMN "usuarioId" TO "estudianteId";

-- 3. Renombrar columna en ActividadSesion
ALTER TABLE "ActividadSesion" RENAME COLUMN "userId" TO "estudianteId";

-- 4. Renombrar la relación/constraint en Vocabulario (si existe)
-- Prisma lo manejará automáticamente al crear el migration

-- 5. Renombrar la relación/constraint en ActividadSesion (si existe)
-- Prisma lo manejará automáticamente al crear el migration

-- Verificar que todo está correcto
SELECT
    'Estudiantes' as tabla,
    COUNT(*) as total
FROM "Estudiante"
UNION ALL
SELECT
    'Vocabulario' as tabla,
    COUNT(*) as total
FROM "Vocabulario"
UNION ALL
SELECT
    'Sesiones' as tabla,
    COUNT(*) as total
FROM "ActividadSesion";
