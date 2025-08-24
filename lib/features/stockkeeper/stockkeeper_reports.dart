import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart'; // for ESC key

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  String selectedPeriod = 'Today';
  late FocusNode _focusNode;

  // ===== Accent colors (unchanged) =====
  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarn = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Handle key events: ESC -> back
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  // ===== Dynamic palette that follows light/dark theme =====
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
    // Light equivalents chosen to preserve your look while being readable
    return const _Palette(
      bg: Color(0xFFF4F6FA),
      surface: Colors.white,
      border: Color(0x1A000000), // ~6% black
      text: Color(0xFF0F172A),   // slate-900
      textMuted: Colors.black54,
    );
  }

  // Card decoration using palette (same shape/shadows)
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
                  onChanged: (String? newValue) {
                    setState(() => selectedPeriod = newValue!);
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
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Total Sales',
                          value: 'Rs. 12,450',
                          change: '+15%',
                          color: kSuccess,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Customers',
                          value: '156',
                          change: '+12%',
                          color: Color(0xFF6366F1), // Indigo
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          p: p,
                          title: 'Products',
                          value: '89',
                          change: '+3%',
                          color: kWarn,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),

              // Sales Content - Direct without tabs
              const SizedBox(height: 12),
              _buildSalesContent(p),
            ],
          ),
        ),
      ),
    );
  }

  // ======= Reusable stat card (uses palette) =======
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

  // ================== SALES CONTENT (without tabs) ==================
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
                          color: kInfo, // keep flat color
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

          // Top Selling Items
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: _cardBox(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Top Selling Items', iconColor: kSuccess, textColor: p.text),
                const SizedBox(height: 12),
                _buildTopSellingItem(p, 'Coffee Latte', 'Rs. 450.00', '234 sold'),
                _buildTopSellingItem(p, 'Chicken Burger', 'Rs. 899.00', '189 sold'),
                _buildTopSellingItem(p, 'Caesar Salad', 'Rs. 675.00', '156 sold'),
                _buildTopSellingItem(p, 'Chocolate Cake', 'Rs. 525.00', '134 sold'),
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
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: p.text)),
                Text(sold, style: TextStyle(fontSize: 12, color: p.textMuted)),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kInfo,
              )),
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

// ===== Small reusable header matching dark cards =====
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
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
