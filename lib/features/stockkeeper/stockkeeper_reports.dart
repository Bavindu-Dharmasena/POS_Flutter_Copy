// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/widget/stock_Keeper_Report/category_filter_bar.dart';
import 'package:pos_system/widget/stock_Keeper_Report/ModernReportCard.dart';
import 'package:pos_system/widget/stock_Keeper_Report/report_preview_dialog.dart';
import 'package:pos_system/widget/stock_Keeper_Report/ModernSectionHeader.dart';

class StockKeeperReports extends StatefulWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  State<StockKeeperReports> createState() => _StockKeeperReportsState();
}

class _StockKeeperReportsState extends State<StockKeeperReports>
    with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  DateTimeRange? _selectedDateRange;
  String _selectedUser = 'All';
  String _selectedCashRegister = 'All';
  String _selectedProduct = 'All';
  String _selectedProductGroup = 'Products';
  String _selectedSupplier = 'All';
  bool _includeSubgroups = true;
  String _selectedCategory = 'All';
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutExpo),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F23),
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(isMobile),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: isMobile ? 16.0 : 24.0,
                  right: isMobile ? 16.0 : 24.0,
                  top: isMobile ? 140 : 160,
                  bottom: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildFilteredContent(isMobile),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isMobile) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isMobile ? 130 : 150),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F23).withOpacity(0.95),
              const Color(0xFF0F0F23).withOpacity(0.8),
              const Color(0xFF0F0F23).withOpacity(0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6), Color(0xFF00BCD4)],
            ).createShader(bounds),
            child: Text(
              'Reports Dashboard',
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [_buildModernAppBarActions(isMobile)],
          bottom: ModernCategoryFilterBar(
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

  Widget _buildModernAppBarActions(bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassButton(
            icon: Icons.print_outlined,
            onPressed: () => _showSnackBar('Printing report...'),
            tooltip: 'Print Report (Enter)',
            isMobile: isMobile,
          ),
          if (!isMobile) ...[
            _buildGlassButton(
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () => _showSnackBar('Exporting to PDF...'),
              tooltip: 'Export to PDF (Enter)',
              isMobile: isMobile,
            ),
            _buildGlassButton(
              icon: Icons.grid_on_outlined,
              onPressed: () => _showSnackBar('Exporting to Excel...'),
              tooltip: 'Export to Excel (Enter)',
              isMobile: isMobile,
            ),
          ] else
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 20,
              ),
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'pdf') {
                  _showSnackBar('Exporting to PDF...');
                } else if (value == 'excel') {
                  _showSnackBar('Exporting to Excel...');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 12),
                      Text('Export PDF', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.grid_on_outlined, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text(
                        'Export Excel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isMobile,
  }) {
    return Tooltip(
      message: tooltip,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            onPressed();
          }
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: isMobile ? 18 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC & DATA METHODS ---
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.dashboard_outlined;
      case 'Sales Reports':
        return Icons.trending_up_outlined;
      case 'Purchase Reports':
        return Icons.shopping_cart_outlined;
      case 'Stock Return':
        return Icons.assignment_return_outlined;
      case 'Loss and Damage':
        return Icons.warning_amber_outlined;
      case 'Finance':
        return Icons.account_balance_wallet_outlined;
      case 'Stock Control':
        return Icons.inventory_2_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  // --- FILTER LOGIC METHODS (same as original) ---
  bool _shouldShowUserFilter(String reportName) {
    return ![
      'Expiration Date',
      'Transaction History',
      'Reorder Product List',
      'Low Stock Warning',
    ].contains(reportName);
  }

  bool _shouldShowSupplierFilter(String reportName) {
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
    final reportData = {
      'Sales Reports': [
        {
          'title': 'Products',
          'icon': Icons.shopping_bag_outlined,
          'colors': [const Color(0xFF64FFDA), const Color(0xFF1DE9B6)],
        },
        {
          'title': 'Product Groups',
          'icon': Icons.category_outlined,
          'colors': [const Color(0xFFBB86FC), const Color(0xFF9C27B0)],
        },
        {
          'title': 'Customers',
          'icon': Icons.people_outline,
          'colors': [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)],
        },
        {
          'title': 'Tax Rates',
          'icon': Icons.receipt_long_outlined,
          'colors': [const Color(0xFFFFB74D), const Color(0xFFFF9800)],
        },
        {
          'title': 'Users',
          'icon': Icons.person_outline,
          'colors': [const Color(0xFFF48FB1), const Color(0xFFE91E63)],
        },
        {
          'title': 'Item List',
          'icon': Icons.list_alt_outlined,
          'colors': [const Color(0xFF9FA8DA), const Color(0xFF3F51B5)],
        },
        {
          'title': 'Payment Types',
          'icon': Icons.payment_outlined,
          'colors': [const Color(0xFF80DEEA), const Color(0xFF00BCD4)],
        },
        {
          'title': 'Payment Types by Users',
          'icon': Icons.account_balance_wallet_outlined,
          'colors': [const Color(0xFFFFD54F), const Color(0xFFFFC107)],
        },
        {
          'title': 'Payment Types by Customers',
          'icon': Icons.credit_card_outlined,
          'colors': [const Color(0xFFC8E6C9), const Color(0xFF4CAF50)],
        },
        {
          'title': 'Refunds',
          'icon': Icons.assignment_return_outlined,
          'colors': [const Color(0xFFEF9A9A), const Color(0xFFF44336)],
        },
        {
          'title': 'Invoice List',
          'icon': Icons.description_outlined,
          'colors': [const Color(0xFFB0BEC5), const Color(0xFF607D8B)],
        },
        {
          'title': 'Daily Sales',
          'icon': Icons.calendar_today_outlined,
          'colors': [const Color(0xFF80CBC4), const Color(0xFF009688)],
        },
        {
          'title': 'Hourly Sales',
          'icon': Icons.access_time_outlined,
          'colors': [const Color(0xFFCE93D8), const Color(0xFF9C27B0)],
        },
        {
          'title': 'Hourly Sales by Product Groups',
          'icon': Icons.timeline_outlined,
          'colors': [const Color(0xFF81D4FA), const Color(0xFF03A9F4)],
        },
        {
          'title': 'Table/Order Number',
          'icon': Icons.table_chart_outlined,
          'colors': [const Color(0xFFFFCC02), const Color(0xFFFF9800)],
        },
        {
          'title': 'Profit & Margin',
          'icon': Icons.attach_money_outlined,
          'colors': [const Color(0xFF9CCC65), const Color(0xFF689F38)],
        },
        {
          'title': 'Unpaid Sales',
          'icon': Icons.money_off_outlined,
          'colors': [const Color(0xFFE57373), const Color(0xFFD32F2F)],
        },
        {
          'title': 'Starting Cash Entries',
          'icon': Icons.point_of_sale_outlined,
          'colors': [const Color(0xFF7986CB), const Color(0xFF3F51B5)],
        },
        {
          'title': 'Voided Items',
          'icon': Icons.verified_outlined,
          'colors': [const Color(0xFF4DB6AC), const Color(0xFF00695C)],
        },
        {
          'title': 'Discounts Granted',
          'icon': Icons.discount_outlined,
          'colors': [const Color(0xFFBA68C8), const Color(0xFF8E24AA)],
        },
        {
          'title': 'Items Discounts',
          'icon': Icons.percent_outlined,
          'colors': [const Color(0xFFFFA726), const Color(0xFFEF6C00)],
        },
      ],
      'Purchase Reports': [
        {
          'title': 'Purchase Products',
          'icon': Icons.shopping_cart_outlined,
          'colors': [const Color(0xFF64FFDA), const Color(0xFF00BCD4)],
        },
        {
          'title': 'Suppliers',
          'icon': Icons.local_shipping_outlined,
          'colors': [const Color(0xFF81C784), const Color(0xFF388E3C)],
        },
        {
          'title': 'Unpaid Purchase',
          'icon': Icons.money_off_outlined,
          'colors': [const Color(0xFFE57373), const Color(0xFFD32F2F)],
        },
        {
          'title': 'Purchase Discounts',
          'icon': Icons.discount_outlined,
          'colors': [const Color(0xFFBA68C8), const Color(0xFF7B1FA2)],
        },
        {
          'title': 'Purchased Items Discounts',
          'icon': Icons.percent_outlined,
          'colors': [const Color(0xFFFFA726), const Color(0xFFE65100)],
        },
        {
          'title': 'Purchase Invoice List',
          'icon': Icons.description_outlined,
          'colors': [const Color(0xFFB0BEC5), const Color(0xFF546E7A)],
        },
        {
          'title': 'Tax Rates',
          'icon': Icons.receipt_long_outlined,
          'colors': [const Color(0xFFFFB74D), const Color(0xFFFF6F00)],
        },
        {
          'title': 'Expiration Date',
          'icon': Icons.calendar_today_outlined,
          'colors': [const Color(0xFF4DB6AC), const Color(0xFF00695C)],
        },
      ],
      'Stock Return': [
        {
          'title': 'Stock Return Products',
          'icon': Icons.assignment_return_outlined,
          'colors': [const Color(0xFFE57373), const Color(0xFFD32F2F)],
        },
      ],
      'Loss and Damage': [
        {
          'title': 'Loss and Damage Products',
          'icon': Icons.warning_amber_outlined,
          'colors': [const Color(0xFFFFB74D), const Color(0xFFE65100)],
        },
      ],
      'Finance': [
        {
          'title': 'Transaction History',
          'icon': Icons.history_outlined,
          'colors': [const Color(0xFF90A4AE), const Color(0xFF455A64)],
        },
      ],
      'Stock Control': [
        {
          'title': 'Reorder Product List',
          'icon': Icons.repeat_outlined,
          'colors': [const Color(0xFF81C784), const Color(0xFF2E7D32)],
        },
        {
          'title': 'Low Stock Warning',
          'icon': Icons.notifications_active_outlined,
          'colors': [const Color(0xFFE57373), const Color(0xFFC62828)],
        },
      ],
    };

    List<Widget> content = [];

    reportData.forEach((category, reports) {
      if (_selectedCategory == 'All' || _selectedCategory == category) {
        content.addAll([
          ModernSectionHeader(
            title: category,
            icon: _getCategoryIcon(category),
            reportCount: reports.length,
          ),
          const SizedBox(height: 16),
          _buildModernReportGrid(reports, isMobile),
          const SizedBox(height: 32),
        ]);
      }
    });

    return content;
  }

  Widget _buildModernReportGrid(
    List<Map<String, dynamic>> reports,
    bool isMobile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 1.3;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.4;
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
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final report = reports[index];
        return ModernReportCard(
          title: report['title'],
          icon: report['icon'],
          colors: report['colors'],
          index: index,
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
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 24,
            ),
            child: Container(
              width: isMobile ? double.infinity : 520,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A2E).withOpacity(0.95),
                    const Color(0xFF16213E).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modern Dialog Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF64FFDA).withOpacity(0.1),
                          const Color(0xFF1DE9B6).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_outlined,
                            color: Color(0xFF0F0F23),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Filters',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reportName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dialog Content (Scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Range Filter
                          _buildModernFilterRow(
                            'Date Range',
                            Icons.date_range_outlined,
                            RawKeyboardListener(
                              focusNode: FocusNode(),
                              onKey: (RawKeyEvent event) {
                                if (event is RawKeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter) {
                                  _openDateRangePicker(setDialogState);
                                }
                              },
                              child: InkWell(
                                onTap: () =>
                                    _openDateRangePicker(setDialogState),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getDateRangeText(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 20,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Conditional Filters (same logic as original)
                          if (_shouldShowUserFilter(reportName))
                            _buildModernFilterRow(
                              'User',
                              Icons.person_outline,
                              _buildModernDropdown(
                                value: _selectedUser,
                                items: ['All', 'User 1', 'User 2', 'User 3'],
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedUser = value!;
                                  });
                                },
                              ),
                            ),

                          if (_shouldShowSupplierFilter(reportName))
                            _buildModernFilterRow(
                              'Supplier',
                              Icons.local_shipping_outlined,
                              _buildModernDropdown(
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

                          if (_shouldShowCashRegisterFilter(reportName))
                            _buildModernFilterRow(
                              'Cash Register',
                              Icons.point_of_sale_outlined,
                              _buildModernDropdown(
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

                          // Product Filters
                          if (_shouldShowProductFilters(reportName)) ...[
                            _buildModernFilterRow(
                              'Product',
                              Icons.shopping_bag_outlined,
                              _buildModernDropdown(
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

                            _buildModernFilterRow(
                              'Product Group',
                              Icons.category_outlined,
                              _buildModernDropdown(
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

                            _buildModernFilterRow(
                              'Include Subgroups',
                              Icons.account_tree_outlined,
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
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
                                      activeColor: const Color(0xFF64FFDA),
                                      activeTrackColor: const Color(
                                        0xFF64FFDA,
                                      ).withOpacity(0.3),
                                      inactiveThumbColor: Colors.white
                                          .withOpacity(0.6),
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.1),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _includeSubgroups
                                          ? 'Enabled'
                                          : 'Disabled',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Filter Summary
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF64FFDA).withOpacity(0.1),
                                  const Color(0xFF1DE9B6).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF64FFDA).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.summarize_outlined,
                                      color: const Color(0xFF64FFDA),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Filter Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildSummaryItem(
                                  'Date Range',
                                  _getDateRangeText(),
                                ),
                                if (_shouldShowUserFilter(reportName))
                                  _buildSummaryItem('User', _selectedUser),
                                if (_shouldShowSupplierFilter(reportName))
                                  _buildSummaryItem(
                                    'Supplier',
                                    _selectedSupplier,
                                  ),
                                if (_shouldShowCashRegisterFilter(reportName))
                                  _buildSummaryItem(
                                    'Cash Register',
                                    _selectedCashRegister,
                                  ),
                                if (_shouldShowProductFilters(reportName)) ...[
                                  _buildSummaryItem(
                                    'Product',
                                    _selectedProduct,
                                  ),
                                  _buildSummaryItem(
                                    'Product Group',
                                    _selectedProductGroup,
                                  ),
                                  _buildSummaryItem(
                                    'Include Subgroups',
                                    _includeSubgroups ? "Yes" : "No",
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter) {
                                setDialogState(() {
                                  _resetFilters();
                                });
                              }
                            },
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  _resetFilters();
                                });
                              },
                              icon: const Icon(
                                Icons.refresh_outlined,
                                size: 18,
                              ),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.8),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter) {
                                Navigator.pop(context);
                                _showReportWithSelectedFilters(reportName);
                              }
                            },
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showReportWithSelectedFilters(reportName);
                              },
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: const Text('Generate Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64FFDA),
                                foregroundColor: const Color(0xFF0F0F23),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
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
      ),
    );
  }

  Future<void> _openDateRangePicker(Function setDialogState) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF64FFDA),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setDialogState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Widget _buildModernFilterRow(String label, IconData icon, Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF64FFDA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF64FFDA)),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          control,
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          // Trigger dropdown open
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF64FFDA),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
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
      builder: (context) => RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        },
        child: ReportPreviewDialog(reportName: reportName, filters: filters),
      ),
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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Modern Category Filter Bar Widget
class ModernCategoryFilterBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String selectedCategory;
  final List<String> categories;
  final IconData Function(String) getCategoryIcon;
  final bool isMobile;
  final Function(String) onCategorySelected;

  const ModernCategoryFilterBar({
    Key? key,
    required this.selectedCategory,
    required this.categories,
    required this.getCategoryIcon,
    required this.isMobile,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  onCategorySelected(category);
                }
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onCategorySelected(category),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(category),
                          size: isMobile ? 16 : 18,
                          color: isSelected
                              ? const Color(0xFF0F0F23)
                              : Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0F0F23)
                                : Colors.white.withOpacity(0.8),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}
