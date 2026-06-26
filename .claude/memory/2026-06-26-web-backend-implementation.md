---
name: web-backend-implementation-2026-06-26
description: Web 端真数据方案实施 — Dart Shelf 后端 + HTTP Web helper + 部署配置
metadata:
  type: project
---

# Web 端真数据方案实施 (2026-06-26)

**Why:** Web 端 `database_helper_stub.dart` 对所有查询返回 null，用户看到占位假数据。数据库 164MB，WASM 不现实，采用后端 API 方案。

**How to apply:** 部署后端到 Render.com 后，Web 端 `flutter build web --dart-define=API_BASE_URL=https://infiltration-api.onrender.com` 即可获得真实数据。

## 完成的变更

### 新建文件
- `backend/` — Dart Shelf REST API 服务器（pubspec.yaml, bin/server.dart, lib/database.dart, lib/routes.dart）
- `lib/services/database_helper_web.dart` — HTTP 调用的 DatabaseHelper + LRU 缓存
- `Dockerfile` — Dart 原生编译 + 容器化部署
- `render.yaml` — Render.com 蓝图配置

### 修改文件
- `lib/main.dart` — Web 条件导入从 stub 改为 web helper
- `lib/services/insight_service.dart` — 添加 Web 条件导入
- `lib/services/heatmap_service.dart` — 添加 Web 条件导入
- `lib/ui/compare_page.dart` — 添加 Web 条件导入
- `pubspec.yaml` — 添加 `http` 包依赖

### 下一步
- 将 `infiltration.db` 上传到服务器（或使用 Git LFS）
- 在 Render.com 连接仓库并部署
- 测试 Web 端真实数据查询
- 更新 `database_helper_stub.dart`（已无引用，可选删除）
