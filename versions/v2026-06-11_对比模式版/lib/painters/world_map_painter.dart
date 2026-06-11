import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/world_outlines.dart';

/// 2D world map rendered with Mercator projection.
/// Supports animated marker with pulse effect + pre-rendered heatmap overlay.
class WorldMapPainter extends CustomPainter {
  final Offset? markerPos;
  final double markerPulse; // 0.0–1.0
  final String? markerLabel;
  final Picture? heatmapPicture; // 预渲染的热力图（避免每帧3614次drawCircle）
  final Color oceanColor;
  final Color landColor;
  final Color landBorderColor;
  final Color markerColor;
  final Color gridColor;
  final bool showGrid;

  WorldMapPainter({
    this.markerPos,
    this.markerPulse = 0.0,
    this.markerLabel,
    this.heatmapPicture,
    this.oceanColor = const Color(0xFF0D1B2A),
    this.landColor = const Color(0xFF1B3A5C),
    this.landBorderColor = const Color(0xFF2B5A8C),
    this.markerColor = const Color(0xFFFF6D00),
    this.gridColor = const Color(0x15FFFFFF),
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawOcean(canvas, size);
    if (showGrid) _drawGrid(canvas, size);
    _drawContinents(canvas, size, heatmapOn: heatmapPicture != null);
    if (heatmapPicture != null) {
      canvas.drawPicture(heatmapPicture!); // 一次调用，O(1)
    }
    if (markerPos != null) _drawMarker(canvas, markerPos!);
    _drawBorder(canvas, size);
  }

  /// 预渲染热力图气泡（国家级别，大圆点）
  static Picture prerenderHeatmap(Size size, List<({double lon, double lat, Color color})> points) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    // 气泡半径：根据点数自适应
    final radius = (size.width / 180).clamp(4.0, 14.0);
    for (final pt in points) {
      final x = (pt.lon + 180) / 360 * size.width;
      final clamped = pt.lat.clamp(-85.0, 85.0);
      final rad = clamped * math.pi / 180;
      final y = (-math.log(math.tan(math.pi / 4 + rad / 2)) + math.pi) / (2 * math.pi) * size.height;
      if (x < -2 || x > size.width + 2 || y < -2 || y > size.height + 2) continue;
      // 外发光效果
      canvas.drawCircle(Offset(x, y), radius + 2,
          Paint()..color = pt.color.withAlpha(60));
      // 主体色块
      canvas.drawCircle(Offset(x, y), radius,
          Paint()..color = pt.color);
    }
    return recorder.endRecording();
  }

  void _drawOcean(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = oceanColor,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (var lat = -60.0; lat <= 60.0; lat += 30) {
      final y = _mercatorY(lat, size);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var lon = -180.0; lon <= 180.0; lon += 30) {
      final x = _mercatorX(lon, size);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final eqY = _mercatorY(0, size);
    canvas.drawLine(Offset(0, eqY), Offset(size.width, eqY), paint..color = gridColor.withAlpha(40));
  }

  void _drawContinents(Canvas canvas, Size size, {bool heatmapOn = false}) {
    final fillPaint = Paint()
      ..color = heatmapOn ? landColor.withAlpha(140) : landColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = landBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final polygon in WorldOutlines.allPolygons) {
      final path = Path();
      bool first = true;
      for (final point in polygon) {
        final x = _mercatorX(point[0], size);
        final y = _mercatorY(point[1], size);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawMarker(Canvas canvas, Offset pos) {
    if (markerPulse > 0.01) {
      final pulseRadius = 4.0 + markerPulse * 20.0;
      final pulseAlpha = ((1.0 - markerPulse) * 180).round();
      canvas.drawCircle(pos, pulseRadius,
          Paint()
            ..color = markerColor.withAlpha(pulseAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
    }
    canvas.drawCircle(pos, 4.0, Paint()..color = markerColor);
    canvas.drawCircle(pos, 1.5, Paint()..color = Colors.white);

    if (markerLabel != null && markerLabel!.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: markerLabel,
          style: TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black.withAlpha(200), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - 18.0));
    }
  }

  void _drawBorder(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = landBorderColor.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  double _mercatorX(double lon, Size size) => (lon + 180) / 360 * size.width;

  double _mercatorY(double lat, Size size) {
    final clamped = lat.clamp(-85.0, 85.0);
    final rad = clamped * math.pi / 180;
    final y = -math.log(math.tan(math.pi / 4 + rad / 2));
    return (y + math.pi) / (2 * math.pi) * size.height;
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.markerPos != markerPos ||
        oldDelegate.markerPulse != markerPulse ||
        oldDelegate.markerLabel != markerLabel ||
        oldDelegate.heatmapPicture != heatmapPicture;
  }

  /// Convert geographic (lon, lat) to canvas position
  static Offset project(double lon, double lat, Size size) {
    final x = (lon + 180) / 360 * size.width;
    final clamped = lat.clamp(-85.0, 85.0);
    final rad = clamped * math.pi / 180;
    final y = -math.log(math.tan(math.pi / 4 + rad / 2));
    return Offset(x, (y + math.pi) / (2 * math.pi) * size.height);
  }
}
