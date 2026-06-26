import 'package:flutter/material.dart';

/// Supported locales.
enum AppLocale { zh, en }

/// Lightweight localization without code generation.
/// Usage: `Strings.of(context).appTitle`
class Strings {
  final AppLocale locale;

  Strings(this.locale);

  // --- Singleton via InheritedWidget ---
  static Strings of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_StringsInherited>();
    return widget?.strings ?? _fallback;
  }

  static Strings _fallback = Strings(AppLocale.zh);

  /// Update the global locale; triggers rebuild on all _StringsScope dependents.
  static void setLocale(BuildContext context, AppLocale locale) {
    _fallback = Strings(locale);
    final scope = context.findAncestorStateOfType<_StringsScopeState>();
    scope?.update(locale);
  }

  static AppLocale currentLocale = AppLocale.zh;

  // ========== Translations ==========

  String get appTitle => locale == AppLocale.en ? 'Infiltration' : '渗透系数查询';
  String get appBarTitle => locale == AppLocale.en ? 'Infiltration Coeff.' : '渗透系数';
  String get notSelected => locale == AppLocale.en ? 'Not selected' : '未选择';
  String get locateFailed => locale == AppLocale.en ? 'Location failed' : '定位失败';
  String get noNearbyRegion => locale == AppLocale.en ? 'No nearby region found' : '未找到附近地区';
  String nearest(String name, String dist) =>
      locale == AppLocale.en ? '📍 Nearest: $name ($dist)' : '📍 最近：$name（$dist）';
  String get searchHint => locale == AppLocale.en ? 'Search regions...' : '搜索地区名称...';
  String get selectTime => locale == AppLocale.en ? 'Select Time' : '选择时间';
  String get selectRegion => locale == AppLocale.en ? 'Select Region' : '选择地区';
  String get noMatch => locale == AppLocale.en ? 'No matching regions' : '未找到匹配地区';
  String foundCount(int n) => locale == AppLocale.en ? 'Found $n regions' : '找到 $n 个地区';
  String searchPrompt(String keyword) =>
      locale == AppLocale.en
          ? 'No regions match "$keyword"\nTry another keyword'
          : '没有匹配的地区名称\n请尝试其他关键词';
  String countryCount(int n) =>
      locale == AppLocale.en ? '$n countries' : '共 $n 个国家/地区';
  String regionCount(int n) =>
      locale == AppLocale.en ? '$n regions' : '$n 个地区';
  String get year => locale == AppLocale.en ? 'Year' : '年份';
  String get month => locale == AppLocale.en ? 'Month' : '月份';
  String get searchTapHint => locale == AppLocale.en
      ? 'Tap search to query infiltration data'
      : '点击搜索按钮查询地区渗透系数';
  String get noData => locale == AppLocale.en ? 'No data for this region' : '暂无该地区数据';
  String get tryOtherTime => locale == AppLocale.en ? 'Try another year or month' : '请尝试其他年份或月份';
  String get meanLabel => locale == AppLocale.en ? 'Mean' : '均值';
  String get medianLabel => locale == AppLocale.en ? 'Median' : '中位数';
  String get ci95Label => locale == AppLocale.en ? '95% CI' : '95% 置信区间';
  String get ci75Label => locale == AppLocale.en ? '75% CI' : '75% 置信区间';
  String get lowerBound => locale == AppLocale.en ? 'Lower' : '下限';
  String get upperBound => locale == AppLocale.en ? 'Upper' : '上限';
  String get insights => locale == AppLocale.en ? '📊 Insights' : '📊 数据洞察';
  String get favorites => locale == AppLocale.en ? '⭐ Favorites' : '⭐ 收藏夹';
  String get favoritesEmpty => locale == AppLocale.en ? 'No favorites yet' : '还没有收藏';
  String get favoritesHint => locale == AppLocale.en
      ? 'Tap ★ after query to save'
      : '查询地区后点击 ★ 即可收藏';
  String get favorited => locale == AppLocale.en ? 'Saved' : '已收藏';
  String get unfavorited => locale == AppLocale.en ? 'Removed' : '已取消收藏';
  String get favorite => locale == AppLocale.en ? 'Fav' : '收藏';
  String get aboutTitle => locale == AppLocale.en ? 'About Infiltration' : '关于渗透系数';
  String get compareTitle => locale == AppLocale.en ? 'Compare' : '对比模式';
  String get compareSelect => locale == AppLocale.en ? 'Tap to select' : '点击选择';
  String get vs => 'VS';
  String get heatmapLabel => locale == AppLocale.en ? 'Heatmap' : '热力图';
  String get heatmapOn => locale == AppLocale.en ? 'ON' : 'ON';
  String get heatmapOff => locale == AppLocale.en ? 'Heatmap' : '热力图';
  String get desktopTestMode => locale == AppLocale.en
      ? 'Desktop Test Mode · Database Connected'
      : '桌面测试模式 · 数据库已连接';
  String get permissionDenied => locale == AppLocale.en
      ? 'Location permission denied'
      : '定位权限被拒绝';
  String get permissionPermanentlyDenied => locale == AppLocale.en
      ? 'Location permission permanently denied, enable in Settings'
      : '定位权限已被永久拒绝，请在系统设置中开启';
  String get locationDisabled => locale == AppLocale.en
      ? 'Please enable location service'
      : '请开启手机定位服务';
  String get exitHint => locale == AppLocale.en
      ? 'Press again to exit'
      : '再按一次退出应用';

  String get locationTimeout => locale == AppLocale.en
      ? 'Location timeout, move to open area'
      : '定位超时，请移至开阔地带或确保手机定位已开启';

  // Info page strings
  String get infoWhatIs => locale == AppLocale.en
      ? '🏠 What is Air Infiltration Coefficient?'
      : '🏠 什么是空气渗透系数？';
  String get infoWhatIsBody => locale == AppLocale.en
      ? 'The Air Infiltration Coefficient measures the rate at which outdoor air enters '
          'a building through its envelope (walls, door/window gaps, cracks, etc.), '
          'commonly expressed in ACH (Air Changes per Hour).\n\n'
          '• High coefficient → poor air-tightness, outdoor air enters easily\n'
          '• Low coefficient → good air-tightness, limited indoor/outdoor air exchange\n\n'
          'It is a key parameter for evaluating building envelope performance.'
      : '空气渗透系数（Air Infiltration Coefficient）是衡量室外空气通过建筑围护结构'
          '（墙体、门窗缝隙、裂缝等）渗入室内的速率指标，常用单位为 ACH（每小时换气次数）'
          '或 m³/(h·m²)。\n\n'
          '• 渗透系数高 → 建筑气密性差，室外空气容易进入\n'
          '• 渗透系数低 → 建筑气密性好，室内外空气交换少\n\n'
          '它是评估建筑围护结构性能的关键参数之一。';
  String get infoWhyImportant => locale == AppLocale.en
      ? '🌍 Why Is It Important?'
      : '🌍 为什么重要？';
  String get infoWhyImportantBody => locale == AppLocale.en
      ? 'Air infiltration directly impacts building energy consumption, indoor environmental '
          'quality, and human health:\n\n'
          '• Building Energy: heat loss from infiltration can account for 30%-50% of total '
          'building energy consumption\n'
          '• Indoor Air Quality: outdoor PM2.5, ozone, pollen enter indoors via infiltration\n'
          '• Thermal Comfort: uncontrolled infiltration causes drafts and uneven temperatures\n'
          '• Moisture & Mold: infiltrated moisture can condense inside walls, causing structural '
          'damage and mold\n'
          '• HVAC Design: accurate infiltration coefficients are essential for HVAC sizing and '
          'energy simulation\n'
          '• Building Codes: many standards set air-tightness requirements (e.g., Passivhaus '
          'requires n50 ≤ 0.6 ACH)'
      : '空气渗透直接影响建筑能耗、室内环境质量和人体健康：\n\n'
          '• 建筑能耗：空气渗透造成的热量损失可占建筑总能耗的 30%-50%，是供暖和制冷负荷的主要来源之一\n'
          '• 室内空气质量：室外 PM2.5、臭氧、花粉等污染物通过渗透进入室内，影响呼吸健康\n'
          '• 热舒适性：不受控制的空气渗透导致冷风侵入、温度分布不均，降低居住舒适度\n'
          '• 湿气与霉菌：空气渗透携带的水汽可能在墙体内部凝结，导致结构损坏和霉菌滋生\n'
          '• HVAC 系统设计：准确的渗透系数是暖通空调系统选型和能耗模拟的基础输入\n'
          '• 建筑节能标准：各国建筑规范对气密性有明确要求（如 Passivhaus 标准要求 n50 ≤ 0.6 ACH）';
  String get infoWhatWeProvide => locale == AppLocale.en
      ? '📊 What Does This App Provide?'
      : '📊 本 App 提供什么？';
  String get infoWhatWeProvideBody => locale == AppLocale.en
      ? 'Based on monthly air infiltration coefficient data for 3,614 regions worldwide '
          'from 1990-2024, you can:\n\n'
          '• Query 6 statistical indicators for any region (mean, median, 95%/75% CI)\n'
          '• View global heatmap showing geographic distribution\n'
          '• Drag timeline to observe 35-year trends in building air-tightness\n'
          '• Compare two regions side by side\n'
          '• Get smart insights (global ranking, trend direction, seasonal patterns)\n'
          '• GPS auto-location to quickly find your local data'
      : '基于全球 3,614 个地区 1990-2024 年的月度空气渗透系数数据，您可以：\n\n'
          '• 查询任意地区的 6 项统计指标（均值、中位数、95%/75% 置信区间）\n'
          '• 查看全球热力图，了解渗透系数的地理分布\n'
          '• 拖动时间轴观察 1990-2024 年建筑气密性的变化趋势\n'
          '• 并排对比两个地区的数据差异\n'
          '• 获取智能数据洞察（全球排名、趋势方向、季节性特征）\n'
          '• GPS 自动定位，快速查看您所在地区的空气渗透系数';
  String get infoDataNotes => locale == AppLocale.en
      ? '🔬 Data Notes'
      : '🔬 数据说明';
  String get infoDataNotesBody => locale == AppLocale.en
      ? 'Time Range: Jan 1990 – Dec 2024 (monthly data)\n'
          'Coverage: 3,614 observation points across 252 countries and regions\n'
          'Statistics: Mean, Median, 95% CI bounds, 75% CI bounds\n'
          'Applications: Building energy design, indoor air quality assessment, '
          'HVAC optimization, building code development'
      : '数据时间范围：1990 年 1 月 – 2024 年 12 月（月度数据）\n'
          '覆盖范围：全球 252 个国家和地区的 3,614 个观测点\n'
          '统计指标：均值、中位数、95% 置信区间上下限、75% 置信区间上下限\n'
          '应用领域：建筑节能设计、室内空气质量评估、HVAC 系统优化、建筑规范制定';
  String get version => '渗透系数查询系统 v1.0';

  // Insight strings (dynamic)
  String globalRank(int rank, int total, String pct, String value) =>
      locale == AppLocale.en
          ? 'Global rank: ~#$rank out of $total regions (top $pct%), coefficient $value'
          : '全球排名：在 $total 个地区中排名约第 $rank 名（前 $pct%），渗透系数$value';

  String trendText(String dir, String from, String to, String dirEn, String pct) =>
      locale == AppLocale.en
          ? 'Trend 1990-2024: ${dirEn}ward, from $from to $to ($pct%)'
          : '时间趋势：1990-2024 年呈${dir}趋势，从 $from 变为 $to（${dir}${pct}%）';

  String monthlyPattern(int highM, String highV, int lowM, String lowV) =>
      locale == AppLocale.en
          ? 'Monthly: peak in month $highM (mean $highV), low in month $lowM (mean $lowV)'
          : '月度特征：${highM}月最高（均值 $highV），${lowM}月最低（均值 $lowV）';

  String yearMonth(int year, int month) =>
      locale == AppLocale.en ? '$year/$month' : '$year年$month月';

  String get shareText => locale == AppLocale.en
      ? '— Infiltration Coefficient Query System\n'
          'otivvito.github.io/infiltration-app'
      : '— 渗透系数查询系统\n'
          'otivvito.github.io/infiltration-app';

  String get compareNoDataA => locale == AppLocale.en ? 'Region A has no data' : '地区 A 暂无数据';
  String get compareNoDataB => locale == AppLocale.en ? 'Region B has no data' : '地区 B 暂无数据';

  String timeYear(int year) => locale == AppLocale.en ? '$year' : '${year}年';

  String get indicator => locale == AppLocale.en ? 'Indicator' : '指标';
  String get regionA => locale == AppLocale.en ? 'Region A' : '地区 A';
  String get regionB => locale == AppLocale.en ? 'Region B' : '地区 B';
}

// === InheritedWidget for tree-based lookup ===
class _StringsInherited extends InheritedWidget {
  final Strings strings;
  const _StringsInherited({required this.strings, required super.child});

  @override
  bool updateShouldNotify(_StringsInherited old) => strings != old.strings;
}

class _StringsScopeState extends State<StringsScope> {
  late Strings _strings;

  @override
  void initState() {
    super.initState();
    _strings = Strings(Strings.currentLocale);
  }

  void update(AppLocale locale) {
    setState(() {
      Strings.currentLocale = locale;
      _strings = Strings(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StringsInherited(strings: _strings, child: widget.child);
  }
}

/// Wrap the app with this to enable localization.
class StringsScope extends StatefulWidget {
  final Widget child;
  const StringsScope({super.key, required this.child});

  @override
  State<StringsScope> createState() => _StringsScopeState();
}
