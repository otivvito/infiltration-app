import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'region_service.dart';

/// GPS 定位 + 最近地区匹配服务
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  final RegionService _regionService = RegionService();

  /// 定位结果
  /// - [position]: GPS 坐标
  /// - [error]: 用户可读的错误信息（用于 SnackBar）
  Position? get currentPosition => _lastPosition;
  Position? _lastPosition;

  /// 获取当前 GPS 位置
  /// 返回 null 表示定位失败，同时 [error] 会包含失败原因
  String? _lastError;
  String? get lastError => _lastError;

  Future<Position?> getCurrentPosition() async {
    _lastError = null;

    // 1. 检查定位服务是否开启
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _lastError = '请开启手机定位服务';
      return null;
    }

    // 2. 检查/请求权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _lastError = '定位权限被拒绝';
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _lastError = '定位权限已被永久拒绝，请在系统设置中开启';
      return null;
    }

    // 3. 优先尝试上次已知位置（毫秒级，室内也可用）
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _lastPosition = lastPos;
        return _lastPosition;
      }
    } catch (_) {}

    // 4. 获取当前位置（低精度 + 10 秒超时，避免无限等待）
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      return _lastPosition;
    } catch (e) {
      _lastError = '定位超时，请移至开阔地带或确保手机定位已开启';
      return null;
    }
  }

  /// 在全部地区中查找距 (lat, lon) 最近的地区
  /// 返回 null 表示没有有效地区
  ({Region region, double distanceKm})? findNearest(double lat, double lon) {
    final regions = _regionService.allRegions;
    if (regions.isEmpty) return null;

    Region? nearest;
    double minDist = double.infinity;

    for (final r in regions) {
      // 跳过无效坐标（防御性检查，正常情况下不应出现）
      if (r.lat == 0 && r.lon == 0) continue;
      final d = _haversine(lat, lon, r.lat, r.lon);
      if (d < minDist) {
        minDist = d;
        nearest = r;
      }
    }

    if (nearest == null) return null;
    return (region: nearest, distanceKm: minDist);
  }

  /// Haversine 公式计算球面距离（单位：公里）
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // 地球平均半径
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _rad(double deg) => deg * pi / 180;
}
