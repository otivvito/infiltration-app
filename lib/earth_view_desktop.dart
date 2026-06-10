// 桌面端地球视图 —— 2D 世界地图 + 结果卡片
// Windows/Linux/macOS 不需要 WebView，使用 CustomPaint 渲染地图
import 'package:flutter/material.dart';

import 'painters/world_map_painter.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;

  const EarthView({super.key, this.onPageLoaded});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView>
    with SingleTickerProviderStateMixin {
  static void Function()? onSearchTap;

  // Data state
  String _regionName = '未选择';
  String? _timeLabel;
  double? _mean;
  double? _median;
  double? _ci95Low;
  double? _ci95High;
  double? _ci75Low;
  double? _ci75High;
  bool _hasData = false;
  bool _pageLoaded = false;

  // Map marker state
  double _targetLat = 35.0;
  double _targetLon = 105.0; // center on China-ish
  Size _mapSize = Size.zero;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool get pageLoaded => _pageLoaded;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutQuad),
    );
    _pageLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageLoaded?.call(true);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void hideOverlay() {}
  void showOverlay() {}

  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month]) async {
    setState(() {
      _targetLat = lat;
      _targetLon = lon;
      _regionName = name;
      _timeLabel = (year != null && month != null) ? '$year年$month月' : null;
      if (record != null) {
        _mean = record.mean;
        _median = record.median;
        _ci95Low = record.ci95Low;
        _ci95High = record.ci95High;
        _ci75Low = record.ci75Low;
        _ci75High = record.ci75High;
        _hasData = record.hasData;
      } else {
        _mean = value;
        _hasData = true;
      }
    });

    // Trigger pulse animation
    _pulseCtrl.forward(from: 0.0);
  }

  Widget _stat(String label, double? v) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(v != null ? v.toStringAsFixed(6) : '—',
          style: const TextStyle(
              fontSize: 13, color: Colors.white70, fontFamily: 'monospace')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Text('渗透系数查询系统',
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              const Text('桌面测试模式 · 数据库已连接',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),

              // ── 2D World Map ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      _mapSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
                      return AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (ctx, _) {
                          return CustomPaint(
                            size: _mapSize,
                            painter: WorldMapPainter(
                              markerPos: _mapSize == Size.zero
                                  ? null
                                  : WorldMapPainter.project(
                                      _targetLon, _targetLat, _mapSize),
                              markerPulse: _pulseAnim.value,
                              markerLabel: _regionName == '未选择' ? null : _regionName,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 结果卡片 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            _regionName,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_timeLabel != null)
                          Center(
                            child: Text(_timeLabel!,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ),
                        const SizedBox(height: 12),
                        if (_regionName == '未选择')
                          const Center(
                            child: Text('🔍 点击右下角按钮查询地区',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey)),
                          )
                        else if (!_hasData)
                          const Center(
                            child: Text('暂无该地区数据',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey)),
                          )
                        else ...[
                          _stat('均值 (Mean)', _mean),
                          _stat('中位数 (Median)', _median),
                          const Divider(color: Colors.white24, height: 12),
                          const Text('95% 置信区间',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(children: [
                            Expanded(child: _stat('L', _ci95Low)),
                            const SizedBox(width: 12),
                            Expanded(child: _stat('H', _ci95High)),
                          ]),
                          const SizedBox(height: 6),
                          const Text('75% 置信区间',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(children: [
                            Expanded(child: _stat('L', _ci75Low)),
                            const SizedBox(width: 12),
                            Expanded(child: _stat('H', _ci75High)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
