import 'package:flutter/material.dart';

import '../i18n/strings.dart';

/// Infiltration coefficient info page (i18n-aware).
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final en = s.locale == AppLocale.en;

    // English bullet points (split by line) or Chinese bullets
    final whyImportantBullets = en
        ? _parseBullets(s.infoWhyImportantBody)
        : const [
            '建筑能耗：空气渗透造成的热量损失可占建筑总能耗的 30%-50%，是供暖和制冷负荷的主要来源之一',
            '室内空气质量：室外 PM2.5、臭氧、花粉等污染物通过渗透进入室内，影响呼吸健康',
            '热舒适性：不受控制的空气渗透导致冷风侵入、温度分布不均，降低居住舒适度',
            '湿气与霉菌：空气渗透携带的水汽可能在墙体内部凝结，导致结构损坏和霉菌滋生',
            'HVAC 系统设计：准确的渗透系数是暖通空调系统选型和能耗模拟的基础输入',
            '建筑节能标准：各国建筑规范对气密性有明确要求（如 Passivhaus 标准要求 n50 ≤ 0.6 ACH），渗透系数是合规性评估的核心指标',
          ];

    final provideBullets = en
        ? _parseBullets(s.infoWhatWeProvideBody)
        : const [
            '查询任意地区的 6 项统计指标（均值、中位数、95%/75% 置信区间）',
            '查看全球热力图，了解渗透系数的地理分布（寒冷地区 vs 温暖地区差异显著）',
            '拖动时间轴观察 1990-2024 年建筑气密性的变化趋势',
            '并排对比两个地区的数据差异',
            '获取智能数据洞察（全球排名、趋势方向、季节性特征）',
            'GPS 自动定位，快速查看您所在地区的空气渗透系数',
          ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(s.aboutTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(s.infoWhatIs, s.infoWhatIsBody, context: context),
            const SizedBox(height: 20),
            _buildSection(
              s.infoWhyImportant,
              en ? '' : '空气渗透直接影响建筑能耗、室内环境质量和人体健康：',
              bullets: whyImportantBullets,
              context: context,
            ),
            const SizedBox(height: 20),
            _buildSection(
              s.infoWhatWeProvide,
              en ? '' : '基于全球 3,614 个地区 1990-2024 年的月度空气渗透系数数据，您可以：',
              bullets: provideBullets,
              context: context,
            ),
            const SizedBox(height: 20),
            _buildSection(s.infoDataNotes, s.infoDataNotesBody, context: context),
            const SizedBox(height: 30),
            Center(
              child: Text(
                s.version,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Parse bullet points from a string with `\n• ` or `\n- ` markers.
  static List<String> _parseBullets(String body) {
    final lines = body.split('\n');
    final bullets = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('• ') || trimmed.startsWith('- ')) {
        bullets.add(trimmed.substring(2));
      } else if (trimmed.isNotEmpty) {
        bullets.add(trimmed);
      }
    }
    return bullets;
  }

  Widget _buildSection(String title, String body, {List<String>? bullets, BuildContext? context}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withValues(alpha: 0.59),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (body.isNotEmpty)
            Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
          if (bullets != null) ...[
            const SizedBox(height: 4),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.cyan, fontSize: 13)),
                      Expanded(child: Text(b, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
