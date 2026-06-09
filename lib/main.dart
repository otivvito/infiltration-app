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
  double? _infiltrationValue;
  bool _earthLoaded = false;

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

    // 查询真实数据库
    final record = await db.query(r.id, result.year, result.month);

    // 有真实数据用真实数据，否则降级为占位值
    final value = (record != null && record.hasData)
        ? record.displayValue!
        : 0.5 + (r.lat.abs() % 0.3);

    _rotateTo(r.lat, r.lon, r.displayName, value);
  }

  Future<void> _rotateTo(double lat, double lon, String name, double value) async {
    if (!_earthLoaded) return;
    _earthKey.currentState?.rotateTo(lat, lon, name, value);
    setState(() {
      _regionName = name;
      _infiltrationValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: kIsWeb ? null : const Text('渗透系数'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: kIsWeb
            ? null // Web 端搜索按钮由 HTML 元素提供
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                ),
              ],
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

          // 移动端：底部结果卡片
          if (!kIsWeb) ...[
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _regionName,
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _infiltrationValue != null
                            ? '渗透系数: ${_infiltrationValue!.toStringAsFixed(6)}'
                            : '请查询地区',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: () {
                _rotateTo(39.9, 116.4, '北京 (示例)', 0.723);
              },
            ),
    );
  }
}
