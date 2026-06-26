# 🌍 渗透系数查询系统 v1.1

> 基于 Flutter 的跨平台应用，查询全球建筑室内空气渗透系数。
>
> 数据：**3,614 地区 × 1990–2024 年月度 × 6 项统计指标**

---

## 📱 获取应用

### Android

下载 APK 安装（**需要重新编译 v1.1**）：

```bash
cd D:/SRT/infiltration_app
flutter build apk --release
```

输出：`build/app/outputs/flutter-apk/app-release.apk`

> ⚠️ 当前已安装的 APK 是 v1.0 版本，不含今天新增的分享卡片、i18n、趋势图等功能。
> 运行上述命令重新编译即可获得 v1.1。

### Web

```
https://otivvito.github.io/infiltration-app
```

> ⚠️ Web 版需要配合后端 API 才能显示真实数据。后端部署说明见下方。

### Windows

```bash
flutter run -d windows
```

---

## 🆕 v1.1 更新 (2026-06-26)

| 功能 | 说明 |
|------|------|
| 🌐 **Web 真数据** | Dart Shelf 后端 API + Render.com 部署，Web 端不再用占位数据 |
| 📤 **分享卡片** | 查询结果一键分享，生成精美图片卡片（Mobile）或文本（Web） |
| 🌏 **中英文双语** | AppBar 右上角 `中`/`EN` 按钮，即时切换全部 UI 语言 |
| 📈 **趋势折线图** | 查询地区后显示 1990-2024 年渗透系数变化趋势曲线 |
| 🔌 **开发插件** | 集成 Claude Code 3 个插件：Wingspan + dev-process-toolkit + Full Stack 2.0 |

---

## ✨ 全部功能

| 功能 | 说明 |
|------|------|
| 🔍 **搜索查询** | 252 国 → 3,614 地区 → 年月选择，6 项统计指标 |
| 🗺️ **3D/2D 地球** | Android 3D Three.js 地球，Windows 2D 墨卡托地图 |
| 📍 **GPS 定位** | 打开 App 自动定位，匹配最近地区，显示当地数据 |
| 🔥 **热力图** | 252 国气泡图，蓝→红 渐变，含时间轴（1990-2024） |
| ⏳ **时间轴** | 拖动滑块 + 播放动画，看 35 年全球变化 |
| ⚖️ **对比模式** | 两地区并排对比，色条 + 表格 + 差异箭头 |
| 📊 **数据洞察** | 全球排名、时间趋势、月度特征——纯本地计算 |
| 📈 **趋势折线图** | CustomPaint 手绘 1990-2024 趋势曲线 🆕 |
| 📤 **分享卡片** | 生成精美图片分享微信/朋友圈 🆕 |
| ⭐ **收藏夹** | 收藏常用地区，底部弹窗快速访问，左滑删除 |
| ℹ️ **科普页** | 右上角 (i) 按钮，解释渗透系数的建筑学意义 |
| 🌏 **中英文双语** | AppBar `中`/`EN` 一键切换 🆕 |
| 🎨 **自定义图标** | 地球+水滴主题，自适应图标（Android 8+） |

---

## 🏗️ 技术架构

```
lib/
├── main.dart                         # App 入口，状态管理
├── i18n/
│   └── strings.dart                  # 中英文翻译（InheritedWidget 传播）
├── services/
│   ├── region_service.dart           # 地区搜索与坐标
│   ├── database_helper_mobile.dart   # SQLite (sqflite + ffi)
│   ├── database_helper_web.dart      # HTTP API 调用（Web）🆕
│   ├── database_helper_stub.dart     # Web 存根（已废弃）
│   ├── location_service.dart         # GPS + Haversine 最近地区
│   ├── heatmap_service.dart          # 热力图：国家聚合 + log 缩放
│   ├── insight_service.dart          # 数据洞察：排名/趋势/月度/趋势序列
│   └── favorites_service.dart        # 收藏夹 JSON 持久化
├── ui/
│   ├── search_dialog.dart            # 搜索 → 国家 → 地区 → 年月
│   ├── compare_page.dart             # 两地区并排对比
│   ├── info_page.dart                # 渗透系数科普
│   ├── share_card.dart               # 分享卡片（Mobile：图片 + 系统分享）🆕
│   ├── share_card_stub.dart          # 分享卡片（Web：纯文本）🆕
│   └── trend_chart.dart              # 趋势折线图（CustomPaint 手绘）🆕
├── painters/
│   └── world_map_painter.dart        # 墨卡托投影 + Picture 预渲染
└── data/
    └── world_outlines.dart           # 大洲轮廓坐标

backend/                              # 🆕 Dart Shelf REST API
├── bin/server.dart                   # 入口，监听 $PORT
├── lib/database.dart                 # SQLite 数据访问层
├── lib/routes.dart                   # 6 个 API 端点 + CORS
└── pubspec.yaml
```

---

## 🚀 Web 后端部署

### 部署到 Render.com

1. 将仓库推送到 GitHub（`render.yaml` 自动识别）
2. Render.com Dashboard → New Web Service → 连接仓库
3. 设置环境变量 `INFILTRATION_DB_PATH=/data/infiltration.db`
4. 部署完成后获得 API URL（如 `https://infiltration-api.onrender.com`）

### 构建 Web 前端

```bash
flutter build web --dart-define=API_BASE_URL=https://infiltration-api.onrender.com
```

### 本地开发

```bash
# 启动后端（需要 infiltration.db 在 assets/ 目录）
cd backend && dart run bin/server.dart

# 启动 Web 前端（连接本地 API）
cd .. && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

---

## 🛠️ 开发命令

```bash
# 项目路径
cd D:/SRT/infiltration_app

# 编译
flutter build apk --release            # Android Release APK
flutter build apk --debug              # Android Debug APK
flutter build web --dart-define=API_BASE_URL=https://YOUR_API_URL  # Web 版
flutter build windows --debug          # Windows 桌面版

# 运行
flutter run -d chrome                  # 浏览器（3D 地球）
flutter run -d windows                 # 桌面（2D 地图 + 真数据）

# 代码检查
dart analyze lib/                      # 前端静态分析
dart analyze backend/                  # 后端静态分析

# 后端本地启动
cd backend && dart run bin/server.dart
```

---

## 📋 开发记录

### v1.1 (2026-06-26)
- ✅ Web 真数据：Dart Shelf 后端 + 6 个 REST API 端点
- ✅ Web HTTP 数据源：database_helper_web.dart + LRU 缓存
- ✅ Docker 部署配置 + Render.com Blueprint
- ✅ 分享卡片：RepaintBoundary 截图 + share_plus 系统分享
- ✅ i18n 中英文双语：Strings 类 + InheritedWidget + 8 文件翻译
- ✅ 趋势折线图：CustomPaint 贝塞尔曲线，零新增依赖
- ✅ Claude Code 开发插件安装（Wingspan + dev-process-toolkit + Full Stack 2.0）
- ✅ 条件导入全面适配（6 个文件 Web/Mobile 双通道）

### v1.0 (2026-06-10 ~ 06-13)
- ✅ 3D 地球（Three.js）+ 2D 地图（CustomPaint 墨卡托）
- ✅ 搜索 UI（252 国 → 3,614 地区 → 年月 + 计数）
- ✅ 6 项统计指标（均值/中位数/CI95/CI75）
- ✅ 平台自适应（Web / Android / Windows）
- ✅ Release 签名（upload-keystore.jks）
- ✅ 坐标数据 100% 覆盖（3,614/3,614 非零坐标）
- ✅ GPS 自动定位（三级降级策略）
- ✅ 热力图（252 国气泡 + 时间轴 1990-2024 + 播放动画）
- ✅ 对比模式 + 数据洞察 + 收藏夹 + 科普说明页
- ✅ 自定义应用图标 + 8 个历史版本备份

---

## ⚠️ 已知限制

| 问题 | 影响 | 方案 |
|------|------|------|
| Web 端需后端 API | 需先部署后端才有真数据 | Render.com 免费部署 |
| iOS 未编译 | 仅 Android/Windows/Web 可用 | Codemagic CI 或本地 macOS |
| GitHub Pages 偶有网络问题 | 推送不稳定 | 换 Gitee Pages 或自有服务器 |
| GitHub 推送需网络畅通 | 偶尔 Connection reset | 重试或使用代理 |

---

## 📂 版本备份

共 8 个历史版本，位于 `versions/` 目录（v1.0 时代）。

---

*最后更新：2026-06-26 · 仓库：https://github.com/otivvito/infiltration-app*
