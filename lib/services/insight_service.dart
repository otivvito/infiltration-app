import 'database_helper_mobile.dart';

/// 一条数据洞察
class InsightLine {
  final String icon;
  final String text;
  const InsightLine({required this.icon, required this.text});
}

/// 本地数据分析生成自然语言洞察（无需外部 AI）
class InsightService {
  static final InsightService instance = InsightService._();
  InsightService._();

  /// 生成一个地区的全套洞察
  Future<List<InsightLine>> generate(int regionId, int year, int month, double currentMean) async {
    final db = DatabaseHelper.instance;
    final insights = <InsightLine>[];

    // 1. 全球排名
    final globalRank = await _computeGlobalRank(db, year, month, currentMean);
    if (globalRank != null) {
      final pct = (globalRank['rank']! / globalRank['total']! * 100).toStringAsFixed(0);
      insights.add(InsightLine(
        icon: '🏆',
        text: '全球排名：在 ${globalRank['total']} 个地区中排名约第 ${globalRank['rank']} 名'
            '（前 $pct%），渗透系数${currentMean.toStringAsFixed(4)}',
      ));
    }

    // 2. 时间趋势
    final trend = await _computeTrend(db, regionId, month);
    if (trend != null) {
      final dir = trend['slope']! > 0 ? '上升' : '下降';
      final pctChange = ((trend['last']! - trend['first']!) / trend['first']! * 100).abs();
      insights.add(InsightLine(
        icon: '📈',
        text: '时间趋势：1990-2024 年呈${dir}趋势，'
            '从 ${trend['first']!.toStringAsFixed(4)} 变为 ${trend['last']!.toStringAsFixed(4)}'
            '（${dir} ${pctChange.toStringAsFixed(0)}%）',
      ));
    }

    // 3. 月度特征
    final monthly = await _computeMonthlyPattern(db, regionId, year);
    if (monthly != null) {
      insights.add(InsightLine(
        icon: '📅',
        text: '月度特征：${monthly['highMonth']}月最高（均值 ${monthly['highVal']!.toStringAsFixed(4)}），'
            '${monthly['lowMonth']}月最低（均值 ${monthly['lowVal']!.toStringAsFixed(4)}）',
      ));
    }

    return insights;
  }

  Future<Map<String, int>?> _computeGlobalRank(DatabaseHelper db, int year, int month, double value) async {
    try {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) + 1 AS r FROM infiltration_data WHERE year=? AND month=? AND value_mean > ?',
        [year, month, value],
      );
      final total = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM infiltration_data WHERE year=? AND month=? AND value_mean IS NOT NULL',
        [year, month],
      );
      if (rows.isEmpty || total.isEmpty) return null;
      return {
        'rank': (rows.first['r'] as num).toInt(),
        'total': (total.first['c'] as num).toInt(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, double>?> _computeTrend(DatabaseHelper db, int regionId, int month) async {
    try {
      final rows = await db.rawQuery(
        'SELECT year, value_mean FROM infiltration_data WHERE region_id=? AND month=? AND value_mean IS NOT NULL ORDER BY year',
        [regionId, month],
      );
      if (rows.length < 2) return null;
      final values = rows.map((r) => (r['value_mean'] as num).toDouble()).toList();
      // 简单线性回归斜率
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
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _computeMonthlyPattern(DatabaseHelper db, int regionId, int year) async {
    try {
      final rows = await db.rawQuery(
        'SELECT month, value_mean FROM infiltration_data WHERE region_id=? AND year=? AND value_mean IS NOT NULL ORDER BY month',
        [regionId, year],
      );
      if (rows.isEmpty) return null;
      double maxV = -1, minV = double.infinity;
      int maxM = 0, minM = 0;
      for (final r in rows) {
        final v = (r['value_mean'] as num).toDouble();
        final m = (r['month'] as num).toInt();
        if (v > maxV) { maxV = v; maxM = m; }
        if (v < minV) { minV = v; minM = m; }
      }
      return {'highMonth': maxM, 'highVal': maxV, 'lowMonth': minM, 'lowVal': minV};
    } catch (_) {
      return null;
    }
  }
}
