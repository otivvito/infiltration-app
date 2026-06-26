---
name: share-card-feature-2026-06-26
description: 分享卡片功能 — 生成精美图片分享微信/朋友圈
metadata:
  type: project
---

# 分享卡片功能 (2026-06-26)

**Why:** 用户查询渗透系数后需要分享到微信/朋友圈，需要生成包含数据的美观图片卡片。

**How to apply:** 查询结果卡片右上角有分享按钮（↗），点击后自动生成图片 → 打开系统分享菜单。

## 实现方案
- Mobile (Android/iOS): `RepaintBoundary.toImage()` → PNG → `SharePlus.instance.share()` 分享图片
- Web: 分享纯文本（`dart:io` 不可用，无法写文件）
- 卡片设计：深蓝渐变背景 + 地球图标 + 地区名 + 大字均值 + 中位数/CI 副指标

## 文件
- `lib/ui/share_card.dart` — 图片卡片 Widget + 截图 + 分享逻辑
- `lib/ui/share_card_stub.dart` — Web 文本分享
- `lib/main.dart` — 条件导入 + 分享按钮
- `pubspec.yaml` — +share_plus
