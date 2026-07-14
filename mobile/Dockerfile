# syntax=docker/dockerfile:1.7
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app
ARG FLUTTER_VERSION=3.44.4
ARG SIGO_API_BASE_URL=/api
ENV PUB_CACHE=/opt/pub-cache

# Cirrus publica 3.44.0 como base de la rama estable. El proyecto requiere
# Dart 3.12.2, incluido en Flutter 3.44.4, por lo que se fija el tag oficial
# de Flutter antes de resolver dependencias.
RUN git -C "${FLUTTER_ROOT}" fetch --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}" \
    && git -C "${FLUTTER_ROOT}" checkout --detach "${FLUTTER_VERSION}" \
    && flutter precache --web

COPY pubspec.yaml pubspec.lock ./
RUN --mount=type=cache,target=/opt/pub-cache flutter pub get

COPY analysis_options.yaml ./
COPY assets ./assets
COPY lib ./lib
COPY web ./web

RUN --mount=type=cache,target=/opt/pub-cache flutter build web \
    --release \
    --dart-define=SIGO_API_BASE_URL=${SIGO_API_BASE_URL}

FROM nginx:1.29.8-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY proxy_params /etc/nginx/proxy_params
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
