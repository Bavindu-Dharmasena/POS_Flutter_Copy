import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for ESC key
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/data/models/stockkeeper/insight/chart_series.dart';
import 'package:pos_system/data/models/stockkeeper/insight/top_selling_item.dart';
import 'package:pos_system/data/repositories/stockkeeper/insight/insight_repository.dart';

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  String selectedPeriod = 'Today';
  late FocusNode _focusNode;

  // Accent colors
  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarn = Color(0xFFF59E0B);

  // Repository
  final _repo = InsightRepository();

  // Quick stats
  bool _loadingTotal = true, _loadingProducts = true, _loadingCustomers = true;
  String? _errorTotal, _errorProducts, _errorCustomers;

  double _totalSales = 0.0;
  int _totalProducts = 0;
  int _totalCustomers = 0;

  // Top Selling
  bool _loadingTopItems = true;
  String? _errorTopItems;
  List<TopItemSummary> _topItems = [];

  // Sales Overview (chart)
  bool _loadingChart = true;
  String? _errorChart;
  ChartSeries _series = const ChartSeries(labels: [], values: [], yUnit: 'Rs.');

  // currency formats
  final _currencyFull = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ', decimalDigits: 2);
  final _currencyCompact = NumberFormat.compactCurrency(locale: 'en', symbol: 'Rs. ');

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.requestFocus();

      // OPTIONAL seed (call once if you want demo data):
      // await _repo.seedInsightDemoIfEmpty();

      await _refreshAll();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  InsightPeriod get _period {
    switch (selectedPeriod) {
      case 'Today':
        return InsightPeriod.today;
      case 'This Week':
        return InsightPeriod.week;
      case 'This Month':
        return InsightPeriod.month;
      case 'This Year':
        return InsightPeriod.year;
      default:
        return InsightPeriod.today;
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loadingTotal = _loadingProducts = _loadingCustomers = true;
      _loadingTopItems = _loadingChart = true;
      _errorTotal = _errorProducts = _errorCustomers = _errorTopItems = _errorChart = null;
    });

    try {
      final total = await _repo.totalSales(_period);
      setState(() {
        _totalSales = total;
        _loadingTotal = false;
      });
    } catch (e) {
      setState(() {
        _errorTotal = e.toString();
        _loadingTotal = false;
      });
    }

    try {
      final p = await _repo.totalProducts();
      setState(() {
        _totalProducts = p;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _errorProducts = e.toString();
        _loadingProducts = false;
      });
    }

    try {
      final c = await _repo.totalCustomers();
      setState(() {
        _totalCustomers = c;
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _errorCustomers = e.toString();
        _loadingCustomers = false;
      });
    }

    try {
      final t = await _repo.topSellingItems(_period, limit: 10);
      setState(() {
        _topItems = t;
        _loadingTopItems = false;
      });
    } catch (e) {
      setState(() {
        _errorTopItems = e.toString();
        _loadingTopItems = false;
      });
    }

    try {
      final s = await _repo.salesSeries(_period);
      setState(() {
        _series = s;
        _loadingChart = false;
      });
    } catch (e) {
      setState(() {
        _errorChart = e.toString();
        _loadingChart = false;
      });
    }
  }

  // ESC -> back
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  // Palette
  _Palette _palette(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _Palette(
        bg: Color(0xFF0B1623),
        surface: Color(0xFF121A26),
        border: Color(0x1FFFFFFF),
        text: Colors.white,
        textMuted: Colors.white70,
      );
    }
    return const _Palette(
      bg: Color(0xFFF4F6FA),
      surface: Colors.white,
      border: Color(0x1A000000),
      text: Color(0xFF0F172A),
      textMuted: Colors.black54,
    );
  }

  BoxDecoration _cardBox(_Palette p) => BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: p.bg,
          foregroundColor: p.text,
          titleSpacing: 12,
          title: Row(
            children: [
              Text('Insights & Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.text.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.border),
                ),
                child: Text('ESC', style: TextStyle(fontSize: 10, color: p.textMuted, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: p.text.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod,
                  dropdownColor: p.surface,
                  style: TextStyle(color: p.text, fontSize: 14),
                  icon: Icon(Icons.keyboard_arrow_down, color: p.textMuted),
                  items: const ['Today','This Week','This Month','This Year']
                      .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (String? v) async {
                    setState(() => selectedPeriod = v!);
                    await _refreshAll();
                  },
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Quick Stats
              Container(
                height: 120,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Total Sales',
                          value: _loadingTotal
                              ? 'Loading...'
                              : _errorTotal != null
                                  ? 'Error'
                                  : _currencyFull.format(_totalSales),
                          change: '',
                          color: kSuccess,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Customers',
                          value: _loadingCustomers
                              ? 'Loading...'
                              : _errorCustomers != null
                                  ? 'Error'
                                  : _totalCustomers.toString(),
                          change: '',
                          color: const Color(0xFF6366F1),
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Products',
                          value: _loadingProducts
                              ? 'Loading...'
                              : _errorProducts != null
                                  ? 'Error'
                                  : _totalProducts.toString(),
                          change: '',
                          color: kWarn,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildSalesContent(p),

              // Top selling items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: _cardBox(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Top Selling Items', iconColor: kSuccess, textColor: p.text),
                      const SizedBox(height: 12),
                      if (_loadingTopItems)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(child: Text('Loading...', style: TextStyle(color: p.textMuted))),
                        )
                      else if (_errorTopItems != null)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Failed to load: $_errorTopItems',
                              style: const TextStyle(color: Colors.redAccent)),
                        )
                      else if (_topItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('No data', style: TextStyle(color: p.textMuted)),
                        )
                      else
                        Column(
                          children: _topItems
                              .map((it) => _buildTopSellingItem(
                                    p,
                                    it.name,
                                    it.price != null ? _currencyFull.format(it.price!) : '—',
                                    '${it.sold} sold',
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),

              if (_errorTotal != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Total Sales load failed:\n$_errorTotal',
                      style: TextStyle(color: Colors.red.shade300), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Stat card
  Widget _buildStatCard({
    required _Palette p,
    required String title,
    required String value,
    required String change,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Text(change, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ===== Sales Overview (with axis names) =====
  Widget _buildSalesContent(_Palette p) {
    final labels = _series.labels;
    final values = _series.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            height: 340,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: _cardBox(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Sales Overview', iconColor: kInfo, textColor: p.text),
                const SizedBox(height: 12),
                Expanded(
                  child: _loadingChart
                      ? Center(child: Text('Loading...', style: TextStyle(color: p.textMuted)))
                      : _errorChart != null
                          ? Center(child: Text('Failed to load: $_errorChart',
                              style: const TextStyle(color: Colors.redAccent)))
                          : (labels.isEmpty || values.isEmpty)
                              ? Center(child: Text('No data', style: TextStyle(color: p.textMuted)))
                              : LineChart(_chartData(p, labels, values)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(_Palette p, List<String> labels, List<double> values) {
    final spots = List<FlSpot>.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    final maxY = values.fold<double>(0, (m, v) => math.max(m, v));
    final niceMax = _niceCeil(maxY);
    final stepX = math.max(1, (labels.length / 6).floor()); // show ~6 ticks on x

    return LineChartData(
      backgroundColor: Colors.transparent,
      minX: 0,
      maxX: math.max(0, labels.length - 1).toDouble(),
      minY: 0,
      maxY: niceMax == 0 ? 10 : niceMax.toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(color: p.text.withOpacity(0.08), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        // Y axis
        leftTitles: AxisTitles(
          axisNameWidget: Text('Sales (${_series.yUnit})',
              style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600)),
          axisNameSize: 28,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 54,
            getTitlesWidget: (v, meta) {
              if (niceMax == 0) return const SizedBox.shrink();
              // show ~5 ticks
              final interval = (niceMax / 4).clamp(1, double.infinity);
              if ((v % interval).abs() > 0.001 && v != niceMax) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(_currencyCompact.format(v),
                    style: TextStyle(color: p.textMuted, fontSize: 11), textAlign: TextAlign.right),
              );
            },
          ),
        ),
        // X axis
        bottomTitles: AxisTitles(
          axisNameWidget:
              Text('Time', style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600)),
          axisNameSize: 26,
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
              if (i % stepX != 0 && i != labels.length - 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[i], style: TextStyle(color: p.textMuted, fontSize: 11)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: kInfo,
          barWidth: 3,
          belowBarData: BarAreaData(show: true, color: kInfo.withOpacity(0.18)),
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  int _niceCeil(double v) {
    if (v <= 0) return 0;
    // round up to 1/2/5 * 10^n
    final exp = (math.log(v) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    final scaled = v / base;
    double nice;
    if (scaled <= 1) {
      nice = 1;
    } else if (scaled <= 2) {
      nice = 2;
    } else if (scaled <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return (nice * base).ceil();
  }

  // Helpers for Top items list rows
  Widget _buildTopSellingItem(_Palette p, String name, String price, String sold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
              Text(sold, style: TextStyle(fontSize: 12, color: p.textMuted)),
            ]),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w800, color: kInfo)),
        ],
      ),
    );
  }
}

// Palette
class _Palette {
  final Color bg;
  final Color surface;
  final Color border;
  final Color text;
  final Color textMuted;
  const _Palette({
    required this.bg,
    required this.surface,
    required this.border,
    required this.text,
    required this.textMuted,
  });
}

// Small header
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color iconColor;
  final Color textColor;
  const _SectionHeader({required this.title, required this.iconColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: iconColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
