import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../services/database_helper_mobile.dart'
    if (dart.library.html) '../services/database_helper_web.dart';

/// Generates a shareable image card for a region's infiltration data.
class ShareCardGenerator {
  final GlobalKey _repaintKey = GlobalKey();

  /// Capture the card widget as a PNG image file and open the share sheet.
  Future<void> share({
    required BuildContext context,
    required String regionName,
    required String country,
    required int year,
    required int month,
    required InfiltrationRecord record,
  }) async {
    try {
      // 1. Show the card briefly to let it render
      final overlay = OverlayEntry(
        builder: (ctx) => Positioned(
          left: -9999,
          top: 0,
          child: Material(
            child: RepaintBoundary(
              key: _repaintKey,
              child: _ShareCardWidget(
                regionName: regionName,
                country: country,
                year: year,
                month: month,
                record: record,
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlay);
      // Wait a frame for the overlay to render
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Capture the RepaintBoundary as an image
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlay.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        overlay.remove();
        return;
      }

      // 3. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'infiltration_${regionName.replaceAll(RegExp(r'[^\w]'), '_')}_${year}_$month.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // 4. Remove the invisible overlay
      overlay.remove();

      // 5. Share
      final xFile = XFile(file.path, mimeType: 'image/png');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: '🌍 $regionName $year年$month月 渗透系数：${record.mean?.toStringAsFixed(6) ?? "—"}',
        ),
      );
    } catch (e) {
      debugPrint('Share card error: $e');
    }
  }
}

/// The visual card widget that gets captured as a share image.
class _ShareCardWidget extends StatelessWidget {
  final String regionName;
  final String country;
  final int year;
  final int month;
  final InfiltrationRecord record;

  const _ShareCardWidget({
    required this.regionName,
    required this.country,
    required this.year,
    required this.month,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080, // 3x pixel ratio → 360dp logical
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D1B2A)],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: Globe icon + App name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  ),
                ),
                child: const Center(
                  child: Text('🌍', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '渗透系数查询',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Infiltration Coefficient',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Divider
          Container(height: 1, color: Colors.white12),

          const SizedBox(height: 40),

          // Region name
          Text(
            regionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            country,
            style: const TextStyle(color: Colors.white38, fontSize: 22),
          ),

          const SizedBox(height: 16),
          Text(
            '$year年${month}月',
            style: const TextStyle(color: Colors.white54, fontSize: 20),
          ),

          const SizedBox(height: 48),

          // Data card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Mean - large display
                const Text(
                  '渗透系数 (Mean)',
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  record.mean?.toStringAsFixed(6) ?? '—',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                // Secondary stats in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _miniStat('中位数', record.median),
                    _miniStat('95% CI 下限', record.ci95Low),
                    _miniStat('95% CI 上限', record.ci95High),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Divider
          Container(height: 1, color: Colors.white12),

          const SizedBox(height: 24),

          // Footer
          const Text(
            'otivvito.github.io/infiltration-app',
            style: TextStyle(color: Colors.white24, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            '数据来源：全球建筑室内空气渗透系数数据库',
            style: TextStyle(color: Colors.white12, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double? value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value?.toStringAsFixed(6) ?? '—',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
