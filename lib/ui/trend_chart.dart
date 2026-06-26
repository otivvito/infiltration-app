import 'dart:math';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';

/// A single data point in the trend series.
class TrendPoint {
  final int year;
  final double value;
  const TrendPoint({required this.year, required this.value});
}

/// Custom-painted line chart showing 1990-2024 infiltration trend.
class TrendChart extends StatelessWidget {
  final List<TrendPoint> data;
  final double? slope;
  final double? firstValue;
  final double? lastValue;

  const TrendChart({
    super.key,
    required this.data,
    this.slope,
    this.firstValue,
    this.lastValue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final s = Strings.of(context);
    final minY = data.map((p) => p.value).reduce(min);
    final maxY = data.map((p) => p.value).reduce(max);
    final range = maxY - minY > 0 ? maxY - minY : 0.001;

    final dir = slope != null
        ? (slope! > 0
            ? (s.locale == AppLocale.en ? 'Upward' : '上升')
            : (s.locale == AppLocale.en ? 'Downward' : '下降'))
        : '';
    final pct = firstValue != null && lastValue != null && firstValue != 0
        ? ((lastValue! - firstValue!) / firstValue! * 100).abs().toStringAsFixed(0)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                s.locale == AppLocale.en ? 'Trend (1990-2024)' : '趋势 (1990-2024)',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (dir.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '$dir${pct != null ? " $pct%" : ""}',
                  style: TextStyle(
                    color: slope != null && slope! > 0 ? Colors.redAccent : Colors.cyanAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Chart area
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _TrendPainter(
                    data: data,
                    minY: minY,
                    range: range,
                    lineColor: const Color(0xFF4FC3F7),
                    fillColor: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                  ),
                );
              },
            ),
          ),
          // Year labels
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1990', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                Text(data[data.length ~/ 2].year.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                Text('2024', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> data;
  final double minY;
  final double range;
  final Color lineColor;
  final Color fillColor;

  _TrendPainter({
    required this.data,
    required this.minY,
    required this.range,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final w = size.width;
    final h = size.height;
    const padding = 4.0;
    final chartW = w - padding * 2;
    final chartH = h - padding * 2;

    // Compute points
    final points = <Offset>[];
    final n = data.length;
    for (int i = 0; i < n; i++) {
      final x = padding + (i / (n - 1)) * chartW;
      final y = padding + chartH - ((data[i].value - minY) / range) * chartH;
      points.add(Offset(x, y));
    }

    // Draw fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, h - padding);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, h - padding);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw first point
    canvas.drawCircle(points.first, 3.5, Paint()..color = lineColor.withValues(alpha: 0.8));
    // Draw last point
    canvas.drawCircle(points.last, 3.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.data != data || old.minY != minY || old.range != range;
}
