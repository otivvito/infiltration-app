import 'dart:convert';

import 'package:flutter/services.dart';

/// 地区数据结构
class Region {
  final int id;
  final String country;
  final String name;
  final double lat;
  final double lon;

  const Region({
    required this.id,
    required this.country,
    required this.name,
    required this.lat,
    required this.lon,
  });

  String get displayName => name == country ? name : '$name, $country';
}

/// 加载 regions.json 和 region_coords.json，提供搜索功能
class RegionService {
  static final RegionService _instance = RegionService._();
  factory RegionService() => _instance;
  RegionService._();

  List<Region> _regions = [];
  List<String> _countries = [];
  Map<String, List<Region>> _byCountry = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<String> get countries => _countries;

  Future<void> init() async {
    if (_loaded) return;

    // 并行加载两个 JSON
    final results = await Future.wait([
      rootBundle.loadString('assets/regions.json'),
      rootBundle.loadString('assets/region_coords.json'),
    ]);

    final regionList = json.decode(results[0]) as Map<String, dynamic>;
    final coords = json.decode(results[1]) as Map<String, dynamic>;

    final byCountry = <String, List<Region>>{};
    final allRegions = <Region>[];

    for (final c in regionList['countries'] as List) {
      final country = c['country'] as String;
      final regions = <Region>[];

      for (final r in c['regions'] as List) {
        final id = r['id'] as int;
        final name = r['name'] as String;
        final coord = coords[id.toString()] as Map<String, dynamic>?;

        final region = Region(
          id: id,
          country: country,
          name: name,
          lat: (coord?['lat'] as num?)?.toDouble() ?? 0.0,
          lon: (coord?['lon'] as num?)?.toDouble() ?? 0.0,
        );
        regions.add(region);
        allRegions.add(region);
      }

      regions.sort((a, b) => a.name.compareTo(b.name));
      byCountry[country] = regions;
    }

    _regions = allRegions;
    _countries = (byCountry.keys.toList()..sort());
    _byCountry = byCountry;
    _loaded = true;
  }

  List<Region> regionsForCountry(String country) {
    return _byCountry[country] ?? [];
  }

  /// 搜索地区（按名称模糊匹配）
  List<Region> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _regions
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.country.toLowerCase().contains(q))
        .take(30)
        .toList();
  }

  Region? findById(int id) {
    try {
      return _regions.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
