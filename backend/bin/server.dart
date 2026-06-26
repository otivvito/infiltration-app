import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:infiltration_api/database.dart';
import 'package:infiltration_api/routes.dart';

void main(List<String> args) async {
  // Database path: look for INFILTRATION_DB_PATH env var, fallback to project assets
  final dbPath = Platform.environment['INFILTRATION_DB_PATH'] ??
      // When running from backend/ dir, the db is at ../assets/infiltration.db
      'assets/infiltration.db';

  final dbFile = File(dbPath);
  if (!await dbFile.exists()) {
    stderr.writeln('ERROR: Database file not found at $dbPath');
    stderr.writeln('Set INFILTRATION_DB_PATH environment variable to the correct path.');
    exit(1);
  }

  stderr.writeln('Opening database: $dbPath');
  final db = AppDatabase(dbPath);
  stderr.writeln('Database opened successfully.');

  final router = createRouter(db);

  // Wrap with CORS middleware (allow all origins for dev; restrict in production)
  final handler = corsHeaders()(router.call);

  // Use PORT env var (Render.com standard) or default to 8080
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  stderr.writeln('Server listening on http://${server.address.host}:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    stderr.writeln('Shutting down...');
    await server.close();
    db.close();
    exit(0);
  });
}
