import 'dart:math';

import 'package:flutter/material.dart';

import 'database_helper_mobile.dart'
    if (dart.library.html) 'database_helper_web.dart';
import 'region_service.dart';

/// 热力图数据点
class HeatPoint {
  final double lat;
  final double lon;
  final double value;
  final Color color;

  const HeatPoint({
    required this.lat,
    required this.lon,
    required this.value,
    required this.color,
  });
}

/// 热力图服务：查询数据库 → log颜色映射
class HeatmapService {
  static final HeatmapService instance = HeatmapService._();
  HeatmapService._();

  final RegionService _regionService = RegionService();

  List<HeatPoint>? _cached;
  int? _cachedYear;
  int? _cachedMonth;
  double _cachedMin = 0;
  double _cachedMax = 0;

  List<HeatPoint>? get cached => _cached;
  double get minValue => _cachedMin;
  double get maxValue => _cachedMax;

  // 时间轴预加载缓存
  Map<int, List<HeatPoint>>? _allYears;
  int? _preloadMonth;
  bool _preloading = false;

  bool get isPreloaded => _allYears != null;

  /// 预加载全部 35 年数据（时间轴滑动前调用一次）
  Future<void> preloadAllYears({int month = 12}) async {
    if (_allYears != null && _preloadMonth == month) return;
    if (_preloading) return;
    _preloading = true;
    _allYears = {};
    for (int y = 1990; y <= 2024; y++) {
      _allYears![y] = await _loadYear(y, month);
    }
    _preloadMonth = month;
    _preloading = false;
  }

  /// 从预加载缓存中获取某年数据（毫秒级）
  List<HeatPoint>? getForYear(int year) => _allYears?[year];

  /// 加载热力图数据——国家级别聚合（每国一个气泡）
  Future<List<HeatPoint>> load({int year = 2024, int month = 12}) async {
    // 优先从预加载缓存取
    if (_allYears != null && _allYears!.containsKey(year)) {
      final pts = _allYears![year]!;
      if (pts.isNotEmpty) {
        _cachedMin = pts.map((p) => p.value).reduce(min);
        _cachedMax = pts.map((p) => p.value).reduce(max);
      }
      return pts;
    }
    return _loadYear(year, month);
  }

  Future<List<HeatPoint>> _loadYear(int year, int month) async {
    if (_cached != null && _cachedYear == year && _cachedMonth == month) {
      return _cached!;
    }

    final db = DatabaseHelper.instance;
    final rows = await db.heatmapQuery(year, month);

    if (rows.isEmpty) {
      _cached = [];
      return [];
    }

    // 按国家聚合：country → {sum, count, lat, lon}
    final countryData = <String, _CountryAgg>{};
    for (final row in rows) {
      final v = (row['value_mean'] as num?)?.toDouble() ?? 0.0;
      if (v <= 0) continue;
      final id = (row['region_id'] as num?)?.toInt();
      if (id == null) continue;
      final region = _regionService.findById(id);
      if (region == null) continue;
      if (region.lat == 0 && region.lon == 0) continue;

      final c = region.country;
      if (!countryData.containsKey(c)) {
        countryData[c] = _CountryAgg();
      }
      final agg = countryData[c]!;
      agg.sum += v;
      agg.count++;
      // 用区域内最中心的点（取第一条的有效坐标作为国家定位）
      if (agg.count == 1) {
        agg.lat = region.lat;
        agg.lon = region.lon;
      }
    }

    if (countryData.isEmpty) {
      _cached = [];
      return [];
    }

    // 计算均值
    final means = <double>[];
    for (final agg in countryData.values) {
      agg.mean = agg.sum / agg.count;
      means.add(agg.mean);
    }

    // log 缩放
    final logValues = means.map((v) => log(v)).toList();
    logValues.sort();
    final logMin = logValues.first;
    final logMax = logValues.last;
    final logRange = logMax - logMin;

    _cachedMin = means.reduce(min);
    _cachedMax = means.reduce(max);

    final points = <HeatPoint>[];
    for (final agg in countryData.values) {
      final t = logRange > 0 ? ((log(agg.mean) - logMin) / logRange).clamp(0.0, 1.0) : 0.5;
      points.add(HeatPoint(
        lat: agg.lat,
        lon: agg.lon,
        value: agg.mean,
        color: _valueToColor(t),
      ));
    }

    _cached = points;
    _cachedYear = year;
    _cachedMonth = month;
    return points;
  }

  /// 颜色映射：蓝(低) → 青 → 绿 → 黄 → 红(高)
  static Color _valueToColor(double t) {
    if (t < 0.25) {
      final s = t / 0.25;
      return Color.fromARGB(160, (s * 255).round(), (128 + s * 127).round(), 255);
    } else if (t < 0.5) {
      final s = (t - 0.25) / 0.25;
      return Color.fromARGB(160, (255 * (1 - s)).round(), 255, (255 * (1 - s)).round());
    } else if (t < 0.75) {
      final s = (t - 0.5) / 0.25;
      return Color.fromARGB(160, (255 * s).round(), 255, 0);
    } else {
      final s = (t - 0.75) / 0.25;
      return Color.fromARGB(160, 255, (255 * (1 - s)).round(), 0);
    }
  }
}

class _CountryAgg {
  double sum = 0;
  int count = 0;
  double lat = 0;
  double lon = 0;
  double mean = 0;
}
