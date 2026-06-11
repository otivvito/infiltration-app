// 原生平台数据库查询 —— Android/iOS 用 sqflite，Desktop 用 sqflite_common_ffi
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 单条渗透系数查询结果
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
}

/// 数据库管理器（移动端单例）
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;
  DatabaseHelper._();

  Database? _db;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Desktop 平台（Windows/Linux/macOS）需要用 FFI 初始化
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = join(dbDir.path, 'infiltration.db');

    if (!await databaseExists(dbPath)) {
      final bytes = await rootBundle.load('assets/infiltration.db');
      final file = File(dbPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());
    }

    _db = await openDatabase(dbPath, readOnly: true);
    _initialized = true;
  }

  Future<InfiltrationRecord?> query(int regionId, int year, int month) async {
    if (_db == null) await init();

    final rows = await _db!.rawQuery(
      '''SELECT value_mean, value_median, value_ci95_low, value_ci95_high,
                 value_ci75_low, value_ci75_high
         FROM infiltration_data
         WHERE region_id = ? AND year = ? AND month = ?''',
      [regionId, year, month],
    );

    if (rows.isEmpty) return null;
    final r = rows.first;

    return InfiltrationRecord(
      mean: (r['value_mean'] as num?)?.toDouble(),
      median: (r['value_median'] as num?)?.toDouble(),
      ci95Low: (r['value_ci95_low'] as num?)?.toDouble(),
      ci95High: (r['value_ci95_high'] as num?)?.toDouble(),
      ci75Low: (r['value_ci75_low'] as num?)?.toDouble(),
      ci75High: (r['value_ci75_high'] as num?)?.toDouble(),
    );
  }

  /// 热力图查询：获取指定年月所有地区的渗透系数均值
  Future<List<Map<String, Object?>>> heatmapQuery(int year, int month) async {
    if (_db == null) await init();

    return await _db!.rawQuery(
      '''SELECT region_id, value_mean
         FROM infiltration_data
         WHERE year = ? AND month = ? AND value_mean IS NOT NULL''',
      [year, month],
    );
  }

  void close() {
    _db?.close();
    _db = null;
    _initialized = false;
  }
}
