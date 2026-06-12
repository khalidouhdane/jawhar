# Multi-stage build: AOT-compiled jawhar-api on a minimal runtime image
# (roadmap §6: dart compile exe -> distroless-style scratch + Dart runtime libs).

FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first for layer caching.
#
# server/api is a pub WORKSPACE member (root pubspec.yaml at the repo root),
# so inside this build context (server/api only, no Flutter SDK available)
# the `resolution: workspace` line is stripped to resolve standalone — the
# package has no path dependencies, so the standalone solve is equivalent.
# The lockfile lives at the workspace root (which pins Flutter app deps and
# cannot resolve here), so the image resolves fresh; CI's post-deploy
# /health + smoke checks are the guard against surprise transitive bumps.
# hifz_core IS a dependency (not on pub.dev): the build context MUST be a
# STAGED copy of server/api with packages/hifz_core vendored in and a
# dependency_overrides path appended to pubspec.yaml — see the
# "Stage build context" step in .github/workflows/deploy-api.yml for the
# canonical recipe (local deploys must replicate it).
# The \r? keeps the strip working when the build context comes from a
# CRLF working tree (local `gcloud run deploy --source` on Windows; CI
# checkouts are LF and match either way).
COPY pubspec.yaml ./
COPY packages/ ./packages/
RUN sed -i '/^resolution: workspace\r\?$/d' pubspec.yaml && dart pub get

COPY . .
# COPY . . restores the workspace pubspec.yaml — strip it again.
RUN sed -i '/^resolution: workspace\r\?$/d' pubspec.yaml
RUN dart pub get
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
