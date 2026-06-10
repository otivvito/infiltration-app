# 🌍 全球渗透系数查询 App

> 基于 Flutter + Three.js 的跨平台应用，用 3D 地球 / 2D 世界地图查询全球建筑室内渗透系数。
>
> 数据：**3614 地区 × 1990–2024 年月度 × 6 项统计指标**（均值、中位数、CI95、CI75）

---

## 🎯 项目目标

将科研数据集（164MB SQLite）变成手机 App，支持：
- 🗺️ 3D 地球（Web）或 2D 世界地图（桌面）可视化定位
- 🔍 国家 → 地区 → 年月 三级搜索
- 📊 6 项统计指标展示
- 📍 GPS 自动定位（代码就绪，待测试）

---

## 📦 技术架构

```
lib/
├── main.dart                         # App 入口，搜索与地球联动
├── earth_view_web.dart               # Web : IFrameElement + Three.js 3D 地球
├── earth_view_mobile.dart            # 移动端 : flutter_inappwebview + 3D 地球
├── earth_view_desktop.dart           # 桌面端 : 2D 世界地图 (CustomPaint)
├── earth_view_native.dart            # 原生平台路由（条件导出）
├── services/
│   ├── region_service.dart           # 地区数据加载与搜索 (regions.json)
│   ├── database_helper_mobile.dart   # SQLite 查询 (sqflite + sqflite_common_ffi)
│   └── database_helper_stub.dart     # Web 端数据库存根
├── ui/
│   └── search_dialog.dart            # 搜索 UI：搜索 → 国家 → 地区 → 年月
├── painters/
│   └── world_map_painter.dart        # 2D 世界地图 CustomPainter（墨卡托投影）
└── data/
    └── world_outlines.dart           # 简化的大洲/岛屿轮廓坐标
```

**平台自适应策略：**
```
main.dart
  ├─ Web     → earth_view_web       (3D Three.js, IFrameElement)
  └─ Native  → earth_view_native
                 ├─ Android/iOS  → earth_view_mobile   (InAppWebView + 3D)
                 └─ Desktop      → earth_view_desktop  (CustomPaint 2D 地图)
```

---

## 📝 开发记录 (2026-06-10/11)

```
Git Log
───────
9132b99 feat: 去除DEBUG横幅 + 配置release签名
7203903 fix: 允许Gradle处理含中文路径的项目
a27ace8 refactor: 移除演示FAB, 搜索按钮移到右下角
7ec8db2 feat: 2D世界地图可视化替代桌面端占位图标
bae95bb feat: 增强结果显示 + 修复Windows编译 + UX优化
1080a47 feat: 3D地球 + 搜索UI + 数据库接入（初始提交）
```

### 本轮完成

| 类别 | 内容 |
|------|------|
| **桌面端可视化** | 2D 世界地图（CustomPaint 墨卡托投影）、9 大陆轮廓、经纬网格、脉冲标记动画 |
| **结果显示** | 从单一数值 → 6 项统计指标卡片（均值/中位数/CI95/CI75） |
| **UX** | 初始引导、加载状态、空数据提示、搜索计数、搜索按钮移至右下角 FAB |
| **Windows** | 修复编译（排除 `flutter_inappwebview_windows` NuGet 依赖）、静态 plugin_registrant |
| **Android** | 首次 APK 编译成功、去除 DEBUG 横幅、配置签名密钥、解决中文路径 Gradle 问题 |
| **代码质量** | flutter analyze 零问题、条件导入零开销平台切换 |

### 编译状态

```
✅ flutter build web       → build/web/
✅ flutter build windows   → build/windows/x64/runner/Debug/infiltration_app.exe
✅ flutter build apk       → build/app/outputs/flutter-apk/app-debug.apk (267MB)
🔲 flutter build apk --release  ← 需 ASCII 路径（中文路径 AOT 编码问题）
🔲 flutter build ios      ← 需 macOS + Xcode
```

---

## 🛠️ 开发命令

```bash
cd infiltration_app

# 编译
flutter build web                     # Web 版（Chrome 可直接打开）
flutter build windows --debug         # Windows 桌面版
flutter build apk --debug             # Android APK

# 运行
flutter run -d chrome                 # 浏览器运行（3D 地球）
flutter run -d windows                # 桌面运行（2D 地图 + 真实数据库）

# 代码检查
flutter analyze                       # 静态分析（当前：0 issues）
flutter clean && flutter pub get      # 清理 + 重装依赖
```

### Windows 桌面版特殊说明

`flutter_inappwebview_windows` 插件的 NuGet 依赖在部分环境失败。我们的桌面端用 `earth_view_desktop.dart`（2D 地图），不需要 WebView。解决方式：
- `windows/CMakeLists.txt`：手动管理插件列表，排除 inappwebview
- `windows/runner/CMakeLists.txt`：使用静态 `plugin_registrant.cc`
- `windows/flutter/plugin_registrant.{cc,h}`：仅注册 geolocator_windows

---

## 🚀 未来路线图

### 近期（1-2 周）
| 任务 | 说明 |
|------|------|
| **迁移到 ASCII 路径** | 将项目移到 `D:\projects\infiltration_app`，解除 release 编译限制 |
| **正式 APK 签名** | `flutter build apk --release` → 优化版 50MB 左右 |
| **GPS 真机测试** | 连接手机测试自动定位 → 匹配最近地区 → 显示当月数据 |
| **Shapefile 经纬度** | 解决 950/3614 地区坐标为 (0,0) 的问题 |

### 中期（1-2 月）
| 任务 | 说明 |
|------|------|
| **App 图标 + 启动屏** | 替换默认 Flutter 图标和启动白屏 |
| **上架应用商店** | 小米应用商店 / 华为应用市场 / Google Play |
| **iOS 适配** | 需要 Mac + Xcode + Apple Developer |
| **时间轴动画** 🎨 | 滑动时间轴时，地图上数值平滑变化，播放 1990-2024 趋势 |
| **热力图模式** 🎨 | 根据渗透系数值给地区着色（蓝=低，红=高），一眼看全球分布 |

### 远期（创意池）🎨
| 创意 | 描述 |
|------|------|
| **对比模式** | 选两个地区并排对比趋势图，一键生成对比报告 |
| **建筑类型过滤** | 住宅/办公/学校等不同建筑类型渗透系数不同，加筛选器 |
| **AI 摘要** | "北京冬季渗透系数通常比夏季低约 0.3，年均值 0.72……" |
| **分享卡片** | 生成精美图片（地区+数据+地图标记），一键分享微信/朋友圈 |
| **收藏夹** | 收藏常用地区，首页快捷访问 |
| **离线趋势推送** | 当季渗透系数较历史同期异常时，推送提醒 |
| **深色/浅色主题** | 自动跟随系统或手动切换 |
| **数据导出** | 将查询结果导出为 CSV/Excel，方便写论文引用 |
| **i18n 国际化** | 中英文切换，方便国际合作者使用 |
| **Web 部署** | 部署到 GitHub Pages / 校内服务器，无需安装直接用 |

---

## ⚠️ 已知问题

| 问题 | 影响 | 解决方案 |
|------|------|----------|
| 项目路径含中文 | Release APK 编译失败 | 迁移到 ASCII 路径 |
| C 盘仅 3.4GB | 无法安装 Android 模拟器 | USB 真机或清理磁盘 |
| 950 地区坐标缺失 | 地图标记偏差 | Shapefile 提取省级中心点 |
| Web 端无数据库 | 查询返回占位数据 | WASM SQLite 或服务端 API |

---

*最后更新: 2026-06-11 · Git HEAD: 9132b99*
