// 移动端地球视图 —— 使用 flutter_inappwebview
// 热力图模式：切换到 Flutter 2D 地图原生渲染（零 JS 开销）
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'painters/world_map_painter.dart';
import 'services/heatmap_service.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;

  const EarthView({super.key, this.onPageLoaded});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView>
    with TickerProviderStateMixin {
  static void Function()? onSearchTap;
  static const bool hasOwnOverlay = false;

  InAppWebViewController? _controller;
  bool _pageLoaded = false;
  String? _htmlContent;

  // 热力图状态
  bool _heatmapOn = false;
  bool _heatmapLoading = false;
  int _queryYear = 2024;
  int _queryMonth = 12;
  ui.Picture? _heatmapPicture;
  Size _heatmapSize = Size.zero;
  int _heatmapSliderYear = 2024;
  bool _heatmapPlaying = false;
  late AnimationController _timeCtrl;

  bool get pageLoaded => _pageLoaded;
  bool get heatmapOn => _heatmapOn;

  Future<void> toggleHeatmap({int? year, int? month}) async {
    if (_heatmapLoading) return;

    if (_heatmapOn) {
      _timeCtrl.stop();
      setState(() {
        _heatmapOn = false;
        _heatmapPicture = null;
        _heatmapPlaying = false;
      });
      return;
    }

    final y = year ?? _queryYear;
    final m = month ?? _queryMonth;
    _heatmapSliderYear = y;
    setState(() => _heatmapLoading = true);

    try {
      final service = HeatmapService.instance;
      if (!service.isPreloaded) {
        await service.preloadAllYears(month: m);
      }
      final points = await service.load(year: y, month: m);
      if (!mounted) return;

      final mapPoints = points
          .map((p) => (lon: p.lon, lat: p.lat, color: p.color))
          .toList();

      ui.Picture? pic;
      if (_heatmapSize != Size.zero && mapPoints.isNotEmpty) {
        pic = WorldMapPainter.prerenderHeatmap(_heatmapSize, mapPoints);
      }

      if (mounted) {
        setState(() {
          _heatmapOn = true;
          _heatmapLoading = false;
          _heatmapPicture = pic;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _heatmapLoading = false);
    }
  }

  void _rebuildForYear(int year) async {
    final points = HeatmapService.instance.getForYear(year);
    if (points == null || _heatmapSize == Size.zero) return;
    final mapPoints = points
        .map((p) => (lon: p.lon, lat: p.lat, color: p.color))
        .toList();
    final pic = WorldMapPainter.prerenderHeatmap(_heatmapSize, mapPoints);
    if (mounted) setState(() => _heatmapPicture = pic);
  }

  @override
  void initState() {
    super.initState();
    _timeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(() {
      if (_heatmapOn && _heatmapPlaying) {
        final y = 1990 + (_timeCtrl.value * 34).round();
        if (y != _heatmapSliderYear) {
          _heatmapSliderYear = y;
          _rebuildForYear(y);
        }
      }
    });
    _prepareHtml();
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepareHtml() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/earth.html'),
      rootBundle.load('assets/earth_texture.jpg'),
    ]);

    String html = results[0] as String;
    final imageBytes = (results[1] as ByteData).buffer.asUint8List();
    final base64Image = base64Encode(imageBytes);

    html = html.replaceAll(
      "'earth_texture.jpg'",
      "'data:image/jpeg;base64,$base64Image'",
    );

    if (mounted) setState(() => _htmlContent = html);
  }

  void hideOverlay() {}
  void showOverlay() {}

  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month]) async {
    if (_controller == null || !_pageLoaded) return;
    if (year != null) _queryYear = year;
    if (month != null) _queryMonth = month;
    await _controller!.evaluateJavascript(
      source: "rotateTo($lat, $lon, '$name', $value)",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 热力图模式：2D 世界地图 + 时间轴滑块
    if (_heatmapOn) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final mapW = w;
                  final mapH = w / 2;
                  final topPad = (h - mapH) / 2;
                  final size = Size(mapW, mapH);
                  if (size != _heatmapSize && _heatmapPicture != null) {
                    _heatmapSize = size;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _rebuildPicture(size);
                    });
                  }
                  return Padding(
                    padding: EdgeInsets.only(top: topPad > 0 ? topPad : 0),
                    child: CustomPaint(
                      size: size,
                      painter: WorldMapPainter(
                        heatmapPicture: _heatmapPicture,
                        showGrid: false,
                        landColor: const Color(0x8C1B3A5C),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 时间轴滑块
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildMobileTimeSlider(),
            ),
          ],
        ),
      );
    }

    // 正常模式：3D 地球 WebView
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _htmlContent!,
        baseUrl: WebUri('about:blank'),
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        try {
          controller.addJavaScriptHandler(
            handlerName: 'flutter',
            callback: (args) {
              debugPrint('WebView 消息: $args');
            },
          );
        } catch (e) {
          debugPrint('JS handler 不可用: $e');
        }
      },
      onLoadStop: (controller, url) {
        _pageLoaded = true;
        widget.onPageLoaded?.call(true);
      },
    );
  }
  Widget _buildMobileTimeSlider() {
    return Row(
      children: [
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
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          child: Text(
            '$_heatmapSliderYear',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
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
                  _rebuildForYear(y);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _rebuildPicture(Size size) async {
    if (!_heatmapOn || !mounted) return;
    final points = HeatmapService.instance.cached;
    if (points == null) return;
    final mapPoints = points
        .map((p) => (lon: p.lon, lat: p.lat, color: p.color))
        .toList();
    final pic = WorldMapPainter.prerenderHeatmap(size, mapPoints);
    if (mounted && _heatmapOn) {
      setState(() => _heatmapPicture = pic);
    }
  }
}
