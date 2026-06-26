---
name: trend-chart-2026-06-26
description: 趋势折线图 — CustomPaint 手绘，查询后显示 1990-2024 年渗透系数变化趋势
metadata:
  type: project
---

# 趋势折线图 (2026-06-26)

**Why:** 查询结果只显示单月数值，用户看不到 35 年时间趋势。加上折线图让数据故事更完整。

**How to apply:** 查询某个地区后，结果卡片中会出现 📈 趋势图（需要至少 2 年数据）。

## 实现
- `lib/ui/trend_chart.dart` — CustomPaint 手绘：贝塞尔曲线 + 渐变填充 + 首尾数据点
- `lib/services/insight_service.dart` — 新增 `getTrendSeries()` 暴露完整年-值序列
- `lib/main.dart` — 异步加载趋势数据 + 卡片中渲染 TrendChart
- 零新增依赖（使用 Flutter 内置 CustomPaint）
