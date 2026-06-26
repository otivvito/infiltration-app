import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/region_service.dart';

/// 搜索结果：地区 + 年月
class SearchResult {
  final Region region;
  final int year;
  final int month;

  const SearchResult({
    required this.region,
    required this.year,
    required this.month,
  });
}

/// 全屏搜索对话框：国家 → 地区 → 年月选择
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final RegionService _service = RegionService();
  final ScrollController _yearScrollController = ScrollController();
  final ScrollController _countryScrollController = ScrollController();

  // Step: 0=country list, 1=region list, 2=time picker
  int _step = 0;
  String? _selectedCountry;
  Region? _selectedRegion;
  int _selectedYear = 2020;
  int _selectedMonth = 6;

  String _searchQuery = '';
  List<Region> _searchResults = [];

  static List<String> _months(BuildContext context) {
    final s = Strings.of(context);
    final en = s.locale == AppLocale.en;
    return List.generate(12, (i) => en ? '${i + 1}' : '${i + 1}月');
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    _countryScrollController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(_step == 2 ? Strings.of(context).selectTime : Strings.of(context).selectRegion),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildCountryList();
      case 1:
        return _buildRegionList();
      case 2:
        return _buildTimePicker();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- 步骤 0：搜索 + 国家列表 ----
  Widget _buildCountryList() {
    final countries = _service.countries;

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: Strings.of(context).searchHint,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (q) {
              setState(() {
                _searchQuery = q;
                _searchResults = _service.search(q);
              });
            },
          ),
        ),

        // 搜索结果提示
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _searchResults.isEmpty
                  ? Strings.of(context).noMatch
                  : Strings.of(context).foundCount(_searchResults.length),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

        // 搜索结果或国家列表
        Expanded(
          child: _searchQuery.isNotEmpty
              ? (_searchResults.isEmpty
                  ? Center(
                      child: Text(Strings.of(context).searchPrompt(_searchQuery),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) {
                        final r = _searchResults[i];
                        return ListTile(
                          title: Text(r.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(r.country, style: const TextStyle(color: Colors.grey)),
                          onTap: () => _selectRegion(r),
                        );
                      },
                    ))
              : ListView.builder(
                  controller: _countryScrollController,
                  itemCount: countries.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(Strings.of(context).countryCount(_service.countries.length),
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      );
                    }
                    final idx = i - 1;
                    final c = countries[idx];
                    final count = _service.regionsForCountry(c).length;
                    return ListTile(
                      title: Text(c, style: const TextStyle(color: Colors.white)),
                      trailing: Text(Strings.of(context).regionCount(count),
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      onTap: () {
                        setState(() {
                          _selectedCountry = c;
                          _step = 1;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---- 步骤 1：地区列表 ----
  Widget _buildRegionList() {
    if (_selectedCountry == null) return const SizedBox.shrink();
    final regions = _service.regionsForCountry(_selectedCountry!);

    return Column(
      children: [
        // 面包屑
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          color: Colors.grey[900],
          child: Text(
            _selectedCountry!,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: regions.length,
            itemBuilder: (ctx, i) {
                final r = regions[i];
                return ListTile(
                  title: Text(r.name, style: const TextStyle(color: Colors.white)),
                  onTap: () => _selectRegion(r),
                );
              },
            ),
          ),
      ],
    );
  }

  void _selectRegion(Region r) {
    setState(() {
      _selectedRegion = r;
      _step = 2;
    });
  }

  // ---- 步骤 2：年月选择 ----
  Widget _buildTimePicker() {
    return Column(
      children: [
        // 可滚动的上部内容
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 已选地区
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedRegion?.name ?? '',
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedRegion?.country ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 年份选择（←→ 箭头 + 拖拽 + Shift滚轮）
              Text(Strings.of(context).year, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 左箭头
                  GestureDetector(
                    onTap: () {
                      if (_selectedYear > 1990) {
                        setState(() => _selectedYear--);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 可滚动年份列表
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Scrollbar(
                        controller: _yearScrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: _yearScrollController,
                          scrollDirection: Axis.horizontal,
                          children: List.generate(35, (i) {
                            final y = 1990 + i;
                            final selected = y == _selectedYear;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedYear = y),
                              child: Container(
                                width: 56,
                                height: 40,
                                margin: const EdgeInsets.only(right: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? Colors.blue : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$y',
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.grey,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 右箭头
                  GestureDetector(
                    onTap: () {
                      if (_selectedYear < 2024) {
                        setState(() => _selectedYear++);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 月份选择
              Text(Strings.of(context).month, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final selected = m == _selectedMonth;
                  final months = _months(context);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMonth = m),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.blue : Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        months[i],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // 给底部按钮留空间
              const SizedBox(height: 80),
            ],
          ),
        ),

        // 底部固定查询按钮
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.78),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedRegion == null) return;
                Navigator.pop(
                  context,
                  SearchResult(
                    region: _selectedRegion!,
                    year: _selectedYear,
                    month: _selectedMonth,
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: Text(Strings.of(context).appTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
