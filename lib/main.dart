import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'earth_view_native.dart'
    if (dart.library.html) 'earth_view_web.dart';
import 'services/database_helper_mobile.dart'
    if (dart.library.html) 'services/database_helper_stub.dart';
import 'services/favorites_service.dart';
import 'services/insight_service.dart';
import 'services/location_service.dart';
import 'services/region_service.dart';
import 'ui/compare_page.dart';
import 'ui/info_page.dart';
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
  bool _locating = false;
  bool _autoLocateDone = false;
  bool _heatmapOn = false;
  List<InsightLine>? _insights;
  bool _isFavorited = false;
  int? _regionId;

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

    // 异步加载数据洞察
    if (record != null && record.hasData) {
      InsightService.instance.generate(r.id, result.year, result.month, record.mean!).then((list) {
        if (mounted) setState(() => _insights = list);
      });
    } else {
      _insights = null;
    }

    // 有真实数据用真实数据，否则降级为占位值
    final display = (record != null && record.hasData)
        ? record.displayValue!
        : 0.5 + (r.lat.abs() % 0.3);

    // 检查收藏状态
    final fav = await FavoritesService.instance.isFavorited(r.id, result.year, result.month);

    _rotateTo(r.lat, r.lon, r.displayName, display, record, result.year, result.month, r.id);
    if (mounted) setState(() { _isFavorited = fav; _regionId = r.id; });
  }

  Future<void> _openFavorites() async {
    final favs = FavoritesService.instance.favorites;
    if (!mounted) return;

    final result = await showModalBottomSheet<FavoriteItem>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FavoritesSheet(favorites: favs),
    );

    if (result == null || !mounted) return;

    // 跳转到收藏的地区
    final region = RegionService().findById(result.regionId);
    if (region == null) return;

    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final record = await db.query(result.regionId, result.year, result.month);
    if (!mounted) return;
    setState(() => _loading = false);

    final display = (record != null && record.hasData)
        ? record.displayValue!
        : 0.5 + (region.lat.abs() % 0.3);

    _rotateTo(region.lat, region.lon, region.displayName, display, record, result.year, result.month, result.regionId);
    if (mounted) setState(() => _isFavorited = true);
  }

  Future<void> _openCompare() async {
    await Navigator.push(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ComparePage()),
    );
  }

  /// 切换热力图开关（跟随当前查询年月）
  Future<void> _toggleHeatmap() async {
    final state = _earthKey.currentState;
    if (state == null) return;
    await state.toggleHeatmap(year: _year, month: _month);
    if (mounted) setState(() => _heatmapOn = state.heatmapOn);
  }

  /// GPS 定位 → 找最近地区 → 查询数据 → 跳转地球
  Future<void> _locateMe() async {
    setState(() => _locating = true);

    try {
      final locService = LocationService.instance;
      final position = await locService.getCurrentPosition();

      if (!mounted) return;

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locService.lastError ?? '定位失败'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // 在全部地区中找离 GPS 坐标最近的
      final nearest = locService.findNearest(position.latitude, position.longitude);

      if (!mounted) return;

      if (nearest == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到附近地区')),
        );
        return;
      }

      final r = nearest.region;
      final db = DatabaseHelper.instance;

      // 查询最新数据（默认 2024年12月）
      final record = await db.query(r.id, 2024, 12);

      if (!mounted) return;

      final display = (record != null && record.hasData)
          ? record.displayValue!
          : 0.5 + (r.lat.abs() % 0.3);

      // 距离格式化
      final distStr = nearest.distanceKm < 1
          ? '${(nearest.distanceKm * 1000).round()}m'
          : '${nearest.distanceKm.toStringAsFixed(1)}km';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 最近：${r.displayName}（$distStr）'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _rotateTo(r.lat, r.lon, r.displayName, display, record, 2024, 12);
    } finally {
      // 无论成功失败超时，确保重置加载状态
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _rotateTo(double lat, double lon, String name, double value, [InfiltrationRecord? record, int? year, int? month, int? regionId]) async {
    if (!_earthLoaded) return;
    _earthKey.currentState?.rotateTo(lat, lon, name, value, record, year, month, regionId);
    setState(() {
      _regionName = name;
      _record = record;
      _year = year;
      _month = month;
    });
  }

  /// 构建统计指标行
  Widget _fabBtn(IconData? icon, VoidCallback? onTap, Color bg, String tag, {bool loading = false, bool large = false}) {
    final size = large ? 48.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Center(
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: large ? 24 : 18),
        ),
      ),
    );
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _regionName,
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_record != null && _record!.hasData)
                  GestureDetector(
                    onTap: () async {
                      if (_regionId == null || _year == null || _month == null) return;
                      final favService = FavoritesService.instance;
                      if (_isFavorited) {
                        await favService.removeByKey(_regionId!, _year!, _month!);
                        if (mounted) {
                          setState(() => _isFavorited = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已取消收藏'), duration: Duration(seconds: 1)),
                          );
                        }
                      } else {
                        await favService.add(
                          _regionId!, _regionName,
                          _regionName.contains(',') ? _regionName.split(', ').last : _regionName,
                          _year!, _month!,
                        );
                        if (mounted) {
                          setState(() => _isFavorited = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已收藏'), duration: Duration(seconds: 1)),
                          );
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFavorited ? Icons.star : Icons.star_border,
                          color: _isFavorited ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _isFavorited ? '已收藏' : '收藏',
                          style: TextStyle(color: _isFavorited ? Colors.amber : Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
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
              // 数据洞察
              if (_insights != null && _insights!.isNotEmpty) ...[
                const Divider(color: Colors.white24, height: 20),
                const Text('📊 数据洞察',
                    style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ..._insights!.map((ins) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(ins.text,
                                style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
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
        actions: [
          // 收藏列表
          IconButton(
            icon: const Icon(Icons.bookmarks, color: Colors.white54, size: 22),
            onPressed: () => _openFavorites(),
            tooltip: '收藏夹',
          ),
          // 信息
          IconButton(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 1.5),
              ),
              child: const Center(
                child: Text('i', style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage()));
            },
            tooltip: '关于渗透系数',
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
              // 首次加载完成后自动定位
              if (loaded && !_autoLocateDone) {
                _autoLocateDone = true;
                _locateMe();
              }
            },
          ),

          // 仅当视图不自带卡片时才显示（移动端需要，桌面/Web自带）
          if (!EarthViewState.hasOwnOverlay) ...[
            Positioned(
              bottom: 100, // 给底部按钮栏留空间
              left: 16,
              right: 16,
              child: _buildResultCard(),
            ),
          ],
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fabBtn(Icons.compare_arrows, _openCompare, Colors.purple[700]!, 'compare'),
                  const SizedBox(width: 8),
                  _fabBtn(Icons.whatshot, _toggleHeatmap, _heatmapOn ? Colors.orange : Colors.grey[700]!, 'heatmap'),
                  const SizedBox(width: 8),
                  _fabBtn(_locating ? null : Icons.my_location, _locating ? null : _locateMe, Colors.green, 'gps',
                      loading: _locating),
                  const SizedBox(width: 8),
                  _fabBtn(Icons.search, _openSearch, Colors.blue, 'search', large: true),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// 收藏列表底部弹窗
class _FavoritesSheet extends StatelessWidget {
  final List<FavoriteItem> favorites;
  const _FavoritesSheet({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('⭐ 收藏夹', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${favorites.length} 项', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text('☆', style: TextStyle(fontSize: 40, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('还没有收藏', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('查询地区后点击 ★ 即可收藏', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            SizedBox(
              height: 360,
              child: ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (ctx, i) {
                  final f = favorites[i];
                  return Dismissible(
                    key: Key('fav_${f.regionId}_${f.year}_${f.month}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => FavoritesService.instance.remove(i),
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber, size: 20),
                      title: Text(f.displayName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(f.timeLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () => Navigator.pop(context, f),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
