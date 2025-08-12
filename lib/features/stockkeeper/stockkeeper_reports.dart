import 'package:flutter/material.dart';
import 'package:pos_system/widget/stock_Keeper_Report/category_filter_bar.dart';
import 'package:pos_system/widget/stock_Keeper_Report/report_card.dart';
import 'package:pos_system/widget/stock_Keeper_Report/report_preview_dialog.dart';
import 'package:pos_system/widget/stock_Keeper_Report/section_header.dart';

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports> {
  // --- STATE VARIABLES ---
  DateTimeRange? _selectedDateRange;
  String _selectedUser = 'All';
  String _selectedCashRegister = 'All';
  String _selectedProduct = 'All';
  String _selectedProductGroup = 'Products';
  String _selectedSupplier = 'All';
  bool _includeSubgroups = true;
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

  // --- LIFECYCLE METHODS ---
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(isMobile),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFilteredContent(isMobile),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return PreferredSize(
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
          title: Text(
            'Reports Dashboard',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [_buildAppBarActions(isMobile)],
          bottom: CategoryFilterBar(
            selectedCategory: _selectedCategory,
            categories: _categories,
            getCategoryIcon: _getCategoryIcon,
            isMobile: isMobile,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarActions(bool isMobile) {
    return Container(
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
              icon: Icon(Icons.picture_as_pdf, color: Colors.grey[700]),
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
                if (value == 'pdf')
                  _showSnackBar('Exporting to PDF...');
                else if (value == 'excel')
                  _showSnackBar('Exporting to Excel...');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                const PopupMenuItem(
                  value: 'excel',
                  child: Text('Export Excel'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- LOGIC & DATA METHODS ---

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

  // --- FILTER LOGIC METHODS ---
  bool _shouldShowUserFilter(String reportName) {
    // Exclude user filter for these reports
    return ![
      'Expiration Date',
      'Transaction History',
      'Reorder Product List',
      'Low Stock Warning',
    ].contains(reportName);
  }

  bool _shouldShowSupplierFilter(String reportName) {
    // Show supplier filter only for purchase-related reports
    return [
      'Purchase Products',
      'Suppliers',
      'Unpaid Purchase',
      'Purchase Discounts',
      'Purchased Items Discounts',
      'Purchase Invoice List',
      'Expiration Date',
    ].contains(reportName);
  }

  bool _shouldShowCashRegisterFilter(String reportName) {
    // Exclude cash register for purchase and some other reports
    return ![
      'Purchase Products',
      'Suppliers',
      'Unpaid Purchase',
      'Purchase Discounts',
      'Purchased Items Discounts',
      'Purchase Invoice List',
      'Expiration Date',
      'Stock Return Products',
      'Loss and Damage Products',
      'Transaction History',
      'Reorder Product List',
      'Low Stock Warning',
    ].contains(reportName);
  }

  bool _shouldShowProductFilters(String reportName) {
    // Exclude product filters for payment-related and summary reports
    return ![
      'Payment Types',
      'Payment Types by Users',
      'Payment Types by Customers',
      'Daily Sales',
      'Hourly Sales',
      'Table/Order Number',
      'Unpaid Sales',
      'Starting Cash Entries',
      'Discounts Granted',
      'Unpaid Purchase',
      'Purchase Discounts',
      'Transaction History',
    ].contains(reportName);
  }

  List<Widget> _buildFilteredContent(bool isMobile) {
    // THIS IS THE COMPLETE DATA MAP
    final reportData = {
      'Sales Reports': [
        {
          'title': 'Products',
          'icon': Icons.shopping_bag,
          'colors': [Colors.blue, Colors.lightBlue],
        },
        {
          'title': 'Product Groups',
          'icon': Icons.category,
          'colors': [Colors.purple, Colors.deepPurple],
        },
        {
          'title': 'Customers',
          'icon': Icons.people,
          'colors': [Colors.green, Colors.teal],
        },
        {
          'title': 'Tax Rates',
          'icon': Icons.receipt,
          'colors': [Colors.orange, Colors.deepOrange],
        },
        {
          'title': 'Users',
          'icon': Icons.person,
          'colors': [Colors.pink, Colors.pinkAccent],
        },
        {
          'title': 'Item List',
          'icon': Icons.list,
          'colors': [Colors.indigo, Colors.indigoAccent],
        },
        {
          'title': 'Payment Types',
          'icon': Icons.payment,
          'colors': [Colors.cyan, Colors.cyanAccent],
        },
        {
          'title': 'Payment Types by Users',
          'icon': Icons.account_balance_wallet,
          'colors': [Colors.amber, Colors.orange],
        },
        {
          'title': 'Payment Types by Customers',
          'icon': Icons.credit_card,
          'colors': [Colors.lightGreen, Colors.green],
        },
        {
          'title': 'Refunds',
          'icon': Icons.assignment_return,
          'colors': [Colors.red, Colors.redAccent],
        },
        {
          'title': 'Invoice List',
          'icon': Icons.description,
          'colors': [Colors.blueGrey, Colors.grey],
        },
        {
          'title': 'Daily Sales',
          'icon': Icons.calendar_today,
          'colors': [Colors.teal, Colors.tealAccent],
        },
        {
          'title': 'Hourly Sales',
          'icon': Icons.access_time,
          'colors': [Colors.deepPurple, Colors.purpleAccent],
        },
        {
          'title': 'Hourly Sales by Product Groups',
          'icon': Icons.timeline,
          'colors': [Colors.lightBlue, Colors.blue],
        },
        {
          'title': 'Table/Order Number',
          'icon': Icons.table_chart,
          'colors': [Colors.orange, Colors.deepOrange],
        },
        {
          'title': 'Profit & Margin',
          'icon': Icons.attach_money,
          'colors': [Colors.green, Colors.lightGreen],
        },
        {
          'title': 'Unpaid Sales',
          'icon': Icons.money_off,
          'colors': [Colors.red, Colors.pink],
        },
        {
          'title': 'Starting Cash Entries',
          'icon': Icons.point_of_sale,
          'colors': [Colors.blue, Colors.indigo],
        },
        {
          'title': 'Voided Items',
          'icon': Icons.verified,
          'colors': [Colors.green, Colors.teal],
        },
        {
          'title': 'Discounts Granted',
          'icon': Icons.discount,
          'colors': [Colors.purple, Colors.deepPurpleAccent],
        },
        {
          'title': 'Items Discounts',
          'icon': Icons.percent,
          'colors': [Colors.amber, Colors.orange],
        },
      ],
      'Purchase Reports': [
        {
          'title': 'Purchase Products',
          'icon': Icons.shopping_cart,
          'colors': [Colors.blue, Colors.lightBlue],
        },
        {
          'title': 'Suppliers',
          'icon': Icons.local_shipping,
          'colors': [Colors.green, Colors.teal],
        },
        {
          'title': 'Unpaid Purchase',
          'icon': Icons.money_off,
          'colors': [Colors.red, Colors.pink],
        },
        {
          'title': 'Purchase Discounts',
          'icon': Icons.discount,
          'colors': [Colors.purple, Colors.deepPurple],
        },
        {
          'title': 'Purchased Items Discounts',
          'icon': Icons.percent,
          'colors': [Colors.amber, Colors.orange],
        },
        {
          'title': 'Purchase Invoice List',
          'icon': Icons.description,
          'colors': [Colors.blueGrey, Colors.grey],
        },
        {
          'title': 'Tax Rates',
          'icon': Icons.receipt,
          'colors': [Colors.orange, Colors.deepOrange],
        },
        {
          'title': 'Expiration Date',
          'icon': Icons.calendar_today,
          'colors': [Colors.teal, Colors.tealAccent],
        },
      ],
      'Stock Return': [
        {
          'title': 'Stock Return Products',
          'icon': Icons.assignment_return,
          'colors': [Colors.red, Colors.pink],
        },
      ],
      'Loss and Damage': [
        {
          'title': 'Loss and Damage Products',
          'icon': Icons.warning,
          'colors': [Colors.orange, Colors.deepOrange],
        },
      ],
      'Finance': [
        {
          'title': 'Transaction History',
          'icon': Icons.history,
          'colors': [Colors.blueGrey, Colors.grey],
        },
      ],
      'Stock Control': [
        {
          'title': 'Reorder Product List',
          'icon': Icons.repeat,
          'colors': [Colors.green, Colors.teal],
        },
        {
          'title': 'Low Stock Warning',
          'icon': Icons.notifications_active,
          'colors': [Colors.red, Colors.pink],
        },
      ],
    };

    List<Widget> content = [];

    reportData.forEach((category, reports) {
      if (_selectedCategory == 'All' || _selectedCategory == category) {
        content.addAll([
          SectionHeader(
            title: category,
            icon: _getCategoryIcon(category),
            reportCount: reports.length,
          ),
          const SizedBox(height: 10),
          _buildReportGrid(reports, isMobile),
          const SizedBox(height: 20),
        ]);
      }
    });

    return content;
  }

  Widget _buildReportGrid(List<Map<String, dynamic>> reports, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final report = reports[index];
        return ReportCard(
          title: report['title'],
          icon: report['icon'],
          colors: report['colors'],
          onFiltersTap: () => _showFiltersDialog(report['title']),
        );
      },
    );
  }

  // --- DIALOGS & HELPERS ---

  void _showFiltersDialog(String reportName) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$reportName - Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Dialog Content (Scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Filter (Always shown)
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(_getDateRangeText())),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // User Filter (Conditionally shown)
                        if (_shouldShowUserFilter(reportName))
                          _buildDialogFilterRow(
                            'User',
                            Icons.person,
                            _buildDropdown(
                              value: _selectedUser,
                              items: ['All', 'User 1', 'User 2', 'User 3'],
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedUser = value!;
                                });
                              },
                            ),
                          ),

                        // Supplier Filter (Conditionally shown)
                        if (_shouldShowSupplierFilter(reportName))
                          _buildDialogFilterRow(
                            'Supplier',
                            Icons.local_shipping,
                            _buildDropdown(
                              value: _selectedSupplier,
                              items: [
                                'All',
                                'Alpha Suppliers Ltd',
                                'Beta Distribution Co',
                                'Gamma Wholesale Inc',
                                'Delta Trading House',
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedSupplier = value!;
                                });
                              },
                            ),
                          ),

                        // Cash Register Filter (Conditionally shown)
                        if (_shouldShowCashRegisterFilter(reportName))
                          _buildDialogFilterRow(
                            'Cash Register',
                            Icons.point_of_sale,
                            _buildDropdown(
                              value: _selectedCashRegister,
                              items: [
                                'All',
                                'Register 1',
                                'Register 2',
                                'Register 3',
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedCashRegister = value!;
                                });
                              },
                            ),
                          ),

                        // Product Filters (Conditionally shown)
                        if (_shouldShowProductFilters(reportName)) ...[
                          _buildDialogFilterRow(
                            'Product',
                            Icons.shopping_bag,
                            _buildDropdown(
                              value: _selectedProduct,
                              items: [
                                'All',
                                'Product 1',
                                'Product 2',
                                'Product 3',
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedProduct = value!;
                                });
                              },
                            ),
                          ),

                          _buildDialogFilterRow(
                            'Product Group',
                            Icons.category,
                            _buildDropdown(
                              value: _selectedProductGroup,
                              items: [
                                'Products',
                                'Electronics',
                                'Clothing',
                                'Food & Beverages',
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedProductGroup = value!;
                                });
                              },
                            ),
                          ),

                          _buildDialogFilterRow(
                            'Include Subgroups',
                            Icons.account_tree,
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Filter Summary
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
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
                              if (_shouldShowUserFilter(reportName))
                                Text('• User: $_selectedUser'),
                              if (_shouldShowSupplierFilter(reportName))
                                Text('• Supplier: $_selectedSupplier'),
                              if (_shouldShowCashRegisterFilter(reportName))
                                Text('• Cash Register: $_selectedCashRegister'),
                              if (_shouldShowProductFilters(reportName)) ...[
                                Text('• Product: $_selectedProduct'),
                                Text('• Product Group: $_selectedProductGroup'),
                                Text(
                                  '• Include Subgroups: ${_includeSubgroups ? "Yes" : "No"}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dialog Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _resetFilters();
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      Row(
                        children: [
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
                          ),
                        ],
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

  Widget _buildDialogFilterRow(String label, IconData icon, Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          control,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _resetFilters() {
    _selectedUser = 'All';
    _selectedSupplier = 'All';
    _selectedCashRegister = 'All';
    _selectedProduct = 'All';
    _selectedProductGroup = 'Products';
    _includeSubgroups = true;
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  void _showReportWithSelectedFilters(String reportName) {
    Map<String, dynamic> filters = {'Date Range': _getDateRangeText()};

    // Add filters based on what should be shown for this report
    if (_shouldShowUserFilter(reportName)) {
      filters['User'] = _selectedUser;
    }
    if (_shouldShowSupplierFilter(reportName)) {
      filters['Supplier'] = _selectedSupplier;
    }
    if (_shouldShowCashRegisterFilter(reportName)) {
      filters['Cash Register'] = _selectedCashRegister;
    }
    if (_shouldShowProductFilters(reportName)) {
      filters['Product'] = _selectedProduct;
      filters['Product Group'] = _selectedProductGroup;
      filters['Include Subgroups'] = _includeSubgroups ? "Yes" : "No";
    }

    showDialog(
      context: context,
      builder: (context) =>
          ReportPreviewDialog(reportName: reportName, filters: filters),
    );
  }

  String _getDateRangeText() {
    if (_selectedDateRange != null) {
      return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
          '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}';
    }
    return 'Not selected';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
