// 桌面端地球视图 —— 2D 世界地图 + 结果卡片
// Windows/Linux/macOS 不需要 WebView，使用 CustomPaint 渲染地图
import 'dart:ui';

import 'package:flutter/material.dart';

import 'painters/world_map_painter.dart';
import 'services/favorites_service.dart';
import 'services/heatmap_service.dart';
import 'services/insight_service.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;
  final VoidCallback? onHeatmapChanged;

  const EarthView({super.key, this.onPageLoaded, this.onHeatmapChanged});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView>
    with SingleTickerProviderStateMixin {
  static void Function()? onSearchTap;

  /// 桌面版自带完整结果卡片，main.dart 不需要再叠加
  static const bool hasOwnOverlay = true;

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

  // Heatmap state
  bool _heatmapOn = false;
  bool _heatmapLoading = false;
  Picture? _heatmapPicture;
  List<({double lon, double lat, Color color})> _heatPoints = [];
  int _queryYear = 2024;
  int _queryMonth = 12;
  int _heatmapSliderYear = 2024;
  bool _heatmapPlaying = false;
  List<InsightLine>? _insights;
  bool _isFavorited = false;
  int? _storedRegionId;

  // Time animation
  late AnimationController _timeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool get pageLoaded => _pageLoaded;
  bool get heatmapOn => _heatmapOn;

  @override
  void initState() {
    super.initState();
    _timeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // 35年 ≈ 0.34s/年
    )..addListener(() {
      if (_heatmapOn && _heatmapPlaying) {
        final y = 1990 + (_timeCtrl.value * 34).round();
        if (y != _heatmapSliderYear) {
          _heatmapSliderYear = y;
          _rebuildPictureForYear(y);
        }
      }
    });
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
    _timeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void hideOverlay() {}
  void showOverlay() {}

  /// 切换热力图开关
  Future<void> toggleHeatmap({int? year, int? month}) async {
    if (_heatmapLoading) return;

    if (_heatmapOn) {
      _timeCtrl.stop();
      setState(() {
        _heatmapOn = false;
        _heatmapPicture = null;
        _heatmapPlaying = false;
      });
      widget.onHeatmapChanged?.call();
      return;
    }

    final y = year ?? _queryYear;
    final m = month ?? _queryMonth;
    _heatmapSliderYear = y;
    setState(() => _heatmapLoading = true);

    try {
      final service = HeatmapService.instance;
      // 首次打开时预加载全部年份
      if (!service.isPreloaded) {
        await service.preloadAllYears(month: m);
      }
      final points = await service.load(year: y, month: m);
      final mapPoints = points
          .map((p) => (lon: p.lon, lat: p.lat, color: p.color))
          .toList();

      Picture? pic;
      if (mounted && _mapSize != Size.zero && mapPoints.isNotEmpty) {
        pic = WorldMapPainter.prerenderHeatmap(_mapSize, mapPoints);
      }

      if (mounted) {
        setState(() {
          _heatmapOn = true;
          _heatmapLoading = false;
          _heatPoints = mapPoints;
          _heatmapPicture = pic;
        });
        widget.onHeatmapChanged?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _heatmapLoading = false);
    }
  }

  void _rebuildPictureForYear(int year) async {
    final points = HeatmapService.instance.getForYear(year);
    if (points == null || _mapSize == Size.zero) return;
    final mapPoints = points
        .map((p) => (lon: p.lon, lat: p.lat, color: p.color))
        .toList();
    final pic = WorldMapPainter.prerenderHeatmap(_mapSize, mapPoints);
    if (mounted) setState(() => _heatmapPicture = pic);
  }

  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month, int? regionId]) async {
    setState(() {
      _targetLat = lat;
      _targetLon = lon;
      _regionName = name;
      _timeLabel = (year != null && month != null) ? '$year年$month月' : null;
      if (year != null) _queryYear = year;
      if (month != null) _queryMonth = month;
      // 加载数据洞察 + 收藏状态
      if (record != null && record.hasData && regionId != null && year != null && month != null && record.mean != null) {
        _storedRegionId = regionId;
        InsightService.instance.generate(regionId, year, month, record.mean).then((list) {
          if (mounted) setState(() => _insights = list);
        });
        FavoritesService.instance.isFavorited(regionId, year, month).then((fav) {
          if (mounted) setState(() => _isFavorited = fav);
        });
      } else {
        _insights = null;
        _isFavorited = false;
      }
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

  /// 时间轴滑块 + 播放按钮
  Widget _buildTimeSlider() {
    return Row(
      children: [
        // 播放/暂停
        GestureDetector(
          onTap: () {
            setState(() => _heatmapPlaying = !_heatmapPlaying);
            if (_heatmapPlaying) {
              _timeCtrl.forward(from: (_heatmapSliderYear - 1990) / 34);
            } else {
              _timeCtrl.stop();
            }
          },
          child: Icon(
            _heatmapPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white70,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        // 年份标签
        SizedBox(
          width: 44,
          child: Text(
            '$_heatmapSliderYear',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        // 滑块
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: Colors.orange,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.orange,
            ),
            child: Slider(
              value: _heatmapSliderYear.toDouble(),
              min: 1990,
              max: 2024,
              divisions: 34,
              onChanged: (v) {
                final y = v.round();
                if (y != _heatmapSliderYear) {
                  setState(() => _heatmapSliderYear = y);
                  _rebuildPictureForYear(y);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 热力图颜色图例
  Widget _buildLegend() {
    final colors = [
      const Color.fromARGB(160, 0, 128, 255),   // 蓝（低）
      const Color.fromARGB(160, 0, 255, 255),     // 青
      const Color.fromARGB(160, 0, 255, 0),       // 绿
      const Color.fromARGB(160, 255, 255, 0),     // 黄
      const Color.fromARGB(160, 255, 0, 0),       // 红（高）
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('低', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 4),
          ...colors.map((c) => Container(
                width: 28, height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
          const SizedBox(width: 4),
          const Text('高', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('渗透系数查询系统',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  const SizedBox(width: 12),
                  // 热力图切换按钮
                  GestureDetector(
                    onTap: toggleHeatmap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _heatmapOn ? Colors.orange : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _heatmapLoading
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 1.5),
                                )
                              : Text(_heatmapOn ? '🔥' : '🌡️',
                                  style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            _heatmapOn ? 'ON' : '热力图',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Text('桌面测试模式 · 数据库已连接',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              // 颜色图例
              if (_heatmapOn && _heatPoints.isNotEmpty)
                _buildLegend(),
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
                              heatmapPicture: _heatmapOn ? _heatmapPicture : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 时间轴滑块（热力图模式下显示）──
              if (_heatmapOn) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTimeSlider(),
                ),
                const SizedBox(height: 8),
              ],

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Text(
                              _regionName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            if (_hasData)
                              GestureDetector(
                                onTap: () async {
                                  if (_storedRegionId == null || _queryYear == 0 || _queryMonth == 0) return;
                                  final fs = FavoritesService.instance;
                                  if (_isFavorited) {
                                    await fs.removeByKey(_storedRegionId!, _queryYear, _queryMonth);
                                    if (mounted) setState(() => _isFavorited = false);
                                  } else {
                                    await fs.add(
                                      _storedRegionId!, _regionName,
                                      _regionName.contains(',') ? _regionName.split(', ').last : _regionName,
                                      _queryYear, _queryMonth,
                                    );
                                    if (mounted) setState(() => _isFavorited = true);
                                  }
                                },
                                child: Icon(
                                  _isFavorited ? Icons.star : Icons.star_border,
                                  color: _isFavorited ? Colors.amber : Colors.grey,
                                  size: 22,
                                ),
                              ),
                          ],
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
                          // 数据洞察
                          if (_insights != null && _insights!.isNotEmpty) ...[
                            const Divider(color: Colors.white24, height: 16),
                            const Text('📊 数据洞察',
                                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ..._insights!.map((ins) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ins.icon, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(ins.text,
                                            style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
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
