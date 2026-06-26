# Dart backend for infiltration API (Render.com deployment)
FROM dart:3.11.5-sdk AS build

WORKDIR /app
COPY backend/pubspec.yaml backend/pubspec.lock ./
RUN dart pub get

COPY backend/ .
COPY assets/infiltration.db /data/infiltration.db

# Compile to native executable for faster cold starts
RUN dart compile exe bin/server.dart -o /app/server

FROM dart:3.11.5-sdk
WORKDIR /app
COPY --from=build /app/server /app/server
COPY --from=build /data/infiltration.db /data/infiltration.db

ENV INFILTRATION_DB_PATH=/data/infiltration.db
ENV PORT=8080

EXPOSE 8080
CMD ["/app/server"]
