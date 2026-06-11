import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/world_outlines.dart';

/// 2D world map rendered with Mercator projection.
/// Supports animated marker with pulse effect.
class WorldMapPainter extends CustomPainter {
  final Offset? markerPos; // canvas position of marker
  final double markerPulse; // 0.0–1.0 animation progress
  final String? markerLabel;
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
    _drawContinents(canvas, size);
    if (markerPos != null) _drawMarker(canvas, markerPos!);
    _drawBorder(canvas, size);
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

    // Latitude lines every 30°
    for (var lat = -60.0; lat <= 60.0; lat += 30) {
      final y = _mercatorY(lat, size);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Longitude lines every 30°
    for (var lon = -180.0; lon <= 180.0; lon += 30) {
      final x = _mercatorX(lon, size);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Equator slightly more visible
    final eqY = _mercatorY(0, size);
    canvas.drawLine(
      Offset(0, eqY),
      Offset(size.width, eqY),
      paint..color = gridColor.withAlpha(40),
    );
  }

  void _drawContinents(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = landColor
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
    // Outer pulse ring
    if (markerPulse > 0.01) {
      final pulseRadius = 4.0 + markerPulse * 20.0;
      final pulseAlpha = ((1.0 - markerPulse) * 180).round();
      final pulsePaint = Paint()
        ..color = markerColor.withAlpha(pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pos, pulseRadius, pulsePaint);
    }

    // Inner dot
    final dotPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4.0, dotPaint);

    // White center
    canvas.drawCircle(
      pos,
      1.5,
      Paint()..color = Colors.white,
    );

    // Label
    if (markerLabel != null && markerLabel!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: markerLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black.withAlpha(200), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Position label above marker
      final labelX = pos.dx - textPainter.width / 2;
      final labelY = pos.dy - 18.0;
      textPainter.paint(canvas, Offset(labelX, labelY));
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

  /// Mercator projection: longitude → x
  double _mercatorX(double lon, Size size) {
    return (lon + 180) / 360 * size.width;
  }

  /// Mercator projection: latitude → y
  double _mercatorY(double lat, Size size) {
    // Clamp to avoid infinity at poles
    final clamped = lat.clamp(-85.0, 85.0);
    final rad = clamped * math.pi / 180;
    final y = -math.log(math.tan(math.pi / 4 + rad / 2));
    // y ranges from -π to π for lat -85 to 85
    return (y + math.pi) / (2 * math.pi) * size.height;
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.markerPos != markerPos ||
        oldDelegate.markerPulse != markerPulse ||
        oldDelegate.markerLabel != markerLabel;
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
