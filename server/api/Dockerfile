# Multi-stage build: AOT-compiled jawhar-api on a minimal runtime image
# (roadmap §6: dart compile exe -> distroless-style scratch + Dart runtime libs).

FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first for layer caching.
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Minimal base: scratch + the runtime libs the dart image stages under /runtime/.
FROM scratch

# Deployed git SHA surfaced by /healthz (pass --build-arg GIT_SHA=$(git rev-parse HEAD)).
ARG GIT_SHA=unknown
ENV GIT_SHA=${GIT_SHA}

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Cloud Run injects PORT (defaults to 8080 in Config).
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
