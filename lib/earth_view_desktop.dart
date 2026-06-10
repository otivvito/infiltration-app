// 桌面端地球视图 —— 无 3D 地球，仅显示查询结果
// Windows/Linux/macOS 不需要 WebView，直接展示数据卡片
import 'package:flutter/material.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;

  const EarthView({super.key, this.onPageLoaded});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView> {
  static void Function()? onSearchTap;

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

  bool get pageLoaded => _pageLoaded;

  @override
  void initState() {
    super.initState();
    _pageLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageLoaded?.call(true);
    });
  }

  void hideOverlay() {}
  void showOverlay() {}

  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month]) async {
    setState(() {
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
  }

  Widget _stat(String label, double? v) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(v != null ? v.toStringAsFixed(6) : '—',
          style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'monospace')),
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
              const SizedBox(height: 40),
              const Icon(Icons.public, size: 64, color: Color(0xFF1B3A5C)),
              const SizedBox(height: 12),
              const Text('渗透系数查询系统',
                  style: TextStyle(fontSize: 22, color: Colors.white)),
              const Text('桌面测试模式 · 数据库已连接',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(_regionName,
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        if (_timeLabel != null)
                          Center(
                            child: Text(_timeLabel!,
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                        const SizedBox(height: 12),
                        if (!_hasData)
                          const Center(child: Text('暂无该地区数据', style: TextStyle(fontSize: 14, color: Colors.grey)))
                        else ...[
                          _stat('均值 (Mean)', _mean),
                          _stat('中位数 (Median)', _median),
                          const Divider(color: Colors.white24, height: 12),
                          const Text('95% 置信区间', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(children: [
                            Expanded(child: _stat('L', _ci95Low)),
                            const SizedBox(width: 12),
                            Expanded(child: _stat('H', _ci95High)),
                          ]),
                          const SizedBox(height: 6),
                          const Text('75% 置信区间', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              const SizedBox(height: 16),
              const Text('点击右上角 🔍 开始查询',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
