# leoconlula

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# leoconlula

## Despliegue en Railway

Se añadió un `Dockerfile` que construye la app en modo web y la sirve con Nginx. Pasos recomendados:

1. Asegúrate de que puedes construir localmente con Flutter 3.27 o superior: `flutter build web --release`.
2. Publica este repo en GitHub (o conéctalo a Railway de forma privada).
3. En Railway: New Project → New Service → Deploy from Repo y selecciona el repo.
4. Railway detectará el `Dockerfile` y construirá la imagen. No hace falta configurar un comando de arranque adicional; Nginx expone el puerto 80.
5. Cuando el deploy termine, abre la URL pública que ofrece Railway.

Si usas otra versión de Flutter, ajusta la imagen base en `Dockerfile` (`FROM ghcr.io/cirruslabs/flutter:<versión>`).
