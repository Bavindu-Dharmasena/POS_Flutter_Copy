import 'package:flutter/material.dart';

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
  String _selectedSupplier = 'All';
  bool _includeSubgroups = true;
  final Set<String> _downloadingReports = {};

  // Add category filter
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Sales Reports',
    'Purchase Reports',
    'Stock Return',
    'Loss and Damage',
    'Finance',
    'Stock Control',
  ];

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
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 120 : 140),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'Reports Dashboard',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
               
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.print,
                        color: Colors.grey[700],
                        size: isMobile ? 20 : 24,
                      ),
                      onPressed: () => _showSnackBar('Printing report...'),
                      tooltip: 'Print Report',
                    ),
                    if (!isMobile) ...[
                      IconButton(
                        icon: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.grey[700],
                        ),
                        onPressed: () => _showSnackBar('Exporting to PDF...'),
                        tooltip: 'Export to PDF',
                      ),
                      IconButton(
                        icon: Icon(Icons.grid_on, color: Colors.grey[700]),
                        onPressed: () => _showSnackBar('Exporting to Excel...'),
                        tooltip: 'Export to Excel',
                      ),
                    ] else
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                        onSelected: (value) {
                          if (value == 'pdf') {
                            _showSnackBar('Exporting to PDF...');
                          } else if (value == 'excel') {
                            _showSnackBar('Exporting to Excel...');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf),
                                SizedBox(width: 8),
                                Text('Export PDF'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                Icon(Icons.grid_on),
                                SizedBox(width: 8),
                                Text('Export Excel'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(isMobile ? 50 : 60),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: isMobile ? 8 : 12),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[300]!
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                color: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[600],
                                size: isMobile ? 16 : 18,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue[700]
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFilteredContent(),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.dashboard;
      case 'Sales Reports':
        return Icons.trending_up;
      case 'Purchase Reports':
        return Icons.shopping_cart;
      case 'Stock Return':
        return Icons.assignment_return;
      case 'Loss and Damage':
        return Icons.warning;
      case 'Finance':
        return Icons.account_balance;
      case 'Stock Control':
        return Icons.inventory;
      default:
        return Icons.folder;
    }
  }

  List<Widget> _buildFilteredContent() {
    List<Widget> content = [];

    if (_selectedCategory == 'All' || _selectedCategory == 'Sales Reports') {
      content.addAll([
        _buildSectionHeader('Sales Reports'),
        const SizedBox(height: 10),
        _buildSalesReportsGrid(),
        const SizedBox(height: 20),
      ]);
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Purchase Reports') {
      content.addAll([
        _buildSectionHeader('Purchase Reports'),
        const SizedBox(height: 10),
        _buildPurchaseReportsGrid(),
        const SizedBox(height: 20),
      ]);
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Stock Return') {
      content.addAll([
        _buildSectionHeader('Stock Return'),
        const SizedBox(height: 10),
        _buildStockReturnGrid(),
        const SizedBox(height: 20),
      ]);
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Loss and Damage') {
      content.addAll([
        _buildSectionHeader('Loss and Damage'),
        const SizedBox(height: 10),
        _buildLossAndDamageGrid(),
        const SizedBox(height: 20),
      ]);
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Finance') {
      content.addAll([
        _buildSectionHeader('Finance'),
        const SizedBox(height: 10),
        _buildFinanceGrid(),
        const SizedBox(height: 20),
      ]);
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Stock Control') {
      content.addAll([
        _buildSectionHeader('Stock Control'),
        const SizedBox(height: 10),
        _buildStockControlGrid(),
      ]);
    }

    return content;
  }

  Widget _buildSalesReportsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 1; // Single column on mobile
      childAspectRatio = 1.2; // Adjusted ratio for mobile
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: childAspectRatio,
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
          title: 'Voided Items',
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
    );
  }

  Widget _buildPurchaseReportsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 1.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildReportCard(
          title: ' Purchase Products',
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
    );
  }

  Widget _buildStockReturnGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : (screenWidth > 800 ? 3 : 2),
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildReportCard(
          title: 'Stock Return Products',
          icon: Icons.assignment_return,
          colors: [Colors.red, Colors.pink],
        ),
      ],
    );
  }

  Widget _buildLossAndDamageGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : (screenWidth > 800 ? 3 : 2),
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildReportCard(
          title: 'Loss and Damage Products',
          icon: Icons.warning,
          colors: [Colors.orange, Colors.deepOrange],
        ),
      ],
    );
  }

  Widget _buildFinanceGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : (screenWidth > 800 ? 3 : 2),
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildReportCard(
          title: 'Transaction History',
          icon: Icons.history,
          colors: [Colors.blueGrey, Colors.grey],
        ),
      ],
    );
  }

  Widget _buildStockControlGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : (screenWidth > 800 ? 3 : 2),
      crossAxisSpacing: isMobile ? 8 : 16,
      mainAxisSpacing: isMobile ? 8 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
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
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
  }) {
    bool isDownloading = _downloadingReports.contains(title);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: colors.first.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            hoverColor: colors.first.withOpacity(0.04),
            splashColor: colors.first.withOpacity(0.12),
            onTap: () => _showFiltersDialog(title),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFFAFBFC).withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  if (isMobile)
                    // Mobile layout - stacked vertically
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.first.withOpacity(0.12),
                                colors.last.withOpacity(0.18),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.first.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, color: colors.first, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate detailed analytics',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  else
                    // Desktop/Tablet layout - side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.first.withOpacity(0.12),
                                colors.last.withOpacity(0.18),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.first.withOpacity(0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: colors.first, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Generate detailed analytics',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // Action buttons with responsive layout
                  if (isMobile)
                    // Mobile - stacked buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF8FAFC),
                                  const Color(0xFFE2E8F0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showFiltersDialog(title),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: const Color(0xFF475569),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filters',
                                      style: TextStyle(
                                        color: const Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.first, colors.last],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: isDownloading
                                    ? null
                                    : () => _handleDownloadReport(title),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isDownloading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.download_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDownloading ? 'Getting...' : 'Export',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Desktop/Tablet - side by side buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF8FAFC),
                                  const Color(0xFFE2E8F0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showFiltersDialog(title),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: const Color(0xFF475569),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Filters',
                                      style: TextStyle(
                                        color: const Color(0xFF475569),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.first, colors.last],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.first.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isDownloading
                                    ? null
                                    : () => _handleDownloadReport(title),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isDownloading)
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.white),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.download_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDownloading ? 'Getting...' : 'Export',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.15),
                            const Color(0xFF1D4ED8).withOpacity(0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(title),
                        color: const Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Business intelligence reports',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getReportCount(title)} reports',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.15),
                        const Color(0xFF1D4ED8).withOpacity(0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(title),
                    color: const Color(0xFF3B82F6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Business intelligence reports',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _getReportCount(title).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Add this method to fix the error
  int _getReportCount(String title) {
    switch (title) {
      case 'Sales Reports':
        return 21;
      case 'Purchase Reports':
        return 8;
      case 'Stock Return':
        return 1;
      case 'Loss and Damage':
        return 1;
      case 'Finance':
        return 1;
      case 'Stock Control':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF1A1D29),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keep all other existing methods unchanged...
  // (All the filter methods, dialog methods, etc. remain the same)

  // Add helper method to check if report is payment-related
  bool _isPaymentRelatedReport(String reportName) {
    return reportName == 'Payment Types' ||
        reportName == 'Payment Types by Users' ||
        reportName == 'Payment Types by Customers' ||
        reportName == 'Daily Sales' ||
        reportName == 'Hourly Sales' ||
        reportName == 'Table/Order Number' ||
        reportName == 'Unpaid Sales' ||
        reportName == 'Starting Cash Entries' ||
        reportName == 'Discounts Granted';
  }

  // Add helper method to check if report is purchase-related and should exclude cash register filter
  bool _isPurchaseProductReport(String reportName) {
    return reportName.trim() == 'Purchase Products' ||
        reportName.trim() == 'Suppliers' ||
        reportName.trim() == 'Unpaid Purchase' ||
        reportName.trim() == 'Purchase Discounts' ||
        reportName.trim() == 'Expiration Date' ||
        reportName.trim() == 'Stock Return Products' ||
        reportName.trim() == 'Loss and Damage Products' ||
        reportName.trim() == 'Transaction History' ||
        reportName.trim() == 'Reorder Product List' ||
        reportName.trim() == 'Low Stock Warning';
  }

  // Add helper method to check if report should exclude user filter
  bool _shouldExcludeUserFilter(String reportName) {
    return reportName.trim() == 'Expiration Date' ||
        reportName.trim() == 'Transaction History' ||
        reportName.trim() == 'Reorder Product List' ||
        reportName.trim() == 'Low Stock Warning';
  }

  // Add helper method to check if report should exclude product-related filters
  bool _shouldExcludeProductFilters(String reportName) {
    return _isPaymentRelatedReport(reportName) ||
        reportName.trim() == 'Unpaid Purchase' ||
        reportName.trim() == 'Purchase Discounts' ||
        reportName.trim() == 'Transaction History';
  }

  // Add helper method to check if report should exclude supplier filter
  bool _shouldExcludeSupplierFilter(String reportName) {
    return reportName.trim() == 'Loss and Damage Products' ||
        reportName.trim() == 'Starting Cash Entries' ||
        reportName.trim() == 'Voided Items';
  }

  void _showFiltersDialog(String reportName) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 24 : 40,
          ),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: isMobile ? double.infinity : 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Colors.blue,
                        size: isMobile ? 20 : 24,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Text(
                          '$reportName - Filters',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Report Filters',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Date Range Filter
                        _buildMobileDialogFilterRow(
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
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 12 : 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange != null
                                          ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
                                                '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                                          : 'Select Date Range',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: isMobile ? 14 : 16,
                                        color: _selectedDateRange != null
                                            ? Colors.black87
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    size: isMobile ? 18 : 20,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          isMobile,
                        ),

                        // User Filter - Hide for reports that exclude it
                        if (!_shouldExcludeUserFilter(reportName))
                          _buildMobileDialogFilterRow(
                            'User',
                            Icons.person,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUser,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                  items:
                                      const [
                                            'All',
                                            'User 1',
                                            'User 2',
                                            'User 3',
                                          ]
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
                            ),
                            isMobile,
                          ),

                        // Supplier Filter - Hide for reports that exclude it
                        if (!_shouldExcludeSupplierFilter(reportName))
                          _buildMobileDialogFilterRow(
                            'Supplier',
                            Icons.local_shipping,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSupplier,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                  items:
                                      const [
                                            'All',
                                            'Alpha Suppliers Ltd',
                                            'Beta Distribution Co',
                                            'Gamma Wholesale Inc',
                                            'Delta Trading House',
                                            'Epsilon Supply Chain',
                                            'Zeta Logistics Ltd',
                                            'Theta Manufacturing',
                                          ]
                                          .map(
                                            (item) => DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(
                                                item,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _selectedSupplier = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            isMobile,
                          ),

                        // Cash Register Filter - Hide for Purchase product reports
                        if (!_isPurchaseProductReport(reportName))
                          _buildMobileDialogFilterRow(
                            'Cash Register',
                            Icons.point_of_sale,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCashRegister,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                  items:
                                      const [
                                            'All',
                                            'Register 1',
                                            'Register 2',
                                            'Register 3',
                                            'Register 4',
                                          ]
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
                            ),
                            isMobile,
                          ),

                        // Product Filter - Hide for payment-related reports
                        if (!_shouldExcludeProductFilters(reportName))
                          _buildMobileDialogFilterRow(
                            'Product',
                            Icons.shopping_bag,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedProduct,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                  items:
                                      const [
                                            'All',
                                            'Product 1',
                                            'Product 2',
                                            'Product 3',
                                            'Product 4',
                                            'Product 5',
                                          ]
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
                            ),
                            isMobile,
                          ),

                        // Product Group Filter - Hide for payment-related reports
                        if (!_shouldExcludeProductFilters(reportName))
                          _buildMobileDialogFilterRow(
                            'Product Group',
                            Icons.category,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedProductGroup,
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                  items:
                                      const [
                                            'Products',
                                            'Electronics',
                                            'Clothing',
                                            'Food & Beverages',
                                            'Home & Garden',
                                            'Books & Media',
                                          ]
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
                            ),
                            isMobile,
                          ),

                        // Include Subgroups Filter - Hide for payment-related reports
                        if (!_shouldExcludeProductFilters(reportName))
                          _buildMobileDialogFilterRow(
                            'Include Subgroups',
                            Icons.account_tree,
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
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
                                  Text(
                                    _includeSubgroups ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isMobile,
                          ),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Filter Summary
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter Summary:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              SizedBox(height: isMobile ? 6 : 8),
                              Text(
                                '• Date Range: ${_getDateRangeText()}',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                              if (!_shouldExcludeUserFilter(reportName))
                                Text(
                                  '• User: $_selectedUser',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              if (!_shouldExcludeSupplierFilter(reportName))
                                Text(
                                  '• Supplier: $_selectedSupplier',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              if (!_isPurchaseProductReport(reportName))
                                Text(
                                  '• Cash Register: $_selectedCashRegister',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              if (!_shouldExcludeProductFilters(
                                reportName,
                              )) ...[
                                Text(
                                  '• Product: $_selectedProduct',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                Text(
                                  '• Product Group: $_selectedProductGroup',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                Text(
                                  '• Include Subgroups: ${_includeSubgroups ? "Yes" : "No"}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    if (!_shouldExcludeUserFilter(reportName)) {
                                      _selectedUser = 'All';
                                    }
                                    if (!_shouldExcludeSupplierFilter(
                                      reportName,
                                    )) {
                                      _selectedSupplier = 'All';
                                    }
                                    if (!_isPurchaseProductReport(reportName)) {
                                      _selectedCashRegister = 'All';
                                    }
                                    if (!_shouldExcludeProductFilters(
                                      reportName,
                                    )) {
                                      _selectedProduct = 'All';
                                      _selectedProductGroup = 'Products';
                                      _includeSubgroups = true;
                                    }
                                    final now = DateTime.now();
                                    _selectedDateRange = DateTimeRange(
                                      start: DateTime(now.year, now.month, 1),
                                      end: now,
                                    );
                                  });
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showReportWithSelectedFilters(
                                        reportName,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 18,
                                    ),
                                    label: const Text('Show Report'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (!_shouldExcludeUserFilter(reportName)) {
                                    _selectedUser = 'All';
                                  }
                                  if (!_shouldExcludeSupplierFilter(
                                    reportName,
                                  )) {
                                    _selectedSupplier = 'All';
                                  }
                                  if (!_isPurchaseProductReport(reportName)) {
                                    _selectedCashRegister = 'All';
                                  }
                                  if (!_shouldExcludeProductFilters(
                                    reportName,
                                  )) {
                                    _selectedProduct = 'All';
                                    _selectedProductGroup = 'Products';
                                    _includeSubgroups = true;
                                  }
                                  final now = DateTime.now();
                                  _selectedDateRange = DateTimeRange(
                                    start: DateTime(now.year, now.month, 1),
                                    end: now,
                                  );
                                });
                              },
                              child: const Text('Reset'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this new helper method for mobile-friendly filter rows
  Widget _buildMobileDialogFilterRow(
    String label,
    IconData icon,
    Widget control,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isMobile ? 18 : 20, color: Colors.blue),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          control,
        ],
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
                // Applied Filters Section - Updated to conditionally show Supplier and Cash Register
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
                      // Only show user for reports that allow it
                      if (!_shouldExcludeUserFilter(reportName))
                        Text('• User: $_selectedUser'),
                      // Only show supplier for reports that allow it
                      if (!_shouldExcludeSupplierFilter(reportName))
                        Text('• Supplier: $_selectedSupplier'),
                      // Only show cash register for non-Purchase product reports
                      if (!_isPurchaseProductReport(reportName))
                        Text('• Cash Register: $_selectedCashRegister'),
                      // Only show product-related filters for reports that allow them
                      if (!_shouldExcludeProductFilters(reportName)) ...[
                        Text('• Product: $_selectedProduct'),
                        Text('• Product Group: $_selectedProductGroup'),
                        Text(
                          '• Include Subgroups: ${_includeSubgroups ? "Yes" : "No"}',
                        ),
                      ],
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
                        _isPaymentRelatedReport(reportName)
                            ? 'Total Payments'
                            : 'Total Sales',
                        '\$${_calculateTotalSales(reportName)}',
                        _isPaymentRelatedReport(reportName)
                            ? Icons.payment
                            : Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        _isPaymentRelatedReport(reportName)
                            ? 'Payment Methods'
                            : 'Items Sold',
                        _isPaymentRelatedReport(reportName)
                            ? '${_calculatePaymentMethods(reportName)}'
                            : '${_calculateItemsSold(reportName)}',
                        _isPaymentRelatedReport(reportName)
                            ? Icons.credit_card
                            : Icons.shopping_cart,
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
                    columns: _isPaymentRelatedReport(reportName)
                        ? _getPaymentReportColumns(reportName)
                        : const [
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

  // Add method to get appropriate columns for payment reports
  List<DataColumn> _getPaymentReportColumns(String reportName) {
    if (reportName == 'Payment Types by Users') {
      return const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Transactions')),
        DataColumn(label: Text('Amount')),
      ];
    } else if (reportName == 'Payment Types by Customers') {
      return const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Transactions')),
        DataColumn(label: Text('Amount')),
      ];
    } else {
      return const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Transactions')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Fee')),
      ];
    }
  }

  // Update the _generateReportData method to handle all payment reports
  List<DataRow> _generateReportData(String reportName) {
    List<DataRow> rows = [];

    if (_isPaymentRelatedReport(reportName)) {
      // Generate Payment-related report data
      if (reportName == 'Payment Types by Users') {
        List<String> users = [
          'John Doe',
          'Jane Smith',
          'Mike Johnson',
          'Sarah Wilson',
          'Tom Brown',
        ];
        List<String> paymentMethods = [
          'Cash',
          'Credit Card',
          'Debit Card',
          'Digital Wallet',
          'Bank Transfer',
        ];

        for (int i = 0; i < users.length; i++) {
          rows.add(
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '${DateTime.now().day - i}/${DateTime.now().month}/${DateTime.now().year}',
                  ),
                ),
                DataCell(Text(users[i])),
                DataCell(Text(paymentMethods[i])),
                DataCell(Text('${15 + i * 3}')),
                DataCell(Text('\$${(300 + i * 120).toStringAsFixed(2)}')),
              ],
            ),
          );
        }
      } else if (reportName == 'Payment Types by Customers') {
        List<String> customers = [
          'ABC Corp',
          'XYZ Ltd',
          'Tech Solutions',
          'Global Inc',
          'Local Store',
        ];
        List<String> paymentMethods = [
          'Credit Card',
          'Bank Transfer',
          'Cash',
          'Digital Wallet',
          'Cheque',
        ];

        for (int i = 0; i < customers.length; i++) {
          rows.add(
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '${DateTime.now().day - i}/${DateTime.now().month}/${DateTime.now().year}',
                  ),
                ),
                DataCell(Text(customers[i])),
                DataCell(Text(paymentMethods[i])),
                DataCell(Text('${25 + i * 4}')),
                DataCell(Text('\$${(800 + i * 200).toStringAsFixed(2)}')),
              ],
            ),
          );
        }
      } else {
        // Regular Payment Types report
        List<String> paymentMethods = [
          'Cash',
          'Credit Card',
          'Debit Card',
          'Digital Wallet',
          'Bank Transfer',
        ];

        for (int i = 0; i < paymentMethods.length; i++) {
          rows.add(
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '${DateTime.now().day - i}/${DateTime.now().month}/${DateTime.now().year}',
                  ),
                ),
                DataCell(Text(paymentMethods[i])),
                DataCell(Text('${20 + i * 5}')),
                DataCell(Text('\$${(500 + i * 150).toStringAsFixed(2)}')),
                DataCell(Text('\$${(5 + i * 2).toStringAsFixed(2)}')),
              ],
            ),
          );
        }
      }
    } else {
      // Generate regular report data
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

  // Add new method for Payment Types specific calculation
  int _calculatePaymentMethods(String reportName) {
    return 5 +
        (reportName.length %
            3); // Cash, Credit Card, Debit Card, Digital Wallet, etc.
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
