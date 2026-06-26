import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_helper_mobile.dart'
    if (dart.library.html) '../services/database_helper_web.dart';

/// Web stub: shares text only (no image capture on web).
class ShareCardGenerator {
  Future<void> share({
    required BuildContext context,
    required String regionName,
    required String country,
    required int year,
    required int month,
    required InfiltrationRecord record,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: '🌍 $regionName ($country)\n'
              '$year年$month月\n'
              '渗透系数：${record.mean?.toStringAsFixed(6) ?? "—"}\n'
              '中位数：${record.median?.toStringAsFixed(6) ?? "—"}\n'
              '95% CI：[${record.ci95Low?.toStringAsFixed(6) ?? "—"}, ${record.ci95High?.toStringAsFixed(6) ?? "—"}]\n'
              '\n— 渗透系数查询系统\n'
              'otivvito.github.io/infiltration-app',
        ),
      );
    } catch (e) {
      debugPrint('Share stub error: $e');
    }
  }
}
