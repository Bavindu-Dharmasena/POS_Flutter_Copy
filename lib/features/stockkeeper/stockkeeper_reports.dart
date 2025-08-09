import 'package:flutter/material.dart';
import '../../widget/stockKeeperReportCard.dart';

// Constants for better maintainability
class AppConstants {
  static const primaryDark = Color(0xFF0B1623);
  static const cardPadding = EdgeInsets.all(20.0);
  static const gridSpacing = 16.0;
  static const borderRadius = 16.0;
  static const iconContainerRadius = 12.0;
  static const buttonBorderRadius = 8.0;
}

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  final Set<String> _downloadingReports = {};
  DateTimeRange? _selectedDateRange;
  Map<String, dynamic> _quickSalesData = {
    'totalSales': 0,
    'totalItems': 0,
    'topProducts': [],
  };

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadQuickSalesData();
  }

  Future<void> _loadQuickSalesData() async {
    // Simulate API call to get sales data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _quickSalesData = {
        'totalSales': 12540.75,
        'totalItems': 342,
        'topProducts': [
          {'name': 'Premium Widget', 'sales': 4200},
          {'name': 'Standard Gadget', 'sales': 3800},
          {'name': 'Basic Tool', 'sales': 2100},
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock Keeper Reports',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Date range selector
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _showDateRangePicker,
              icon: const Icon(Icons.date_range, color: Colors.white),
              label: Text(
                _getDateRangeText(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonBorderRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppConstants.primaryDark,
      body: SingleChildScrollView(
        padding: AppConstants.cardPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Quick info card with date range
                _buildDateRangeCard(),
                const SizedBox(height: 20),
                // Quick sales report
                _buildQuickSalesReport(),
                const SizedBox(height: 20),
                // Reports grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;
                    if (constraints.maxWidth > 900) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 1;
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppConstants.gridSpacing,
                      mainAxisSpacing: AppConstants.gridSpacing,
                      childAspectRatio: 1.3,
                      children: [
                        StockKeeperReportCard(
                          reportId: 'daily',
                          title: 'Daily Report',
                          subtitle: 'View today\'s sales & transactions',
                          icon: Icons.today_outlined,
                          gradientColors: [
                            const Color(0xFF1e3c72),
                            const Color(0xFF2a5298),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Daily Sales Report',
                            'This report shows all sales transactions for ${_getFormattedDate(DateTime.now())}.\n\n• Total Sales: Rs${_quickSalesData['totalSales']}\n• Items Sold: ${_quickSalesData['totalItems']}\n• Top Products: ${_quickSalesData['topProducts'].map((p) => p['name']).join(', ')}',
                          ),
                          onDownloadTap: () =>
                              _handleDownloadReport('daily', 'Daily Report'),
                          isDownloading: _downloadingReports.contains('daily'),
                        ),
                        StockKeeperReportCard(
                          reportId: 'weekly',
                          title: 'Weekly Report',
                          subtitle: 'Analyze weekly performance',
                          icon: Icons.view_week_outlined,
                          gradientColors: [
                            const Color(0xFF134e5e),
                            const Color(0xFF71b280),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Weekly Sales Report',
                            'Weekly sales summary for ${_getDateRangeText()}:\n\n• Total Revenue: Rs${(_quickSalesData['totalSales'] * 4).toStringAsFixed(2)}\n• Average Daily Sales: Rs${(_quickSalesData['totalSales'] / 7).toStringAsFixed(2)}\n• Most Sold Day: Friday\n• Product Trends: Premium products up 12%',
                          ),
                          onDownloadTap: () =>
                              _handleDownloadReport('weekly', 'Weekly Report'),
                          isDownloading: _downloadingReports.contains('weekly'),
                        ),

                        StockKeeperReportCard(
                          reportId: 'monthly',
                          title: 'Monthly Report',
                          subtitle: 'Monthly business insights',
                          icon: Icons.calendar_month_outlined,
                          gradientColors: [
                            const Color(0xFF8B4513),
                            const Color(0xFFD2691E),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Monthly Sales Report',
                            'Monthly performance overview:\n\n• Total Sales: Rs${(_quickSalesData['totalSales'] * 30).toStringAsFixed(2)}\n• New Customers: 45\n• Returns: 5 (1.2% of sales)\n• Inventory Turnover: 2.4x\n• Profit Margin: 32.5%',
                          ),
                          onDownloadTap: () => _handleDownloadReport(
                            'monthly',
                            'Monthly Report',
                          ),
                          isDownloading: _downloadingReports.contains(
                            'monthly',
                          ),
                        ),
                        StockKeeperReportCard(
                          reportId: 'sales',
                          title: 'Sales Report',
                          subtitle: 'Detailed sales analytics',
                          icon: Icons.trending_up_outlined,
                          gradientColors: [
                            const Color(0xFF2C5364),
                            const Color(0xFF203A43),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Detailed Sales Analysis',
                            'Comprehensive sales data for ${_getDateRangeText()}:\n\n• Sales by Category:\n   - Electronics: 42%\n   - Home Goods: 28%\n   - Clothing: 22%\n   - Other: 8%\n\n• Sales by Hour:\n   - Peak: 2PM (18% of sales)\n   - Slowest: 9AM (4% of sales)\n\n• Customer Demographics:\n   - Repeat Customers: 65%\n   - New Customers: 35%',
                          ),
                          onDownloadTap: () =>
                              _handleDownloadReport('sales', 'Sales Report'),
                          isDownloading: _downloadingReports.contains('sales'),
                        ),
                        StockKeeperReportCard(
                          reportId: 'inventory',
                          title: 'Inventory Report',
                          subtitle: 'Stock levels & movements',
                          icon: Icons.inventory_2_outlined,
                          gradientColors: [
                            const Color(0xFF4B0082),
                            const Color(0xFF8B008B),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Inventory Status Report',
                            'Current inventory status:\n\n• Total SKUs: 142\n• Low Stock Items: 18\n• Out of Stock: 5\n• Overstocked Items: 7\n\nRecent Movements:\n• Received: 45 items\n• Sold: 342 items\n• Damaged: 3 items\n• Returned: 12 items',
                          ),
                          onDownloadTap: () => _handleDownloadReport(
                            'inventory',
                            'Inventory Report',
                          ),
                          isDownloading: _downloadingReports.contains(
                            'inventory',
                          ),
                        ),
                        StockKeeperReportCard(
                          reportId: 'profit',
                          title: 'Profit Report',
                          subtitle: 'Profit margins & analysis',
                          icon: Icons.account_balance_wallet_outlined,
                          gradientColors: [
                            const Color(0xFF1a252f),
                            const Color(0xFF2b5876),
                          ],
                          onViewTap: () => _showReportPreview(
                            'Profitability Analysis',
                            'Profit report for ${_getDateRangeText()}:\n\n• Gross Revenue: Rs${(_quickSalesData['totalSales'] * 30).toStringAsFixed(2)}\n• COGS: Rs${(_quickSalesData['totalSales'] * 30 * 0.6).toStringAsFixed(2)}\n• Gross Profit: Rs${(_quickSalesData['totalSales'] * 30 * 0.4).toStringAsFixed(2)}\n• Expenses: Rs${(_quickSalesData['totalSales'] * 30 * 0.08).toStringAsFixed(2)}\n• Net Profit: Rs${(_quickSalesData['totalSales'] * 30 * 0.32).toStringAsFixed(2)}\n\nProfit by Category:\n• Electronics: 38%\n• Home Goods: 42%\n• Clothing: 15%\n• Other: 5%',
                          ),
                          onDownloadTap: () =>
                              _handleDownloadReport('profit', 'Profit Report'),
                          isDownloading: _downloadingReports.contains('profit'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to show report preview
  void _showReportPreview(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Report exported successfully!', isSuccess: true);
            },
            child: const Text('Export as PDF'),
          ),
        ],
      ),
    );
  }

  // Enhanced date range card
  Widget _buildDateRangeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C5364), Color(0xFF203A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Selected Date Range',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedDateRange != null
                            ? _getFormattedDate(_selectedDateRange!.start)
                            : 'Not selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedDateRange != null
                            ? _getFormattedDate(_selectedDateRange!.end)
                            : 'Not selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showDateRangePicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonBorderRadius,
                      ),
                    ),
                  ),
                  child: const Text('Change Range'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // New quick sales report widget
  Widget _buildQuickSalesReport() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: const LinearGradient(
            colors: [Color(0xFF4B0082), Color(0xFF8B008B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Quick Sales Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadQuickSalesData,
                  tooltip: 'Refresh sales data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSalesMetric(
                  'Total Sales',
                  '${_quickSalesData['totalSales'].toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
                const SizedBox(width: 16),
                _buildSalesMetric(
                  'Items Sold',
                  _quickSalesData['totalItems'].toString(),
                  Icons.shopping_cart,
                ),
                const SizedBox(width: 16),
                _buildSalesMetric(
                  'Avg. Order',
                  '${(_quickSalesData['totalSales'] / (_quickSalesData['totalItems'] > 0 ? _quickSalesData['totalItems'] : 1)).toStringAsFixed(2)}',
                  Icons.assessment,
                  prefix: 'LKR',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_quickSalesData['topProducts'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Selling Products:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._quickSalesData['topProducts'].map<Widget>((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          Text(
                            'Rs${product['sales']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesMetric(
    String label,
    String value,
    IconData icon, {
    String? prefix,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (prefix != null)
                  Text(
                    prefix,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for date formatting
  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'Select Date Range';

    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    return '${_getFormattedDate(startDate)} - ${_getFormattedDate(endDate)}';
  }

  // Method to handle report download
  void _handleDownloadReport(String reportId, String reportName) async {
    setState(() {
      _downloadingReports.add(reportId);
    });

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _downloadingReports.remove(reportId);
    });

    _showSnackBar('$reportName downloaded successfully!', isSuccess: true);
  }

  // Method to show the date range picker dialog
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppConstants.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadQuickSalesData();
    }
  }

  // Helper method to show a SnackBar
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
