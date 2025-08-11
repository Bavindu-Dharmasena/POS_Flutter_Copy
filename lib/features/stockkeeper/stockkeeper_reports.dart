import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Keeper Reports',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StockKeeperReports(),
    );
  }
}

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  DateTimeRange? _selectedDateRange;
  String _selectedUser = 'All';
  String _selectedCashRegister = 'All';
  String _selectedProduct = 'All';
  String _selectedProductGroup = 'Products';
  bool _includeSubgroups = true;
  final Set<String> _downloadingReports = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _showSnackBar('Printing report...'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _showSnackBar('Exporting to PDF...'),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: () => _showSnackBar('Exporting to Excel...'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Reports Section
            _buildSectionHeader('Sales Reports'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Products',
                  icon: Icons.shopping_bag,
                  colors: [Colors.blue, Colors.lightBlue],
                ),
                _buildReportCard(
                  title: 'Product Groups',
                  icon: Icons.category,
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                _buildReportCard(
                  title: 'Customers',
                  icon: Icons.people,
                  colors: [Colors.green, Colors.teal],
                ),
                _buildReportCard(
                  title: 'Tax Rates',
                  icon: Icons.receipt,
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                _buildReportCard(
                  title: 'Users',
                  icon: Icons.person,
                  colors: [Colors.pink, Colors.pinkAccent],
                ),
                _buildReportCard(
                  title: 'Item List',
                  icon: Icons.list,
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
                _buildReportCard(
                  title: 'Payment Types',
                  icon: Icons.payment,
                  colors: [Colors.cyan, Colors.cyanAccent],
                ),
                _buildReportCard(
                  title: 'Payment Types by Users',
                  icon: Icons.account_balance_wallet,
                  colors: [Colors.amber, Colors.orange],
                ),
                _buildReportCard(
                  title: 'Payment Types by Customers',
                  icon: Icons.credit_card,
                  colors: [Colors.lightGreen, Colors.green],
                ),
                _buildReportCard(
                  title: 'Refunds',
                  icon: Icons.assignment_return,
                  colors: [Colors.red, Colors.redAccent],
                ),
                _buildReportCard(
                  title: 'Invoice List',
                  icon: Icons.description,
                  colors: [Colors.blueGrey, Colors.grey],
                ),
                _buildReportCard(
                  title: 'Daily Sales',
                  icon: Icons.calendar_today,
                  colors: [Colors.teal, Colors.tealAccent],
                ),
                _buildReportCard(
                  title: 'Hourly Sales',
                  icon: Icons.access_time,
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
                _buildReportCard(
                  title: 'Hourly Sales by Product Groups',
                  icon: Icons.timeline,
                  colors: [Colors.lightBlue, Colors.blue],
                ),
                _buildReportCard(
                  title: 'Table/Order Number',
                  icon: Icons.table_chart,
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                _buildReportCard(
                  title: 'Profit & Margin',
                  icon: Icons.attach_money,
                  colors: [Colors.green, Colors.lightGreen],
                ),
                _buildReportCard(
                  title: 'Unpaid Sales',
                  icon: Icons.money_off,
                  colors: [Colors.red, Colors.pink],
                ),
                _buildReportCard(
                  title: 'Starting Cash Entries',
                  icon: Icons.point_of_sale,
                  colors: [Colors.blue, Colors.indigo],
                ),
                _buildReportCard(
                  title: 'Validated Items',
                  icon: Icons.verified,
                  colors: [Colors.green, Colors.teal],
                ),
                _buildReportCard(
                  title: 'Discounts Granted',
                  icon: Icons.discount,
                  colors: [Colors.purple, Colors.deepPurpleAccent],
                ),
                _buildReportCard(
                  title: 'Items Discounts',
                  icon: Icons.percent,
                  colors: [Colors.amber, Colors.orange],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Purchase Reports Section
            _buildSectionHeader('Purchase Reports'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Products',
                  icon: Icons.shopping_cart,
                  colors: [Colors.blue, Colors.lightBlue],
                ),
                _buildReportCard(
                  title: 'Suppliers',
                  icon: Icons.local_shipping,
                  colors: [Colors.green, Colors.teal],
                ),
                _buildReportCard(
                  title: 'Unpaid Purchase',
                  icon: Icons.money_off,
                  colors: [Colors.red, Colors.pink],
                ),
                _buildReportCard(
                  title: 'Purchase Discounts',
                  icon: Icons.discount,
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                _buildReportCard(
                  title: 'Purchased Items Discounts',
                  icon: Icons.percent,
                  colors: [Colors.amber, Colors.orange],
                ),
                _buildReportCard(
                  title: 'Purchase Invoice List',
                  icon: Icons.description,
                  colors: [Colors.blueGrey, Colors.grey],
                ),
                _buildReportCard(
                  title: 'Tax Rates',
                  icon: Icons.receipt,
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                _buildReportCard(
                  title: 'Expiration Date',
                  icon: Icons.calendar_today,
                  colors: [Colors.teal, Colors.tealAccent],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Other Reports Sections
            _buildSectionHeader('Stock Return'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Products',
                  icon: Icons.assignment_return,
                  colors: [Colors.red, Colors.pink],
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Loss and Damage'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Products',
                  icon: Icons.warning,
                  colors: [Colors.orange, Colors.deepOrange],
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Finance'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Transaction History',
                  icon: Icons.history,
                  colors: [Colors.blueGrey, Colors.grey],
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Stock Control'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  title: 'Reorder Product List',
                  icon: Icons.repeat,
                  colors: [Colors.green, Colors.teal],
                ),
                _buildReportCard(
                  title: 'Low Stock Warning',
                  icon: Icons.notifications_active,
                  colors: [Colors.red, Colors.pink],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
  }) {
    bool isDownloading = _downloadingReports.contains(title);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFiltersDialog(title),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFiltersDialog(title),
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: const Text('Set Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isDownloading
                          ? null
                          : () => _handleDownloadReport(title),
                      icon: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.download, size: 16),
                      label: Text(isDownloading ? 'Downloading' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersDialog(String reportName) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue),
              const SizedBox(width: 8),
              Text('$reportName - Filters'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Report Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Date Range Filter
                  _buildDialogFilterRow(
                    'Date Range',
                    Icons.date_range,
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _selectedDateRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDateRange != null
                                    ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
                                          '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                                    : 'Select Date Range',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // User Filter
                  _buildDialogFilterRow(
                    'User',
                    Icons.person,
                    DropdownButtonFormField<String>(
                      value: _selectedUser,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const ['All', 'User 1', 'User 2', 'User 3']
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedUser = value!;
                        });
                      },
                    ),
                  ),

                  // Cash Register Filter
                  _buildDialogFilterRow(
                    'Cash Register',
                    Icons.point_of_sale,
                    DropdownButtonFormField<String>(
                      value: _selectedCashRegister,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const ['All', 'Register 1', 'Register 2']
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCashRegister = value!;
                        });
                      },
                    ),
                  ),

                  // Product Filter
                  _buildDialogFilterRow(
                    'Product',
                    Icons.shopping_bag,
                    DropdownButtonFormField<String>(
                      value: _selectedProduct,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          const ['All', 'Product 1', 'Product 2', 'Product 3']
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedProduct = value!;
                        });
                      },
                    ),
                  ),

                  // Product Group Filter
                  _buildDialogFilterRow(
                    'Product Group',
                    Icons.category,
                    DropdownButtonFormField<String>(
                      value: _selectedProductGroup,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const ['Products', 'Group 1', 'Group 2', 'Group 3']
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedProductGroup = value!;
                        });
                      },
                    ),
                  ),

                  // Include Subgroups Filter
                  _buildDialogFilterRow(
                    'Include Subgroups',
                    Icons.account_tree,
                    Row(
                      children: [
                        Switch(
                          value: _includeSubgroups,
                          onChanged: (value) {
                            setDialogState(() {
                              _includeSubgroups = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(_includeSubgroups ? 'Enabled' : 'Disabled'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Summary:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('• Date Range: ${_getDateRangeText()}'),
                        Text('• User: $_selectedUser'),
                        Text('• Cash Register: $_selectedCashRegister'),
                        Text('• Product: $_selectedProduct'),
                        Text('• Product Group: $_selectedProductGroup'),
                        Text(
                          '• Include Subgroups: ${_includeSubgroups ? "Yes" : "No"}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedUser = 'All';
                  _selectedCashRegister = 'All';
                  _selectedProduct = 'All';
                  _selectedProductGroup = 'Products';
                  _includeSubgroups = true;
                  final now = DateTime.now();
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(now.year, now.month, 1),
                    end: now,
                  );
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showReportWithSelectedFilters(reportName);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportWithSelectedFilters(String reportName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('$reportName Report')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applied Filters Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Applied Filters:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('• Date Range: ${_getDateRangeText()}'),
                      Text('• User: $_selectedUser'),
                      Text('• Cash Register: $_selectedCashRegister'),
                      Text('• Product: $_selectedProduct'),
                      Text('• Product Group: $_selectedProductGroup'),
                      Text(
                        '• Include Subgroups: ${_includeSubgroups ? "Yes" : "No"}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Report Data Section
                const Text(
                  'Report Data:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Sales',
                        '\$${_calculateTotalSales(reportName)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Items Sold',
                        '${_calculateItemsSold(reportName)}',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Profit',
                        '\$${_calculateProfit(reportName)}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Transactions',
                        '${_calculateTransactions(reportName)}',
                        Icons.receipt,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Detailed Data Table
                const Text(
                  'Detailed Breakdown:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Profit')),
                    ],
                    rows: _generateReportData(reportName),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('$reportName exported to PDF successfully!');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('$reportName exported to Excel successfully!');
            },
            icon: const Icon(Icons.grid_on),
            label: const Text('Export Excel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _generateReportData(String reportName) {
    // Generate sample data based on filters
    List<DataRow> rows = [];
    for (int i = 1; i <= 5; i++) {
      rows.add(
        DataRow(
          cells: [
            DataCell(
              Text(
                '${DateTime.now().day - i}/${DateTime.now().month}/${DateTime.now().year}',
              ),
            ),
            DataCell(Text('${reportName.split(' ').first} $i')),
            DataCell(Text('${10 + i}')),
            DataCell(Text('\$${(100 + i * 25).toStringAsFixed(2)}')),
            DataCell(Text('\$${(30 + i * 8).toStringAsFixed(2)}')),
          ],
        ),
      );
    }
    return rows;
  }

  String _getDateRangeText() {
    if (_selectedDateRange != null) {
      return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
          '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}';
    }
    return 'Not selected';
  }

  int _calculateTotalSales(String reportName) {
    return 1000 +
        (reportName.length * 100) +
        (_selectedUser == 'All' ? 0 : 500);
  }

  int _calculateItemsSold(String reportName) {
    return 50 + (reportName.length * 5) + (_selectedProduct == 'All' ? 0 : 25);
  }

  int _calculateProfit(String reportName) {
    return 300 + (reportName.length * 30) + (_includeSubgroups ? 100 : 0);
  }

  int _calculateTransactions(String reportName) {
    return 15 +
        (reportName.length * 2) +
        (_selectedCashRegister == 'All' ? 0 : 10);
  }

  Widget _buildDialogFilterRow(String label, IconData icon, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          control,
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showReportPreview(String reportName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reportName),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This is a preview of the report.'),
                const SizedBox(height: 16),
                if (_selectedDateRange != null)
                  Text(
                    'Date Range: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
                    '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 16),
                const Text('Sample report data would be displayed here.'),
                const SizedBox(height: 16),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        const DataCell(Text('Total Sales')),
                        DataCell(Text('\$${1000 + (reportName.length * 100)}')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Items Sold')),
                        DataCell(Text('${50 + (reportName.length * 5)}')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Profit')),
                        DataCell(Text('\$${300 + (reportName.length * 30)}')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('$reportName exported successfully!');
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _handleDownloadReport(String reportName) async {
    setState(() {
      _downloadingReports.add(reportName);
    });

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _downloadingReports.remove(reportName);
    });

    _showSnackBar('$reportName downloaded successfully!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
