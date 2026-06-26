import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'database.dart';

/// Build and return the API router for infiltration queries.
Router createRouter(AppDatabase db) {
  final router = Router();

  // Health check
  router.get('/health', (Request req) {
    return Response.ok(jsonEncode({'status': 'ok'}));
  });

  // Point query: GET /api/query?region_id=X&year=Y&month=Z
  router.get('/api/query', (Request req) {
    final params = req.url.queryParameters;
    final regionId = int.tryParse(params['region_id'] ?? '');
    final year = int.tryParse(params['year'] ?? '');
    final month = int.tryParse(params['month'] ?? '');
    if (regionId == null || year == null || month == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid region_id, year, or month'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final record = db.query(regionId, year, month);
    if (record == null) {
      return Response.notFound(
        jsonEncode({'error': 'No data found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(record.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Heatmap: GET /api/heatmap?year=Y&month=Z
  router.get('/api/heatmap', (Request req) {
    final year = int.tryParse(req.url.queryParameters['year'] ?? '');
    final month = int.tryParse(req.url.queryParameters['month'] ?? '');
    if (year == null || month == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid year or month'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final rows = db.heatmap(year, month);
    return Response.ok(
      jsonEncode(rows),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Rank: GET /api/insight/rank?year=Y&month=Z&value=V
  router.get('/api/insight/rank', (Request req) {
    final year = int.tryParse(req.url.queryParameters['year'] ?? '');
    final month = int.tryParse(req.url.queryParameters['month'] ?? '');
    final value = double.tryParse(req.url.queryParameters['value'] ?? '');
    if (year == null || month == null || value == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid year, month, or value'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final result = db.rank(year, month, value);
    if (result == null) {
      return Response.notFound(
        jsonEncode({'error': 'No data found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Trend: GET /api/insight/trend?region_id=X&month=Z
  router.get('/api/insight/trend', (Request req) {
    final regionId = int.tryParse(req.url.queryParameters['region_id'] ?? '');
    final month = int.tryParse(req.url.queryParameters['month'] ?? '');
    if (regionId == null || month == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid region_id or month'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final result = db.trend(regionId, month);
    if (result == null) {
      return Response.notFound(
        jsonEncode({'error': 'Not enough data'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Monthly pattern: GET /api/insight/monthly?region_id=X&year=Y
  router.get('/api/insight/monthly', (Request req) {
    final regionId = int.tryParse(req.url.queryParameters['region_id'] ?? '');
    final year = int.tryParse(req.url.queryParameters['year'] ?? '');
    if (regionId == null || year == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid region_id or year'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final result = db.monthly(regionId, year);
    if (result == null) {
      return Response.notFound(
        jsonEncode({'error': 'No data found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Compare two regions: GET /api/compare?region_a=X&region_b=Y&year=Z&month=W
  router.get('/api/compare', (Request req) {
    final regionA = int.tryParse(req.url.queryParameters['region_a'] ?? '');
    final regionB = int.tryParse(req.url.queryParameters['region_b'] ?? '');
    final year = int.tryParse(req.url.queryParameters['year'] ?? '');
    final month = int.tryParse(req.url.queryParameters['month'] ?? '');
    if (regionA == null || regionB == null || year == null || month == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing or invalid region_a, region_b, year, or month'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final result = db.compare(regionA, regionB, year, month);
    if (result == null) {
      return Response.notFound(
        jsonEncode({'error': 'No data found for either region'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
