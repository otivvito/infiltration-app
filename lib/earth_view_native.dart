// 原生平台路由：Android/iOS → flutter_inappwebview，Desktop → 简易界面
export 'earth_view_desktop.dart'
    if (dart.library.android) 'earth_view_mobile.dart'
    if (dart.library.ios) 'earth_view_mobile.dart';
