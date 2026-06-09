# 🌍 全球渗透系数查询 App

> 基于 Flutter + Three.js 的跨平台移动应用，用 3D 地球可视化全球建筑室内渗透系数数据。

---

## 📋 项目概述

将手头已有的全球渗透系数数据集（3614 个地区 × 1990–2024 年月度数据 × 6 个统计指标）制作成一款易用的手机 App。通过 3D 地球选择任意地区和时间，查询渗透系数。

**技术栈**: Flutter + Three.js (WebView) + SQLite

---

## 🚀 已完成工作

### 阶段一：数据预处理 ✅
- Python 脚本将 103MB Excel → SQLite 数据库
- 生成 `infiltration.db`：2 张表、3614 个地区、151 万条数据
- 提取 `regions.json`（国家-地区层级，133KB）
- 生成 `region_coords.json`（3614 个地区近似经纬度，295KB）

### 阶段二：3D 地球原型 ✅
- Three.js 可交互 3D 地球 (`assets/earth.html`)
- 支持拖拽旋转、缩放、自动旋转
- `rotateTo(lat, lon, name, value)` 全局函数
- 定位后自动停止自转，相机飞到目标正前方
- 恢复旋转按钮（🔄）

### 阶段三：Flutter App 框架 ✅
- **平台自适应**：Web 用 `IFrameElement`，移动端用 `flutter_inappwebview`
- 条件导入实现零开销平台切换
- **搜索功能**：
  - 国家列表（252 国，支持搜索过滤）
  - 地区列表（3614 个地区）
  - 年月选择（1990–2024，←→ 箭头 + 拖拽 + Shift+滚轮）
- **HTML 控件层**（Web 端）：
  - 📍 定位按钮 | 📊 底部结果卡片 | 🔍 搜索按钮
  - 搜索时自动隐藏，避免遮挡

---

## 📁 项目结构

```
infiltration_app/
├── lib/
│   ├── main.dart                  # App 入口，搜索与地球联动
│   ├── earth_view_web.dart        # Web 端：IFrameElement + HTML 控件
│   ├── earth_view_mobile.dart     # 移动端：flutter_inappwebview
│   ├── services/
│   │   └── region_service.dart    # 地区数据加载与搜索
│   └── ui/
│       └── search_dialog.dart     # 搜索对话框
├── assets/
│   ├── earth.html                 # Three.js 3D 地球
│   ├── earth_texture.jpg          # 地球纹理贴图
│   ├── infiltration.db            # SQLite 数据库 (164MB)
│   ├── regions.json               # 国家-地区层级
│   └── region_coords.json         # 地区经纬度
└── scripts/
    └── generate_coords.py         # 生成经纬度 JSON
```

---

## 🔜 待完成

### 高优先级
| 任务 | 说明 |
|------|------|
| **接入真实数据库** | 搜索返回真实 6 项统计指标（均值、中位数、置信区间） |
| **Web 端数据库方案** | `sqflite` 不支持 Web，需预提取或使用 WASM |
| **经纬度精确化** | 950 个地区无坐标，需 Shapefile 计算省级中心点 |

### 中优先级
| 任务 | 说明 |
|------|------|
| **GPS 自动定位** | 获取设备位置 → 匹配最近地区 → 显示当月数据 |
| **UI 美化** | 年份/月份选择器优化、粒子特效、动画过渡 |
| **移动端真机测试** | 当前仅在 Chrome 测试，需 Android/iOS 真机 |

---

## 🛠️ 开发命令

```bash
cd infiltration_app
flutter run -d chrome              # Web 运行
flutter run -d chrome --web-port=8080  # 指定端口
flutter analyze                    # 静态分析
flutter clean                      # 清理缓存
```

---

## 📝 关于 "context used"

Claude Code 的上下文窗口有上限。"91% used" 表示当前会话记忆即将用完，超出后较早对话会被压缩。Claude 仍可工作，但可能需要重新读文件来回顾。这份 README 也是为了让后续会话快速了解项目。

---

*最后更新: 2026-06-09*
