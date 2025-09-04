import 'package:flutter/material.dart';

class ProfitMarginsReportPage extends StatefulWidget {
  const ProfitMarginsReportPage({super.key});

  @override
  State<ProfitMarginsReportPage> createState() => _ProfitMarginsReportPageState();
}

class _ProfitMarginsReportPageState extends State<ProfitMarginsReportPage> {
  String period = 'Day';
  String method = 'All';

  // Sample data - replace with your actual data source
  final List<ProfitMarginData> sampleData = [
    ProfitMarginData('Product A', 1500, 900, 40.0),
    ProfitMarginData('Product B', 2200, 1800, 18.2),
    ProfitMarginData('Product C', 800, 520, 35.0),
    ProfitMarginData('Product D', 3000, 2100, 30.0),
    ProfitMarginData('Product E', 1200, 960, 20.0),
  ];

  @override
  Widget build(BuildContext context) {
    final totalRevenue = sampleData.fold(0.0, (sum, item) => sum + item.revenue);
    final totalCost = sampleData.fold(0.0, (sum, item) => sum + item.cost);
    final overallMargin = ((totalRevenue - totalCost) / totalRevenue * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports • Profit Margins',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B), // Dark slate
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0F172A), // Very dark slate
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Filter:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: DropdownButton<String>(
                      value: period,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF334155),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'Day', child: Text('Day')),
                        DropdownMenuItem(value: 'Month', child: Text('Month')),
                        DropdownMenuItem(value: 'Year', child: Text('Year')),
                      ],
                      onChanged: (v) => setState(() => period = v ?? 'Day'),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Payment:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: DropdownButton<String>(
                      value: method,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF334155),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                      ],
                      onChanged: (v) => setState(() => method = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Key Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Revenue',
                            value: '\$${totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                            color: const Color(0xFF10B981), // Green
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Cost',
                            value: '\$${totalCost.toStringAsFixed(0)}',
                            icon: Icons.trending_down,
                            color: const Color(0xFFF59E0B), // Orange
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Overall Margin',
                            value: '${overallMargin.toStringAsFixed(1)}%',
                            icon: Icons.percent,
                            color: const Color(0xFF3B82F6), // Blue
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Profit Margins Table
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.assessment, color: const Color(0xFF3B82F6)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Profit Margins by Product',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3, 
                                    child: Text(
                                      'Product', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2, 
                                    child: Text(
                                      'Revenue', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ), 
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2, 
                                    child: Text(
                                      'Cost', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ), 
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2, 
                                    child: Text(
                                      'Margin %', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ), 
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Table Rows
                            ...sampleData.map((data) => _ProfitMarginRow(data: data)),
                            
                            const SizedBox(height: 12),
                            Divider(color: const Color(0xFF475569)),
                            
                            // Total Row
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${totalRevenue.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${totalCost.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${overallMargin.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: overallMargin >= 25 
                                            ? const Color(0xFF10B981) 
                                            : const Color(0xFFF59E0B),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Visual Profit Margins
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart, color: const Color(0xFF3B82F6)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Margin Visualization',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            ...sampleData.map((data) => _MarginBar(data: data)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitMarginRow extends StatelessWidget {
  final ProfitMarginData data;

  const _ProfitMarginRow({required this.data});

  @override
  Widget build(BuildContext context) {
    Color marginColor = data.marginPercentage >= 30 
        ? const Color(0xFF10B981) // Green
        : data.marginPercentage >= 20 
            ? const Color(0xFFF59E0B) // Orange
            : const Color(0xFFEF4444); // Red

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF475569))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              data.product,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${data.revenue.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${data.cost.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${data.marginPercentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: marginColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarginBar extends StatelessWidget {
  final ProfitMarginData data;

  const _MarginBar({required this.data});

  @override
  Widget build(BuildContext context) {
    Color barColor = data.marginPercentage >= 30 
        ? const Color(0xFF10B981) // Green
        : data.marginPercentage >= 20 
            ? const Color(0xFFF59E0B) // Orange
            : const Color(0xFFEF4444); // Red

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.product,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                '${data.marginPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: data.marginPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfitMarginData {
  final String product;
  final double revenue;
  final double cost;
  final double marginPercentage;

  ProfitMarginData(this.product, this.revenue, this.cost, this.marginPercentage);
}