import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Single infiltration record — same shape as database_helper_mobile.dart.
class InfiltrationRecord {
  final double? mean;
  final double? median;
  final double? ci95Low;
  final double? ci95High;
  final double? ci75Low;
  final double? ci75High;

  const InfiltrationRecord({
    this.mean,
    this.median,
    this.ci95Low,
    this.ci95High,
    this.ci75Low,
    this.ci75High,
  });

  double? get displayValue => mean ?? median;
  bool get hasData => displayValue != null;

  factory InfiltrationRecord.fromJson(Map<String, dynamic> json) {
    return InfiltrationRecord(
      mean: (json['mean'] as num?)?.toDouble(),
      median: (json['median'] as num?)?.toDouble(),
      ci95Low: (json['ci95_low'] as num?)?.toDouble(),
      ci95High: (json['ci95_high'] as num?)?.toDouble(),
      ci75Low: (json['ci75_low'] as num?)?.toDouble(),
      ci75High: (json['ci75_high'] as num?)?.toDouble(),
    );
  }
}

/// LRU cache entry for point queries.
class _CacheEntry {
  final InfiltrationRecord record;
  final DateTime timestamp;
  _CacheEntry(this.record) : timestamp = DateTime.now();
}

/// HTTP-based DatabaseHelper for Web platform.
///
/// Calls the infiltration REST API instead of local SQLite.
/// Includes a simple LRU cache for repeated queries.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;
  DatabaseHelper._();

  static const String _defaultApiBase = 'http://localhost:8080';
  static const int _cacheLimit = 200;

  String? _apiBase;
  final Map<String, _CacheEntry> _cache = {};
  bool _initialized = false;

  /// Resolve API base URL: env var → fallback.
  String get _baseUrl {
    if (_apiBase != null) return _apiBase!;
    const envUrl = String.fromEnvironment('API_BASE_URL');
    _apiBase = envUrl.isNotEmpty ? envUrl : _defaultApiBase;
    return _apiBase!;
  }

  /// Override the API base URL (for testing).
  set apiBaseUrl(String url) => _apiBase = url;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  void close() {
    _cache.clear();
    _initialized = false;
  }

  /// Point query: fetch single infiltration record from API.
  Future<InfiltrationRecord?> query(int regionId, int year, int month) async {
    final cacheKey = 'q:$regionId:$year:$month';
    final cached = _cache[cacheKey];
    if (cached != null) return cached.record;

    try {
      final uri = Uri.parse('$_baseUrl/api/query').replace(
        queryParameters: {
          'region_id': regionId.toString(),
          'year': year.toString(),
          'month': month.toString(),
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final record = InfiltrationRecord.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        _addToCache(cacheKey, record);
        return record;
      }
      return null;
    } catch (e) {
      debugPrint('DB Web query error: $e');
      return null;
    }
  }

  /// Heatmap: fetch all region means for a year/month.
  Future<List<Map<String, Object?>>> heatmapQuery(int year, int month) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/heatmap').replace(
        queryParameters: {'year': year.toString(), 'month': month.toString()},
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        return list.map((e) => e as Map<String, Object?>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('DB Web heatmap error: $e');
      return [];
    }
  }

  /// Raw query (used by InsightService).
  /// Supports a subset of SQL patterns by routing to specific API endpoints.
  /// Falls back to empty list for unrecognized queries.
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? args]) async {
    // Route known query patterns to API endpoints
    try {
      // Global rank: SELECT COUNT(*) + 1 ... WHERE value_mean > ?
      if (sql.contains('value_mean > ?') && sql.contains('COUNT(*) + 1')) {
        return _rawRankQuery(args!);
      }
      // Total count: SELECT COUNT(*) AS c ... WHERE value_mean IS NOT NULL
      if (sql.contains('COUNT(*) AS c') && sql.contains('value_mean IS NOT NULL')) {
        return _rawCountQuery(args!);
      }
      // Trend: SELECT year, value_mean ... ORDER BY year
      if (sql.contains('ORDER BY year') && sql.contains('value_mean')) {
        return _rawTrendQuery(args!);
      }
      // Monthly pattern: SELECT month, value_mean ... ORDER BY month
      if (sql.contains('ORDER BY month') && sql.contains('value_mean')) {
        return _rawMonthlyQuery(args!);
      }
    } catch (e) {
      debugPrint('DB Web rawQuery error: $e');
    }
    return [];
  }

  // --- Insight API helpers ---

  Future<List<Map<String, Object?>>> _rawRankQuery(List<Object?> args) async {
    // args: [year, month, value]
    final year = args[0] as int;
    final month = args[1] as int;
    final value = (args[2] as num).toDouble();
    final uri = Uri.parse('$_baseUrl/api/insight/rank').replace(
      queryParameters: {'year': year.toString(), 'month': month.toString(), 'value': value.toString()},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return [{'r': data['rank'], 'c': null}];
    }
    return [];
  }

  Future<List<Map<String, Object?>>> _rawCountQuery(List<Object?> args) async {
    // args: [year, month]
    final year = args[0] as int;
    final month = args[1] as int;
    final uri = Uri.parse('$_baseUrl/api/insight/rank').replace(
      queryParameters: {'year': year.toString(), 'month': month.toString(), 'value': '0'},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return [{'c': data['total'], 'r': null}];
    }
    return [];
  }

  Future<List<Map<String, Object?>>> _rawTrendQuery(List<Object?> args) async {
    // args: [regionId, month]
    final regionId = args[0] as int;
    final month = args[1] as int;
    final uri = Uri.parse('$_baseUrl/api/insight/trend').replace(
      queryParameters: {'region_id': regionId.toString(), 'month': month.toString()},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final years = data['years'] as List<dynamic>;
      return years.map((y) => {
            'year': y['year'],
            'value_mean': (y['value'] as num).toDouble(),
          } as Map<String, Object?>).toList();
    }
    return [];
  }

  Future<List<Map<String, Object?>>> _rawMonthlyQuery(List<Object?> args) async {
    // args: [regionId, year]
    final regionId = args[0] as int;
    final year = args[1] as int;
    final uri = Uri.parse('$_baseUrl/api/insight/monthly').replace(
      queryParameters: {'region_id': regionId.toString(), 'year': year.toString()},
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final months = data['months'] as List<dynamic>;
      return months.map((m) => {
            'month': m['month'],
            'value_mean': (m['value'] as num).toDouble(),
          } as Map<String, Object?>).toList();
    }
    return [];
  }

  // --- Cache ---

  void _addToCache(String key, InfiltrationRecord record) {
    if (_cache.length >= _cacheLimit) {
      // Evict oldest entry
      String? oldest;
      DateTime? oldestTime;
      for (final e in _cache.entries) {
        if (oldestTime == null || e.value.timestamp.isBefore(oldestTime)) {
          oldestTime = e.value.timestamp;
          oldest = e.key;
        }
      }
      if (oldest != null) _cache.remove(oldest);
    }
    _cache[key] = _CacheEntry(record);
  }
}
