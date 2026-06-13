import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 一条收藏记录
class FavoriteItem {
  final int regionId;
  final String regionName;
  final String country;
  final int year;
  final int month;
  final DateTime savedAt;

  const FavoriteItem({
    required this.regionId,
    required this.regionName,
    required this.country,
    required this.year,
    required this.month,
    required this.savedAt,
  });

  String get displayName => regionName == country ? regionName : '$regionName, $country';
  String get timeLabel => '$year年$month月';

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'regionName': regionName,
        'country': country,
        'year': year,
        'month': month,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        regionId: json['regionId'] as int,
        regionName: json['regionName'] as String,
        country: json['country'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

/// 收藏夹服务：本地 JSON 文件持久化
class FavoritesService {
  static final FavoritesService instance = FavoritesService._();
  FavoritesService._();

  List<FavoriteItem> _favorites = [];
  bool _loaded = false;

  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/favorites.json');
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List;
        _favorites = list.map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      _favorites = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/favorites.json');
      await file.writeAsString(jsonEncode(_favorites.map((f) => f.toJson()).toList()));
    } catch (_) {}
  }

  /// 添加收藏（去重）
  Future<bool> add(int regionId, String regionName, String country, int year, int month) async {
    await _ensureLoaded();
    // 去重
    if (_favorites.any((f) => f.regionId == regionId && f.year == year && f.month == month)) {
      return false; // 已存在
    }
    _favorites.insert(0, FavoriteItem(
      regionId: regionId,
      regionName: regionName,
      country: country,
      year: year,
      month: month,
      savedAt: DateTime.now(),
    ));
    // 最多保留 50 条
    if (_favorites.length > 50) _favorites = _favorites.sublist(0, 50);
    await _save();
    return true;
  }

  /// 删除收藏（按索引）
  Future<void> remove(int index) async {
    await _ensureLoaded();
    if (index < 0 || index >= _favorites.length) return;
    _favorites.removeAt(index);
    await _save();
  }

  /// 按地区+年月取消收藏
  Future<bool> removeByKey(int regionId, int year, int month) async {
    await _ensureLoaded();
    final idx = _favorites.indexWhere((f) => f.regionId == regionId && f.year == year && f.month == month);
    if (idx == -1) return false;
    _favorites.removeAt(idx);
    await _save();
    return true;
  }

  /// 检查是否已收藏
  Future<bool> isFavorited(int regionId, int year, int month) async {
    await _ensureLoaded();
    return _favorites.any((f) => f.regionId == regionId && f.year == year && f.month == month);
  }
}
