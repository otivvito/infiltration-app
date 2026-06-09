/// 桌面端地球视图 —— 无 3D 地球，仅显示查询结果
/// Windows/Linux/macOS 不需要 WebView，直接展示数据卡片
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
  String _valueText = '请查询地区';
  bool _pageLoaded = false;

  bool get pageLoaded => _pageLoaded;

  @override
  void initState() {
    super.initState();
    // 桌面端即刻"加载完成"
    _pageLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageLoaded?.call(true);
    });
  }

  void hideOverlay() {}
  void showOverlay() {}

  Future<void> rotateTo(double lat, double lon, String name, double value) async {
    setState(() {
      _regionName = name;
      _valueText = '渗透系数: ${value.toStringAsFixed(6)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 80, color: Color(0xFF1B3A5C)),
            const SizedBox(height: 16),
            const Text('渗透系数查询系统',
                style: TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('桌面测试模式 · 数据库已连接',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            // 结果卡片
            Card(
              color: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_regionName,
                        style: const TextStyle(fontSize: 22, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(_valueText,
                        style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('点击右上角 🔍 开始查询',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
