import 'package:sqlite3/sqlite3.dart';

/// Represents a single infiltration data record returned by the API.
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

  Map<String, dynamic> toJson() => {
        'mean': mean,
        'median': median,
        'ci95_low': ci95Low,
        'ci95_high': ci95High,
        'ci75_low': ci75Low,
        'ci75_high': ci75High,
      };
}

/// SQLite-backed data access layer for infiltration database.
class AppDatabase {
  final Database _db;

  AppDatabase(String dbPath) : _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);

  /// Point query: single region × year × month.
  InfiltrationRecord? query(int regionId, int year, int month) {
    final stmt = _db.prepare(
      '''SELECT value_mean, value_median, value_ci95_low, value_ci95_high,
                 value_ci75_low, value_ci75_high
         FROM infiltration_data
         WHERE region_id = ? AND year = ? AND month = ?''',
    );
    final rows = stmt.select([regionId, year, month]).toList();
    stmt.dispose();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return InfiltrationRecord(
      mean: r['value_mean'] as double?,
      median: r['value_median'] as double?,
      ci95Low: r['value_ci95_low'] as double?,
      ci95High: r['value_ci95_high'] as double?,
      ci75Low: r['value_ci75_low'] as double?,
      ci75High: r['value_ci75_high'] as double?,
    );
  }

  /// Heatmap query: all regions' mean for a given year/month.
  List<Map<String, dynamic>> heatmap(int year, int month) {
    final stmt = _db.prepare(
      '''SELECT region_id, value_mean
         FROM infiltration_data
         WHERE year = ? AND month = ? AND value_mean IS NOT NULL''',
    );
    final rows = stmt.select([year, month]).map((r) => {
          'region_id': r['region_id'],
          'value_mean': r['value_mean'],
        }).toList();
    stmt.dispose();
    return rows;
  }

  /// Global rank: how many regions have a higher mean at this year/month.
  Map<String, int>? rank(int year, int month, double value) {
    final stmt1 = _db.prepare(
      'SELECT COUNT(*) + 1 AS r FROM infiltration_data WHERE year=? AND month=? AND value_mean > ?',
    );
    final rows1 = stmt1.select([year, month, value]).toList();
    stmt1.dispose();

    final stmt2 = _db.prepare(
      'SELECT COUNT(*) AS c FROM infiltration_data WHERE year=? AND month=? AND value_mean IS NOT NULL',
    );
    final rows2 = stmt2.select([year, month]).toList();
    stmt2.dispose();

    if (rows1.isEmpty || rows2.isEmpty) return null;
    return {
      'rank': (rows1.first['r'] as int),
      'total': (rows2.first['c'] as int),
    };
  }

  /// Time trend: all years' means for a region in a given month.
  Map<String, dynamic>? trend(int regionId, int month) {
    final stmt = _db.prepare(
      'SELECT year, value_mean FROM infiltration_data WHERE region_id=? AND month=? AND value_mean IS NOT NULL ORDER BY year',
    );
    final rows = stmt.select([regionId, month]).toList();
    stmt.dispose();
    if (rows.length < 2) return null;

    final values = rows.map((r) => (r['value_mean'] as double)).toList();
    final years = rows.map((r) => (r['year'] as int)).toList();
    final n = values.length;
    double sx = 0, sy = 0, sxy = 0, sx2 = 0;
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sx += x;
      sy += y;
      sxy += x * y;
      sx2 += x * x;
    }
    final slope = (n * sxy - sx * sy) / (n * sx2 - sx * sx);

    return {
      'slope': slope,
      'first': values.first,
      'last': values.last,
      'years': List.generate(
        n,
        (i) => {'year': years[i], 'value': values[i]},
      ),
    };
  }

  /// Monthly pattern for a region in a specific year.
  Map<String, dynamic>? monthly(int regionId, int year) {
    final stmt = _db.prepare(
      'SELECT month, value_mean FROM infiltration_data WHERE region_id=? AND year=? AND value_mean IS NOT NULL ORDER BY month',
    );
    final rows = stmt.select([regionId, year]).toList();
    stmt.dispose();
    if (rows.isEmpty) return null;

    double maxV = -1, minV = double.infinity;
    int maxM = 0, minM = 0;
    final months = <Map<String, dynamic>>[];
    for (final r in rows) {
      final v = (r['value_mean'] as double);
      final m = (r['month'] as int);
      months.add({'month': m, 'value': v});
      if (v > maxV) {
        maxV = v;
        maxM = m;
      }
      if (v < minV) {
        minV = v;
        minM = m;
      }
    }
    return {
      'high_month': maxM,
      'high_val': maxV,
      'low_month': minM,
      'low_val': minV,
      'months': months,
    };
  }

  /// Compare two regions side by side.
  Map<String, dynamic>? compare(int regionA, int regionB, int year, int month) {
    final a = query(regionA, year, month);
    final b = query(regionB, year, month);
    if (a == null && b == null) return null;
    return {
      'a': a?.toJson(),
      'b': b?.toJson(),
    };
  }

  void close() => _db.dispose();
}
