import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Repo + model for real SQLite-backed data
import 'package:pos_system/data/models/manager/reports/trending_item_report.dart';
import 'package:pos_system/data/repositories/manager/reports/trending_items_repository.dart';

class TrendingItemsReportPage extends StatefulWidget {
  const TrendingItemsReportPage({super.key});

  @override
  State<TrendingItemsReportPage> createState() => _TrendingItemsReportPageState();
}

class _TrendingItemsReportPageState extends State<TrendingItemsReportPage> {
  // UI state
  String selectedPeriod = 'Last 7 Days';
  String selectedSortBy = 'Quantity Sold';
  int selectedIndex = 0; // 0: Top Products, 1: By Category, 2: Growth Leaders

  final List<String> periods = const [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
  ];

  final List<String> sortOptions = const [
    'Quantity Sold',
    'Revenue',
    'Growth Rate',
    'Profit Margin',
  ];

  // Data state
  bool _loading = false;
  String? _error;
  List<TrendingItemReport> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  (DateTime, DateTime) _rangeForPeriod(DateTime now, String periodLabel) {
    // end = now (exclusive), start depends on the period
    final DateTime to = now;
    DateTime from;

    DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

    switch (periodLabel) {
      case 'Last 7 Days':
        from = to.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        from = to.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        from = DateTime(to.year, to.month - 3, to.day);
        break;
      case 'Last 6 Months':
        from = DateTime(to.year, to.month - 6, to.day);
        break;
      case 'This Year':
        from = DateTime(to.year, 1, 1);
        break;
      default:
        from = to.subtract(const Duration(days: 7));
    }
    // Normalize to start of day for nicer boundaries
    return (startOfDay(from), to);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // If the user taps the "Growth Leaders" tab, force-sort by growth
      final effectiveSort = (selectedIndex == 2) ? 'Growth Rate' : selectedSortBy;

      final now = DateTime.now();
      final fromTo = _rangeForPeriod(now, selectedPeriod);

      final data = await TrendingItemsRepository.instance.fetch(
        fromMs: fromTo.$1.millisecondsSinceEpoch,
        toMs: fromTo.$2.millisecondsSinceEpoch,
        sortBy: sortByFromLabel(effectiveSort),
        limit: 100,
      );

      setState(() {
        _rows = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Derived metrics
  // ---------------------------------------------------------------------------

  int get _totalQty => _rows.fold<int>(0, (s, r) => s + r.quantitySold);
  double get _totalRevenue => _rows.fold<double>(0, (s, r) => s + r.revenue);
  double get _avgGrowth {
    final vals = _rows.map((e) => e.growthRate).whereType<double>().toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
    // NOTE: Per-item growth is revenue vs prev period. This is a *simple mean*.
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reports • Trending Items'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.zero,
          child: Container(height: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildStatsOverview(),
          Expanded(child: _buildMainPane()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Period',
                  value: selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedPeriod = value);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Sort By',
                  value: selectedSortBy,
                  items: sortOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedSortBy = value);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Top Products', 'By Category', 'Growth Leaders'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                  // If user taps "Growth Leaders", force growth sort to match the tab.
                  if (selectedIndex == 2) selectedSortBy = 'Growth Rate';
                });
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalQty = _totalQty;
    final totalRev = _totalRevenue;
    final avgGrowth = _avgGrowth;

    String _fmtCurrency(double v) {
      // simple USD formatting (change as needed)
      return '\$${v.toStringAsFixed(0)}';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Items Sold',
              value: totalQty.toString(),
              change: '${avgGrowth >= 0 ? '+' : ''}${avgGrowth.toStringAsFixed(1)}%',
              isPositive: avgGrowth >= 0,
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Revenue Generated',
              value: _fmtCurrency(totalRev),
              change: '${avgGrowth >= 0 ? '+' : ''}${avgGrowth.toStringAsFixed(1)}%',
              isPositive: avgGrowth >= 0,
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Avg. Growth',
              value: '${avgGrowth.toStringAsFixed(1)}%',
              change: avgGrowth >= 0 ? '+0.0%' : '-0.0%', // cosmetic
              isPositive: avgGrowth >= 0,
              icon: Icons.show_chart,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPane() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Failed to load data:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text('No data for the selected period'),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedIndex == 1 ? 'Trending Categories' : 'Trending Products',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
                ),
              ],
            ),
          ),

          // content
          if (selectedIndex == 1)
            Expanded(child: _buildCategoryList())
          else
            Expanded(child: _buildProductList()),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Product list ----------------------------------------------------------

  Widget _buildProductList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _buildItemTile(_rows[i]),
    );
  }

  Widget _buildItemTile(TrendingItemReport r) {
    final emoji = _emojiForCategory(r.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.category,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${r.rank}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.quantitySold} sold',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${r.revenue.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                (r.growthRate ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                color: (r.growthRate ?? 0) >= 0 ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                '${(r.growthRate ?? 0).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: (r.growthRate ?? 0) >= 0 ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Category list (simple aggregation for tab 1) --------------------------

  Widget _buildCategoryList() {
    // Aggregate by category
    final Map<String, _CatAgg> agg = {};
    for (final r in _rows) {
      final a = agg.putIfAbsent(r.category, () => _CatAgg());
      a.qty += r.quantitySold;
      a.rev += r.revenue;
      if (r.growthRate != null) {
        a.grCount++;
        a.growthSum += r.growthRate!;
      }
    }
    // To list & sort by revenue desc
    final list = agg.entries
        .map((e) => _CatRow(
              category: e.key,
              qty: e.value.qty,
              revenue: e.value.rev,
              avgGrowth: e.value.grCount == 0 ? 0 : e.value.growthSum / e.value.grCount,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = list[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(_emojiForCategory(c.category))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${c.qty} sold', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('\$${c.revenue.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Icon(c.avgGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: c.avgGrowth >= 0 ? Colors.green : Colors.red, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    '${c.avgGrowth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: c.avgGrowth >= 0 ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Future<void> _exportCsv() async {
    final buf = StringBuffer()
      ..writeln('Rank,Item,Category,Quantity Sold,Revenue,Growth %,Profit Margin %');

    for (final r in _rows) {
      buf.writeln(
          '${r.rank},"${r.name.replaceAll('"', '""')}",${r.category.replaceAll(',', ' ')},${r.quantitySold},${r.revenue.toStringAsFixed(2)},${(r.growthRate ?? 0).toStringAsFixed(2)},${(r.profitMargin ?? 0).toStringAsFixed(2)}');
    }

    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  String _emojiForCategory(String c) {
    final key = c.toLowerCase();
    if (key.contains('beverage') || key.contains('drink')) return '🥤';
    if (key.contains('snack')) return '🥨';
    if (key.contains('dairy')) return '🥛';
    if (key.contains('frozen') || key.contains('ice')) return '🧊';
    if (key.contains('produce') || key.contains('fruit') || key.contains('veg')) return '🥦';
    if (key.contains('household')) return '🧼';
    if (key.contains('personal') || key.contains('care')) return '🧴';
    if (key.contains('stationery')) return '📄';
    return '📦';
  }
}

// Simple category aggregation structs
class _CatAgg {
  int qty = 0;
  double rev = 0;
  double growthSum = 0;
  int grCount = 0;
}

class _CatRow {
  final String category;
  final int qty;
  final double revenue;
  final double avgGrowth;
  _CatRow({
    required this.category,
    required this.qty,
    required this.revenue,
    required this.avgGrowth,
  });
}
