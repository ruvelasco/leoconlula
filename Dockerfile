FROM ghcr.io/cirruslabs/flutter:3.27.0 AS build

WORKDIR /app

# Instala dependencias primero para aprovechar el cache de la imagen.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copia el resto del proyecto.
COPY . .

# Habilita soporte web (si ya está habilitado no hace nada) y genera la carpeta web faltante.
RUN flutter config --enable-web \
  && flutter create . --platforms web \
  && flutter build web --release

FROM nginx:alpine

WORKDIR /usr/share/nginx/html
COPY --from=build /app/build/web ./

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
