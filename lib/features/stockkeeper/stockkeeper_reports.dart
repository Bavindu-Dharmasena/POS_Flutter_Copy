import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import "package:flutter/services.dart"; // 👈 for keyboard keys

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  String selectedPeriod = 'Today';
  late FocusNode _focusNode;

  // ===== Dark App Palette (same names as AddItemPage) =====
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26);
  static const Color kBorder = Color(0x1FFFFFFF);
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;

  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarn = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Handle key events
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Navigate back when ESC is pressed
      Navigator.of(context).pop();
    }
  }

  // ====== CARD DECORATION (matches AddItemPage) ======
  BoxDecoration get _cardBox => BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
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
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kBg,
          foregroundColor: kText,
          titleSpacing: 12,
          title: Row(
            children: [
              const Text(
                'Insights & Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(width: 8),
              // ESC hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kBorder),
                ),
                child: const Text(
                  'ESC',
                  style: TextStyle(
                    fontSize: 10,
                    color: kTextMuted,
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
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod,
                  dropdownColor: kSurface,
                  style: const TextStyle(color: kText, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down, color: kTextMuted),
                  items: const [
                    'Today',
                    'This Week',
                    'This Month',
                    'This Year'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: kText)),
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
              // Quick Stats - Made scrollable horizontally
              Container(
                height: 120,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160, // Fixed width for each card
                        child: _buildStatCard(
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
                          title: 'Customers',
                          value: '156',
                          change: '+12%',
                          color: const Color(0xFF6366F1), // Indigo from palette
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: _buildStatCard(
                          title: 'Products',
                          value: '89',
                          change: '+3%',
                          color: kWarn,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12), // Extra padding at the end
                    ],
                  ),
                ),
              ),

              // Sales Content - Direct without tabs
              const SizedBox(height: 12),
              _buildSalesContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ======= Reusable stat card matching dark theme =======
  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox,
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================== SALES CONTENT (without tabs) ==================
  Widget _buildSalesContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Sales Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: _cardBox,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Sales Overview', iconColor: kInfo),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: const TextStyle(color: kTextMuted, fontSize: 11),
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
                          color: kInfo, // flat color instead of gradient
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
            decoration: _cardBox,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Top Selling Items', iconColor: kSuccess),
                const SizedBox(height: 12),
                _buildTopSellingItem('Coffee Latte', 'Rs. 450.00', '234 sold'),
                _buildTopSellingItem('Chicken Burger', 'Rs. 899.00', '189 sold'),
                _buildTopSellingItem('Caesar Salad', 'Rs. 675.00', '156 sold'),
                _buildTopSellingItem('Chocolate Cake', 'Rs. 525.00', '134 sold'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Helpers (list rows) =====
  Widget _buildTopSellingItem(String name, String price, String sold) {
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: kText)),
                Text(sold, style: const TextStyle(fontSize: 12, color: kTextMuted)),
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

class BackgroundBarChartRodData {
}

// ===== Small reusable header matching dark cards =====
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color iconColor;
  const _SectionHeader({required this.title, required this.iconColor});

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
          style: const TextStyle(
            color: _StockKeeperReportsState.kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}