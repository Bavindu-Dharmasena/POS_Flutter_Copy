// reports_profit_margins.dart

import 'package:flutter/material.dart';
import 'package:pos_system/data/models/manager/profit_margin.dart';
import 'package:pos_system/data/repositories/manager/profit_margin_repository.dart';


class ProfitMarginsReportPage extends StatefulWidget {
  const ProfitMarginsReportPage({super.key});

  @override
  State<ProfitMarginsReportPage> createState() => _ProfitMarginsReportPageState();
}

class _ProfitMarginsReportPageState extends State<ProfitMarginsReportPage> {
  final ProfitMarginRepository _repository = ProfitMarginRepository();
  
  String period = 'all';
  String paymentMethod = 'all';
  
  List<ProfitMargin> profitMargins = [];
  ProfitMarginSummary? summary;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfitMargins();
  }

  Future<void> _loadProfitMargins() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final margins = await _repository.getProfitMargins(
        period: period,
        paymentMethod: paymentMethod,
      );
      
      final summaryData = await _repository.getProfitMarginSummary(
        period: period,
        paymentMethod: paymentMethod,
      );

      setState(() {
        profitMargins = margins;
        summary = summaryData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _onFilterChanged() async {
    await _loadProfitMargins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports • Profit Margins',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0F172A),
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
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                        DropdownMenuItem(value: 'day', child: Text('Today')),
                        DropdownMenuItem(value: 'month', child: Text('This Month')),
                        DropdownMenuItem(value: 'year', child: Text('This Year')),
                      ],
                      onChanged: (v) {
                        setState(() => period = v ?? 'all');
                        _onFilterChanged();
                      },
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
                      value: paymentMethod,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF334155),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                      ],
                      onChanged: (v) {
                        setState(() => paymentMethod = v ?? 'all');
                        _onFilterChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            else if (error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: const Color(0xFFEF4444),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfitMargins,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Key Metrics Cards
                      if (summary != null)
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Revenue',
                                value: 'Rs. ${summary!.totalRevenue.toStringAsFixed(2)}',
                                icon: Icons.trending_up,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Cost',
                                value: 'Rs. ${summary!.totalCost.toStringAsFixed(2)}',
                                icon: Icons.trending_down,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Overall Margin',
                                value: '${summary!.overallMarginPercentage.toStringAsFixed(1)}%',
                                icon: Icons.percent,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Additional metrics row
                      if (summary != null)
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Profit',
                                value: 'Rs. ${summary!.totalProfit.toStringAsFixed(2)}',
                                icon: Icons.attach_money,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Items Sold',
                                value: '${summary!.totalItemsSold}',
                                icon: Icons.inventory,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Transactions',
                                value: '${summary!.totalTransactions}',
                                icon: Icons.receipt,
                                color: const Color(0xFF06B6D4),
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Profit Margins Table
                      if (profitMargins.isNotEmpty)
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
                                    const Spacer(),
                                    Text(
                                      '${profitMargins.length} items',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
                                          'Profit', 
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
                                ...profitMargins.map((margin) => _ProfitMarginRow(data: margin)),
                                
                                if (summary != null) ...[
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
                                            'Rs. ${summary!.totalRevenue.toStringAsFixed(2)}',
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
                                            'Rs. ${summary!.totalCost.toStringAsFixed(2)}',
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
                                            'Rs. ${summary!.totalProfit.toStringAsFixed(2)}',
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
                                            '${summary!.overallMarginPercentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: summary!.overallMarginPercentage >= 25 
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
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white38,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Data Available',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No sales data found for the selected period and payment method.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Visual Profit Margins
                      if (profitMargins.isNotEmpty)
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
                                
                                ...profitMargins.take(10).map((margin) => _MarginBar(data: margin)),
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
  final ProfitMargin data;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${data.categoryName} • ${data.quantitySold} sold',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${data.totalRevenue.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${data.totalCost.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${data.totalProfit.toStringAsFixed(2)}',
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
  final ProfitMargin data;

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
              Expanded(
                child: Text(
                  data.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${data.marginPercentage.toStringAsFixed(1)}% • Rs. ${data.totalProfit.toStringAsFixed(2)}',
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
              widthFactor: (data.marginPercentage / 100).clamp(0.0, 1.0),
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