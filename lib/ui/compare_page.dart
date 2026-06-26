import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/database_helper_mobile.dart'
    if (dart.library.html) '../services/database_helper_web.dart';
import '../services/region_service.dart';
import 'search_dialog.dart';

/// 两地区对比页面
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Region? _regionA;
  Region? _regionB;
  int _yearA = 2024, _monthA = 12;
  int _yearB = 2024, _monthB = 12;
  InfiltrationRecord? _recordA;
  InfiltrationRecord? _recordB;
  bool _loading = false;

  Future<void> _selectRegion(bool isA) async {
    final result = await Navigator.push<SearchResult>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SearchDialog()),
    );
    if (result == null) return;

    setState(() {
      if (isA) {
        _regionA = result.region;
        _yearA = result.year;
        _monthA = result.month;
      } else {
        _regionB = result.region;
        _yearB = result.year;
        _monthB = result.month;
      }
    });

    if (_regionA != null && _regionB != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_regionA == null || _regionB == null) return;
    setState(() => _loading = true);

    final db = DatabaseHelper.instance;
    final results = await Future.wait([
      db.query(_regionA!.id, _yearA, _monthA),
      db.query(_regionB!.id, _yearB, _monthB),
    ]);

    if (mounted) {
      setState(() {
        // 没有真实数据的记录置为 null，不显示假零值
        _recordA = (results[0] != null && results[0]!.hasData) ? results[0] : null;
        _recordB = (results[1] != null && results[1]!.hasData) ? results[1] : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(Strings.of(context).compareTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 地区选择行
            Row(
              children: [
                Expanded(child: _buildSelector(true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('VS', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: _buildSelector(false)),
              ],
            ),
            const SizedBox(height: 20),
            // 数据对比
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_regionA != null && _regionB != null && (_recordA == null || _recordB == null))
              _buildNoData()
            else if (_recordA != null && _recordB != null)
              _buildComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(bool isA) {
    final region = isA ? _regionA : _regionB;
    final timeStr = isA ? '$_yearA年$_monthA月' : '$_yearB年$_monthB月';

    return GestureDetector(
      onTap: () => _selectRegion(isA),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isA ? Colors.blue : Colors.orange, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              region?.displayName ?? Strings.of(context).compareSelect,
              style: TextStyle(
                color: region != null ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (region != null) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoData() {
    final missing = <String>[];
    if (_recordA == null) missing.add(_regionA!.displayName);
    if (_recordB == null) missing.add(_regionB!.displayName);
    return Center(
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('${missing.join(', ')} ${Strings.of(context).noData}',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(Strings.of(context).tryOtherTime,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    return Column(
      children: [
        // 均值对比条
        _buildBar('均值', _recordA!.mean, _recordB!.mean),
        const SizedBox(height: 12),
        _buildBar('中位数', _recordA!.median, _recordB!.median),
        const SizedBox(height: 12),
        _buildBar('95% CI 下限', _recordA!.ci95Low, _recordB!.ci95Low),
        const SizedBox(height: 8),
        _buildBar('95% CI 上限', _recordA!.ci95High, _recordB!.ci95High),
        const SizedBox(height: 12),
        _buildBar('75% CI 下限', _recordA!.ci75Low, _recordB!.ci75Low),
        const SizedBox(height: 8),
        _buildBar('75% CI 上限', _recordA!.ci75High, _recordB!.ci75High),
        const SizedBox(height: 16),
        // 详细数值表
        _buildDetailTable(),
      ],
    );
  }

  Widget _buildBar(String label, double? a, double? b) {
    final va = a ?? 0;
    final vb = b ?? 0;
    final maxV = va > vb ? va : vb;
    final total = maxV == 0 ? 1.0 : maxV;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(va.toStringAsFixed(6),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (va / total).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Text('VS', style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vb.toStringAsFixed(6),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (vb / total).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailTable() {
    final a = _recordA!;
    final b = _recordB!;
    final s = Strings.of(context);
    final rows = [
      (s.meanLabel, a.mean, b.mean),
      (s.medianLabel, a.median, b.median),
      ('95% CI ${s.lowerBound}', a.ci95Low, b.ci95Low),
      ('95% CI ${s.upperBound}', a.ci95High, b.ci95High),
      ('75% CI ${s.lowerBound}', a.ci75Low, b.ci75Low),
      ('75% CI ${s.upperBound}', a.ci75High, b.ci75High),
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey[800]!, width: 0.5),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3), 2: FlexColumnWidth(3)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[900]),
          children: [
            Padding(padding: EdgeInsets.all(8), child: Text(Strings.of(context).indicator, style: TextStyle(color: Colors.grey, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text(Strings.of(context).regionA, style: TextStyle(color: Colors.blue, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text(Strings.of(context).regionB, style: TextStyle(color: Colors.orange, fontSize: 12))),
          ],
        ),
        ...rows.map((r) {
          final diff = (r.$2 != null && r.$3 != null) ? (r.$2! - r.$3!).abs() : null;
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(r.$1, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(r.$2?.toStringAsFixed(6) ?? '—',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(r.$3?.toStringAsFixed(6) ?? '—',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                    if (diff != null && diff > 0.000001) ...[
                      const SizedBox(width: 4),
                      Icon(r.$2! > r.$3! ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 14, color: r.$2! > r.$3! ? Colors.blue : Colors.orange),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
