// Web 端地球视图 —— 使用原生 IFrameElement + postMessage 通信
// 独立文件，通过条件导入替换 earth_view_mobile.dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;

  const EarthView({super.key, this.onPageLoaded});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView> {
  /// 主程序可以设置此回调来响应搜索按钮点击
  static void Function()? onSearchTap;

  /// Web 版自带 HTML 卡片，main.dart 不需要再叠加
  static const bool hasOwnOverlay = true;

  html.IFrameElement? _iframe;
  html.ButtonElement? _btn;
  html.ButtonElement? _searchBtn;
  html.DivElement? _card;
  html.SpanElement? _regionSpan;
  html.SpanElement? _timeSpan;
  html.SpanElement? _meanSpan;
  html.SpanElement? _medianSpan;
  html.SpanElement? _ci95Span;
  html.SpanElement? _ci75Span;
  html.SpanElement? _noDataSpan;

  bool _pageLoaded = false;
  final String _viewType = 'earth_iframe_${DateTime.now().millisecondsSinceEpoch}';

  bool get pageLoaded => _pageLoaded;

  /// Web 版暂不支持热力图
  bool get heatmapOn => false;
  Future<void> toggleHeatmap({int? year, int? month}) async {}

  @override
  void initState() {
    super.initState();
    _setupIframe();
  }

  Future<void> _setupIframe() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/earth.html'),
        rootBundle.load('assets/earth_texture.jpg'),
      ]);

      String htmlContent = results[0] as String;
      final imageBytes = (results[1] as ByteData).buffer.asUint8List();
      final base64Image = base64Encode(imageBytes);

      htmlContent = htmlContent.replaceAll(
        "'earth_texture.jpg'",
        "'data:image/jpeg;base64,$base64Image'",
      );

      // 1. iframe（全屏地球）
      _iframe = html.IFrameElement()
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';

      _iframe!.onLoad.listen((_) {
        debugPrint('✅ 地球 iframe 加载完成');
        _pageLoaded = true;
        widget.onPageLoaded?.call(true);
      });

      _iframe!.srcdoc = htmlContent;

      // 2. 底部信息卡片（HTML 元素，叠在 iframe 上方）
      _card = html.DivElement()
        ..style.position = 'fixed'
        ..style.bottom = '30px'
        ..style.left = '20px'
        ..style.right = '20px'
        ..style.backgroundColor = 'rgba(0, 0, 0, 0.85)'
        ..style.borderRadius = '16px'
        ..style.padding = '16px'
        ..style.color = 'white'
        ..style.fontFamily = 'sans-serif'
        ..style.textAlign = 'center'
        ..style.zIndex = '10'
        ..style.pointerEvents = 'none';

      _regionSpan = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '18px'
        ..style.color = 'white'
        ..style.fontWeight = 'bold'
        ..text = '未选择';

      _timeSpan = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '13px'
        ..style.color = 'grey'
        ..text = '';

      _noDataSpan = html.SpanElement()
        ..style.display = 'none'
        ..style.fontSize = '14px'
        ..style.color = 'grey'
        ..text = '暂无该地区数据';

      _meanSpan = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '14px'
        ..style.color = '#ddd'
        ..style.marginTop = '4px'
        ..text = '';

      _medianSpan = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '14px'
        ..style.color = '#ddd'
        ..text = '';

      _ci95Span = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '13px'
        ..style.color = '#aaa'
        ..style.marginTop = '6px'
        ..text = '';

      _ci75Span = html.SpanElement()
        ..style.display = 'block'
        ..style.fontSize = '13px'
        ..style.color = '#aaa'
        ..text = '';

      _card!.append(_regionSpan!);
      _card!.append(_timeSpan!);
      _card!.append(_noDataSpan!);
      _card!.append(_meanSpan!);
      _card!.append(_medianSpan!);
      _card!.append(_ci95Span!);
      _card!.append(_ci75Span!);

      // 3. 定位按钮（HTML 元素，叠在 iframe 上方）
      _btn = html.ButtonElement()
        ..style.position = 'fixed'
        ..style.bottom = '110px'
        ..style.right = '20px'
        ..style.width = '56px'
        ..style.height = '56px'
        ..style.borderRadius = '28px'
        ..style.border = 'none'
        ..style.backgroundColor = '#2196F3'
        ..style.color = 'white'
        ..style.fontSize = '24px'
        ..style.cursor = 'pointer'
        ..style.zIndex = '10'
        ..style.boxShadow = '0 2px 8px rgba(0,0,0,0.4)'
        ..text = '📍';

      _btn!.onClick.listen((_) {
        _rotateToBeijing();
      });

      // 4. 搜索按钮（HTML 元素，叠在 iframe 上方）
      _searchBtn = html.ButtonElement()
        ..style.position = 'fixed'
        ..style.top = '12px'
        ..style.right = '16px'
        ..style.width = '44px'
        ..style.height = '44px'
        ..style.borderRadius = '22px'
        ..style.border = 'none'
        ..style.backgroundColor = 'rgba(255,255,255,0.25)'
        ..style.color = 'white'
        ..style.fontSize = '20px'
        ..style.cursor = 'pointer'
        ..style.zIndex = '10'
        ..text = '🔍';

      _searchBtn!.style.setProperty('backdrop-filter', 'blur(4px)');

      _searchBtn!.onClick.listen((_) {
        onSearchTap?.call();
      });

      // 注册视图（iframe 嵌入 Flutter）
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iframe!,
      );

      // 将 HTML 控件添加到 body（与 Flutter 画布同级，位于 iframe 上方）
      html.document.body?.append(_card!);
      html.document.body?.append(_btn!);
      html.document.body?.append(_searchBtn!);

      // 监听来自 iframe 的消息（点击地球经纬度）
      html.window.onMessage.listen((html.MessageEvent e) {
        debugPrint('📩 收到地球消息: ${e.data}');
      });

      if (mounted) setState(() {});
      debugPrint('🔧 地球 iframe + HTML 按钮已创建, viewType=$_viewType');
    } catch (e) {
      debugPrint('❌ Web 地球初始化失败: $e');
    }
  }

  void _rotateToBeijing() {
    rotateTo(39.9, 116.4, '北京 (示例)', 0.723);
  }

  /// 隐藏 HTML 控件（搜索时调用）
  void hideOverlay() {
    _card?.style.setProperty('display', 'none');
    _btn?.style.setProperty('display', 'none');
    _searchBtn?.style.setProperty('display', 'none');
  }

  /// 显示 HTML 控件（搜索返回后调用）
  void showOverlay() {
    _card?.style.setProperty('display', 'block');
    _btn?.style.setProperty('display', 'block');
    _searchBtn?.style.setProperty('display', 'block');
  }

  /// 通过 postMessage 调用 iframe 中的 rotateTo
  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month]) async {
    debugPrint('🎯 rotateTo: lat=$lat lon=$lon name=$name loaded=$_pageLoaded');
    if (_iframe == null || !_pageLoaded) return;

    _iframe!.contentWindow?.postMessage({
      'action': 'rotateTo',
      'lat': lat,
      'lon': lon,
      'name': name,
      'value': value,
    }, '*');

    // 更新 HTML 卡片
    _regionSpan?.text = name;
    _timeSpan?.text = (year != null && month != null) ? '$year年$month月' : '';

    final hasData = record != null && record.hasData;
    _noDataSpan?.style.display = hasData ? 'none' : 'block';
    _meanSpan?.style.display = hasData ? 'block' : 'none';
    _medianSpan?.style.display = hasData ? 'block' : 'none';
    _ci95Span?.style.display = hasData ? 'block' : 'none';
    _ci75Span?.style.display = hasData ? 'block' : 'none';

    if (hasData) {
      _meanSpan?.text = '均值: ${record.mean?.toStringAsFixed(6) ?? '—'}';
      _medianSpan?.text = '中位数: ${record.median?.toStringAsFixed(6) ?? '—'}';
      _ci95Span?.text = '95% CI: [${record.ci95Low?.toStringAsFixed(4) ?? '—'}, ${record.ci95High?.toStringAsFixed(4) ?? '—'}]';
      _ci75Span?.text = '75% CI: [${record.ci75Low?.toStringAsFixed(4) ?? '—'}, ${record.ci75High?.toStringAsFixed(4) ?? '—'}]';
    } else {
      _meanSpan?.text = '';
      _medianSpan?.text = '';
      _ci95Span?.text = '';
      _ci75Span?.text = '';
    }
  }

  @override
  void dispose() {
    _card?.remove();
    _btn?.remove();
    _searchBtn?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_iframe == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return HtmlElementView(viewType: _viewType);
  }
}
