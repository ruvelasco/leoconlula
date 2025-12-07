# Backend API para leoconlula

API REST mínima (Node/Express + Prisma + Postgres) para reemplazar el SQLite local en web.

## Endpoints
- `GET /health` → estado.
- Usuarios: `POST /usuarios`, `GET /usuarios`, `DELETE /usuarios/:id`, `PATCH /usuarios/:id/campos`.
- Vocabulario: `POST /vocabulario`, `GET /vocabulario?userId=...`, `DELETE /vocabulario/:id`.
- Sesiones: `POST /sesiones`, `PATCH /sesiones/:id/finalizar`, `POST /sesiones/:id/detalle`, `DELETE /sesiones/:id`, `DELETE /sesiones?userId=...`.

Campos esperados siguen el modelo original (booleans como true/false). `inicio_at` y `fin_at` en milisegundos epoch.

## Desarrollo local
1. `cp .env.example .env` y rellena `DATABASE_URL` apuntando a Postgres.
2. `npm install`
3. `npx prisma migrate deploy` (o `prisma db push` en desarrollo).
4. `npm run dev` (puerto 8080 por defecto).

## Deploy en Railway
- Crea un servicio Postgres en Railway y copia la `DATABASE_URL` en las variables de entorno del servicio backend.
- Crea un servicio nuevo desde `/backend` con el `Dockerfile` incluido. Railway usa el puerto 8080.
- Ejecuta `npx prisma migrate deploy` como comando de “Start Command” previo o en un deploy hook (en Railway se puede poner en “Deploy command”).

## Ajustes para Flutter
- Sustituir llamadas de `DBHelper` por peticiones HTTP a estos endpoints.
- Opcional: mantener caché local con SQLite/IndexedDB para offline y sincronizar con la API.
