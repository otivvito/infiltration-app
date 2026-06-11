import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'earth_view_native.dart'
    if (dart.library.html) 'earth_view_web.dart';
import 'services/database_helper_mobile.dart'
    if (dart.library.html) 'services/database_helper_stub.dart';
import 'services/region_service.dart';
import 'ui/search_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RegionService().init();
  await DatabaseHelper.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '渗透系数查询',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GlobePage(),
    );
  }
}

class GlobePage extends StatefulWidget {
  const GlobePage({super.key});

  @override
  State<GlobePage> createState() => _GlobePageState();
}

class _GlobePageState extends State<GlobePage> {
  final GlobalKey<EarthViewState> _earthKey = GlobalKey<EarthViewState>();
  String _regionName = '未选择';
  InfiltrationRecord? _record;
  int? _year;
  int? _month;
  bool _earthLoaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Web 端 HTML 搜索按钮点击时触发此回调
    EarthViewState.onSearchTap = _openSearch;
  }

  Future<void> _openSearch() async {
    // Web 端：隐藏 HTML 卡片和按钮，避免遮挡搜索页面
    _earthKey.currentState?.hideOverlay();

    final result = await Navigator.push<SearchResult>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SearchDialog()),
    );

    // 搜索返回后恢复 HTML 控件
    _earthKey.currentState?.showOverlay();

    if (result == null) return;

    final r = result.region;
    final db = DatabaseHelper.instance;

    setState(() => _loading = true);

    // 查询真实数据库
    final record = await db.query(r.id, result.year, result.month);

    setState(() => _loading = false);

    // 有真实数据用真实数据，否则降级为占位值
    final display = (record != null && record.hasData)
        ? record.displayValue!
        : 0.5 + (r.lat.abs() % 0.3);

    _rotateTo(r.lat, r.lon, r.displayName, display, record, result.year, result.month);
  }

  Future<void> _rotateTo(double lat, double lon, String name, double value, [InfiltrationRecord? record, int? year, int? month]) async {
    if (!_earthLoaded) return;
    _earthKey.currentState?.rotateTo(lat, lon, name, value, record, year, month);
    setState(() {
      _regionName = name;
      _record = record;
      _year = year;
      _month = month;
    });
  }

  /// 构建统计指标行
  Widget _statRow(String label, double? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color ?? Colors.grey)),
          Text(
            value != null ? value.toStringAsFixed(6) : '—',
            style: TextStyle(fontSize: 13, color: color ?? Colors.white70, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  /// 构建详细结果卡片
  Widget _buildResultCard() {
    final hasRecord = _record != null;
    final hasData = hasRecord && _record!.hasData;
    final isInitial = !hasRecord && !_loading;
    final timeStr = (_year != null && _month != null)
        ? '$_year年$_month月'
        : null;

    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 地区名
            Center(
              child: Text(
                _regionName,
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (timeStr != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(timeStr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (isInitial) ...[
              const Center(
                child: Column(
                  children: [
                    Text('🔍', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 6),
                    Text('点击搜索按钮查询地区渗透系数',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ] else if (!hasData) ...[
              const Center(
                child: Column(
                  children: [
                    Text('📭', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 6),
                    Text('暂无该地区数据', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ] else ...[
              // 均值 & 中位数
              _statRow('均值 (Mean)', _record!.mean),
              _statRow('中位数 (Median)', _record!.median),
              const Divider(color: Colors.white24, height: 16),
              // 95% 置信区间
              const Text('95% 置信区间', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(child: _statRow('下限', _record!.ci95Low, color: Colors.blueGrey)),
                  const SizedBox(width: 12),
                  Expanded(child: _statRow('上限', _record!.ci95High, color: Colors.blueGrey)),
                ],
              ),
              const SizedBox(height: 8),
              // 75% 置信区间
              const Text('75% 置信区间', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(child: _statRow('下限', _record!.ci75Low, color: Colors.blueGrey)),
                  const SizedBox(width: 12),
                  Expanded(child: _statRow('上限', _record!.ci75High, color: Colors.blueGrey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: kIsWeb ? null : const Text('渗透系数'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 3D 地球（平台自适应）
          EarthView(
            key: _earthKey,
            onPageLoaded: (loaded) {
              setState(() => _earthLoaded = loaded);
            },
          ),

          // 仅当视图不自带卡片时才显示（移动端需要，桌面/Web自带）
          if (!EarthViewState.hasOwnOverlay) ...[
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildResultCard(),
            ),
          ],
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              heroTag: 'search',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onPressed: _openSearch,
              child: const Icon(Icons.search),
            ),
    );
  }
}
