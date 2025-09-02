import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart'; // for ESC key
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  String selectedPeriod = 'Today';
  late FocusNode _focusNode;

  // ===== Accent colors =====
  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarn = Color(0xFFF59E0B);

  // ==== Total Sales ====
  bool _loadingTotal = true;
  String? _errorTotal;
  double _totalSales = 0.0;
  String? _changePctText; // optional "+15%"

  // ==== Total Products ====
  bool _loadingProducts = true;
  String? _errorProducts;
  int _totalProducts = 0;

  // ==== Total Customers ====
  bool _loadingCustomers = true;
  String? _errorCustomers;
  int _totalCustomers = 0;

  // ==== Top Selling Items ====
  bool _loadingTopItems = true;
  String? _errorTopItems;
  List<_TopItem> _topItems = [];

  // currency formatter
  final _currency = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // === Base URL per platform ===
  String _apiBase() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://127.0.0.1:3001';
  }

  Future<void> _refreshAll() async {
    // Fire them in parallel; each manages its own loading/error state.
    await Future.wait([
      _loadTotalSales(),
      _loadTotalProducts(),
      _loadTotalCustomers(),
      _loadTopItems(),
    ]);
  }

  // ---- Helpers to extract numbers from various JSON shapes ----
  double _extractDouble(dynamic body, List<String> keys) {
    if (body is num) return body.toDouble();
    if (body is Map<String, dynamic>) {
      for (final k in keys) {
        final v = body[k];
        if (v is num) return v.toDouble();
      }
    }
    throw Exception('Unexpected response: $body');
  }

  int _extractInt(dynamic body, List<String> keys) {
    if (body is num) return body.toInt();
    if (body is Map<String, dynamic>) {
      for (final k in keys) {
        final v = body[k];
        if (v is num) return v.toInt();
      }
    }
    throw Exception('Unexpected response: $body');
  }

  // ================= API LOADERS =================
  Future<void> _loadTotalSales() async {
    setState(() {
      _loadingTotal = true;
      _errorTotal = null;
    });

    try {
      // final periodKey = _mapPeriod(selectedPeriod); // period support
      // final uri = Uri.parse('${_apiBase()}/insight/total-sales?period=$periodKey');
      final uri = Uri.parse('${_apiBase()}/insight/total-sales');

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = res.body.trim().isEmpty ? null : jsonDecode(res.body);
      double total = 0.0;
      String? changeText;

      if (body is num) {
        total = body.toDouble();
      } else if (body is Map<String, dynamic>) {
        total = _extractDouble(body, ['totalSales', 'total', 'amount', 'value']);
        if (body['change'] is String) changeText = body['change'] as String;
        if (body['changePct'] is num) {
          final pct = (body['changePct'] as num).toDouble() * 100.0;
          changeText = (pct >= 0 ? '+' : '') + pct.toStringAsFixed(0) + '%';
        }
      } else {
        throw Exception('Unexpected response');
      }

      setState(() {
        _totalSales = total;
        _changePctText = changeText;
        _loadingTotal = false;
      });
    } catch (e) {
      setState(() {
        _errorTotal = e.toString();
        _loadingTotal = false;
      });
    }
  }

  Future<void> _loadTotalProducts() async {
    setState(() {
      _loadingProducts = true;
      _errorProducts = null;
    });

    try {
      // final periodKey = _mapPeriod(selectedPeriod);
      // final uri = Uri.parse('${_apiBase()}/insight/total-products?period=$periodKey');
      final uri = Uri.parse('${_apiBase()}/insight/total-products');

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = res.body.trim().isEmpty ? null : jsonDecode(res.body);
      final total = _extractInt(body, ['totalProducts', 'total', 'count', 'value']);

      setState(() {
        _totalProducts = total;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _errorProducts = e.toString();
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadTotalCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _errorCustomers = null;
    });

    try {
      // final periodKey = _mapPeriod(selectedPeriod);
      // final uri = Uri.parse('${_apiBase()}/insight/total-customers?period=$periodKey');
      final uri = Uri.parse('${_apiBase()}/insight/total-customers');

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = res.body.trim().isEmpty ? null : jsonDecode(res.body);
      final total = _extractInt(body, ['totalCustomers', 'total', 'count', 'value']);

      setState(() {
        _totalCustomers = total;
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _errorCustomers = e.toString();
        _loadingCustomers = false;
      });
    }
  }

  Future<void> _loadTopItems() async {
    setState(() {
      _loadingTopItems = true;
      _errorTopItems = null;
    });

    try {
      // final periodKey = _mapPeriod(selectedPeriod);
      // final uri = Uri.parse('${_apiBase()}/insight/top-selling-items?period=$periodKey');
      final uri = Uri.parse('${_apiBase()}/insight/top-selling-items');

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = res.body.trim().isEmpty ? null : jsonDecode(res.body);

      final items = <_TopItem>[];
      if (body is List) {
        for (final e in body) {
          if (e is Map<String, dynamic>) {
            final name = (e['name'] ?? e['itemName'] ?? e['title'] ?? 'Item').toString();
            final priceRaw = e['price'] ?? e['sellPrice'] ?? e['unitPrice'];
            final price = (priceRaw is num) ? priceRaw.toDouble() : null;
            final soldRaw = e['sold'] ?? e['count'] ?? e['quantity'] ?? e['qty'];
            final sold = (soldRaw is num) ? soldRaw.toInt() : 0;
            items.add(_TopItem(name: name, price: price, sold: sold));
          } else if (e is String) {
            items.add(_TopItem(name: e, price: null, sold: 0));
          }
        }
      } else {
        throw Exception('Unexpected response for top-selling-items');
      }

      setState(() {
        _topItems = items;
        _loadingTopItems = false;
      });
    } catch (e) {
      setState(() {
        _errorTopItems = e.toString();
        _loadingTopItems = false;
      });
    }
  }

  String _mapPeriod(String uiValue) {
    switch (uiValue) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'week';
      case 'This Month':
        return 'month';
      case 'This Year':
        return 'year';
      default:
        return 'today';
    }
  }

  // === ESC -> back ===
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  // ===== Dynamic palette =====
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
              Text(
                'Insights & Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(width: 8),
              // ESC hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.text.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  'ESC',
                  style: TextStyle(
                    fontSize: 10,
                    color: p.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                  items: const [
                    'Today',
                    'This Week',
                    'This Month',
                    'This Year'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    setState(() => selectedPeriod = newValue!);
                    // If API supports period filter, the loaders already have commented lines.
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
              // Quick Stats - horizontally scrollable
              Container(
                height: 120,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Total Sales
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Total Sales',
                          value: _loadingTotal
                              ? 'Loading...'
                              : _errorTotal != null
                                  ? 'Error'
                                  : _currency.format(_totalSales),
                          change: _loadingTotal ? '...' : (_changePctText ?? ''),
                          color: kSuccess,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Orders (still static unless you add endpoint)
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Orders',
                          value: '348',
                          change: '+8%',
                          color: kInfo,
                          icon: Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Customers from API
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

                      // Products from API
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
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildSalesContent(p),

              // Top selling items section (with loading/error)
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
                          child: Center(
                            child: Text('Loading...', style: TextStyle(color: p.textMuted)),
                          ),
                        )
                      else if (_errorTopItems != null)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Failed to load: $_errorTopItems', style: const TextStyle(color: Colors.redAccent)),
                        )
                      else if (_topItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('No data', style: TextStyle(color: p.textMuted)),
                        )
                      else
                        Column(
                          children: _topItems
                              .take(10)
                              .map((it) => _buildTopSellingItem(
                                    p,
                                    it.name,
                                    it.price != null ? _currency.format(it.price!) : '—',
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
                  child: Text(
                    'Total Sales load failed:\n$_errorTotal',
                    style: TextStyle(color: Colors.red.shade300),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ======= Reusable stat card =======
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
          // header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Text(
                change,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: p.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================== SALES CONTENT (chart) ==================
  Widget _buildSalesContent(_Palette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Sales Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: _cardBox(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Sales Overview', iconColor: kInfo, textColor: p.text),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: p.text.withOpacity(0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: TextStyle(color: p.textMuted, fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 6,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 1),
                            FlSpot(2, 4),
                            FlSpot(3, 2),
                            FlSpot(4, 5),
                            FlSpot(5, 3),
                            FlSpot(6, 4),
                          ],
                          isCurved: true,
                          color: kInfo,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: kInfo.withOpacity(0.18),
                          ),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Helpers (list rows) =====
  Widget _buildTopSellingItem(_Palette p, String name, String price, String sold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
                Text(sold, style: TextStyle(fontSize: 12, color: p.textMuted)),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.w800, color: kInfo),
          ),
        ],
      ),
    );
  }
}

// ===== Palette holder =====
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

// ===== Small reusable header =====
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color iconColor;
  final Color textColor;
  const _SectionHeader({
    required this.title,
    required this.iconColor,
    required this.textColor,
  });

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
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}

// ===== Top item model =====
class _TopItem {
  final String name;
  final double? price; // can be null if API doesn’t send it
  final int sold;
  _TopItem({required this.name, this.price, required this.sold});
}
