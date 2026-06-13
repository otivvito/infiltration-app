# 🌍 渗透系数查询系统

> 基于 Flutter 的跨平台应用，查询全球建筑室内空气渗透系数。
>
> 数据：**3,614 地区 × 1990–2024 年月度 × 6 项统计指标**

---

## 📱 安装

### Android

下载 APK 安装：
- **Release**（推荐）：`build/app/outputs/flutter-apk/app-release.apk`（149MB）
- **Debug**：`build/app/outputs/flutter-apk/app-debug.apk`（267MB）

### Web

```
https://otivvito.github.io/infiltration-app
```

> ⚠️ Web 版使用占位数据（SQLite 不支持浏览器），完整数据需 Android/Windows 版。

### Windows

```bash
flutter run -d windows
```

### iOS

需要 macOS + Xcode。推荐使用 Codemagic CI 云端构建。

---

## ✨ 功能

| 功能 | 说明 |
|------|------|
| 🔍 **搜索查询** | 252 国 → 3,614 地区 → 年月选择，6 项统计指标 |
| 🗺️ **3D/2D 地球** | Android 3D Three.js 地球，Windows 2D 墨卡托地图 |
| 📍 **GPS 定位** | 打开 App 自动定位，匹配最近地区，显示当地数据 |
| 🔥 **热力图** | 252 国气泡图，蓝→红 渐变，含时间轴（1990-2024） |
| ⏳ **时间轴** | 拖动滑块 + 播放动画，看 35 年全球变化 |
| ⚖️ **对比模式** | 两地区并排对比，色条 + 表格 + 差异箭头 |
| 📊 **数据洞察** | 全球排名、时间趋势、月度特征——纯本地计算 |
| ⭐ **收藏夹** | 收藏常用地区，底部弹窗快速访问，左滑删除 |
| ℹ️ **科普页** | 右上角 (i) 按钮，解释渗透系数的建筑学意义 |
| 🎨 **自定义图标** | 地球+水滴主题，自适应图标（Android 8+） |

---

## 🏗️ 技术架构

```
lib/
├── main.dart                         # App 入口，状态管理
├── earth_view_web.dart               # Web : IFrameElement + Three.js
├── earth_view_mobile.dart            # Android : InAppWebView + 3D 地球
├── earth_view_desktop.dart           # Windows : 2D CustomPaint 地图
├── earth_view_native.dart            # 平台路由（条件导出）
├── services/
│   ├── region_service.dart           # 地区搜索与坐标
│   ├── database_helper_mobile.dart   # SQLite (sqflite + ffi)
│   ├── database_helper_stub.dart     # Web 存根
│   ├── location_service.dart         # GPS + Haversine 最近地区
│   ├── heatmap_service.dart          # 热力图：国家聚合 + log 缩放
│   ├── insight_service.dart          # 数据洞察：排名/趋势/月度
│   └── favorites_service.dart        # 收藏夹 JSON 持久化
├── ui/
│   ├── search_dialog.dart            # 搜索 → 国家 → 地区 → 年月
│   ├── compare_page.dart             # 两地区并排对比
│   └── info_page.dart                # 渗透系数科普
├── painters/
│   └── world_map_painter.dart        # 墨卡托投影 + Picture 预渲染
└── data/
    └── world_outlines.dart           # 大洲轮廓坐标
```

**平台自适应：**
```
main.dart
  ├─ Web     → earth_view_web       (3D Three.js + HTML overlay)
  └─ Native  → earth_view_native
                 ├─ Android/iOS  → earth_view_mobile   (WebView 3D)
                 └─ Desktop      → earth_view_desktop  (CustomPaint 2D)
```

---

## 📋 开发记录（2026-06-10 ~ 06-13）

### 基础架构
- ✅ 3D 地球（Three.js）+ 2D 地图（CustomPaint 墨卡托）
- ✅ 搜索 UI（252 国 → 3,614 地区 → 年月 + 计数）
- ✅ 6 项统计指标（均值/中位数/CI95/CI75）
- ✅ 平台自适应（Web / Android / Windows）
- ✅ Release 签名（upload-keystore.jks）
- ✅ 项目迁移至 ASCII 路径 `D:\SRT\infiltration_app`
- ✅ Debug + Release APK 编译成功

### 坐标数据
- ✅ 950 → 0 个 (0,0) 坐标（Open-Meteo + 手动修正 16 国）
- ✅ 中美 84 省/州真实坐标（手工录入）
- ✅ 1,498 个全球子地区精确坐标（Open-Meteo API 批量）
- ✅ 总计 1,582/3,614 个地区有真实坐标

### 功能特性
- ✅ GPS 自动定位（三级降级策略：缓存→低精度超时→提示）
- ✅ 热力图（252 国气泡 + 时间轴 1990-2024 + 播放动画）
- ✅ 对比模式（两地区并排 + 色条 + 表格 + 箭头）
- ✅ 数据洞察（全球排名、时间趋势、月度特征，纯本地计算）
- ✅ 收藏夹（☆ 切换收藏、底部弹窗列表、左滑删除）
- ✅ 科普说明页（右上角 i 按钮）
- ✅ 自定义应用图标（地球+水滴主题）
- ✅ 版本备份机制（versions/ 文件夹，7 个历史版本）

### Web 部署
- ✅ Web 编译成功（`flutter build web`）
- ✅ GitHub Pages 部署（`otivvito.github.io/infiltration-app`）
- ⚠️ base href 偶有网络问题，需手动修复

---

## 🛠️ 开发命令

```bash
# 项目路径
cd D:/SRT/infiltration_app

# 编译
flutter build apk --release            # Android Release APK (149MB)
flutter build apk --debug              # Android Debug APK (267MB)
flutter build web --base-href "//infiltration-app/"   # Web 版
flutter build windows --debug          # Windows 桌面版

# 运行
flutter run -d chrome                  # 浏览器（3D 地球）
flutter run -d windows                 # 桌面（2D 地图 + 真数据）

# 代码检查
dart analyze lib/                       # 静态分析
```

---

## 🚀 下一步

| 优先级 | 任务 | 说明 |
|:--:|------|------|
| 🔴 | **iOS 编译** | 需 macOS + Xcode，或 Codemagic CI |
| 🔴 | **Web 数据** | Web 端用占位数据，需后端 API 或 WASM SQLite |
| 🟡 | **剩余坐标** | ~2,000 个子地区仍用质心+微抖动 |
| 🟡 | **分享卡片** | 生成精美图片分享微信/朋友圈 |
| 🟢 | **i18n 国际化** | 中英文双语切换 |
| 🟢 | **时间轴增强** | 地区详情页加趋势折线图 |
| 🟢 | **上架商店** | 小米/华为/Google Play（需开发者账号） |

---

## ⚠️ 已知限制

| 问题 | 影响 | 方案 |
|------|------|------|
| Web 端无数据库 | 查询返回占位数据 | WASM SQLite 或后端 API |
| iOS 未编译 | 仅 Android 可用 | Codemagic CI |
| 部分子地区坐标近似 | 约 2,000 个用国家质心 | 继续扩充 geocode_progress.json |
| GitHub Pages 偶有网络问题 | 推送不稳定 | 换 Gitee Pages 或自有服务器 |

---

## 📂 版本备份

共 8 个历史版本，位于 `versions/` 目录：

| 版本 | 日期 | 里程碑 |
|------|------|------|
| v2026-06-10_初始版本 | 06-10 | 初始完成版 |
| v2026-06-11_坐标修复版 | 06-11 | 重复卡片修复 + 坐标 100% |
| v2026-06-11_GPS前备份 | 06-11 | GPS 开发前 |
| v2026-06-11_GPS完成版 | 06-11 | GPS 自动定位 |
| v2026-06-11_Release版 | 06-11 | Release 签名 + 英文路径 |
| v2026-06-11_国家气泡版 | 06-11 | 热力图 + 时间轴 |
| v2026-06-11_对比模式版 | 06-11 | 对比 + 洞察 + 科普 |
| v2026-06-11_时间轴版 | 06-11 | 时间轴播放 |
| v2026-06-11_科普修正版 | 06-11 | 科普内容修正为建筑领域 |

---

*最后更新：2026-06-13 · 仓库：https://github.com/otivvito/infiltration-app*
