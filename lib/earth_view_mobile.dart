// 移动端地球视图 —— 使用 flutter_inappwebview
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EarthView extends StatefulWidget {
  final void Function(bool loaded)? onPageLoaded;

  const EarthView({super.key, this.onPageLoaded});

  @override
  State<EarthView> createState() => EarthViewState();
}

class EarthViewState extends State<EarthView> {
  /// 搜索按钮回调（Web 端使用，移动端 AppBar 按钮直接处理）
  static void Function()? onSearchTap;

  InAppWebViewController? _controller;
  bool _pageLoaded = false;
  String? _htmlContent;

  bool get pageLoaded => _pageLoaded;

  @override
  void initState() {
    super.initState();
    _prepareHtml();
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

  void hideOverlay() {} // 移动端不需要（Flutter 层级正常）
  void showOverlay() {}

  Future<void> rotateTo(double lat, double lon, String name, double value,
      [dynamic record, int? year, int? month]) async {
    if (_controller == null || !_pageLoaded) return;
    await _controller!.evaluateJavascript(
      source: "rotateTo($lat, $lon, '$name', $value)",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
}
