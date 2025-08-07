import 'package:flutter/material.dart';

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
  final Set<String> _loadingReports = {};
  final Set<String> _downloadingReports = {};
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
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
        title: const Text(
          'Select report to view or print',
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
                // Quick info card
                _buildQuickInfoCard(),
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
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'daily',
                          title: 'Daily Report',
                          subtitle: 'View today\'s sales & transactions',
                          icon: Icons.today_outlined,
                          gradientColors: [
                            const Color(0xFF1e3c72),
                            const Color(0xFF2a5298),
                          ], // Deep Navy Blue
                          onViewTap: () =>
                              _handleViewReport('daily', 'Daily Report'),
                          onDownloadTap: () =>
                              _handleDownloadReport('daily', 'Daily Report'),
                        ),
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'weekly',
                          title: 'Weekly Report',
                          subtitle: 'Analyze weekly performance',
                          icon: Icons.view_week_outlined,
                          gradientColors: [
                            const Color(0xFF134e5e),
                            const Color(0xFF71b280),
                          ], // Dark Teal to Forest Green
                          onViewTap: () =>
                              _handleViewReport('weekly', 'Weekly Report'),
                          onDownloadTap: () =>
                              _handleDownloadReport('weekly', 'Weekly Report'),
                        ),
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'monthly',
                          title: 'Monthly Report',
                          subtitle: 'Monthly business insights',
                          icon: Icons.calendar_month_outlined,
                          gradientColors: [
                            const Color(0xFF8B4513),
                            const Color(0xFFD2691E),
                          ], // Dark Brown to Bronze
                          onViewTap: () =>
                              _handleViewReport('monthly', 'Monthly Report'),
                          onDownloadTap: () => _handleDownloadReport(
                            'monthly',
                            'Monthly Report',
                          ),
                        ),
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'sales',
                          title: 'Sales Report',
                          subtitle: 'Detailed sales analytics',
                          icon: Icons.trending_up_outlined,
                          gradientColors: [
                            const Color(0xFF2C5364),
                            const Color(0xFF203A43),
                          ], // Dark Slate Blue
                          onViewTap: () =>
                              _handleViewReport('sales', 'Sales Report'),
                          onDownloadTap: () =>
                              _handleDownloadReport('sales', 'Sales Report'),
                        ),
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'inventory',
                          title: 'Inventory Report',
                          subtitle: 'Stock levels & movements',
                          icon: Icons.inventory_2_outlined,
                          gradientColors: [
                            const Color(0xFF4B0082),
                            const Color(0xFF8B008B),
                          ], // Deep Purple to Dark Magenta
                          onViewTap: () => _handleViewReport(
                            'inventory',
                            'Inventory Report',
                          ),
                          onDownloadTap: () => _handleDownloadReport(
                            'inventory',
                            'Inventory Report',
                          ),
                        ),
                        _buildReportCardWithButtons(
                          context,
                          reportId: 'profit',
                          title: 'Profit Report',
                          subtitle: 'Profit margins & analysis',
                          icon: Icons.account_balance_wallet_outlined,
                          gradientColors: [
                            const Color(0xFF1a252f),
                            const Color(0xFF2b5876),
                          ], // Midnight Blue to Steel Blue
                          onViewTap: () =>
                              _handleViewReport('profit', 'Profit Report'),
                          onDownloadTap: () =>
                              _handleDownloadReport('profit', 'Profit Report'),
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

  // Handler methods for report actions
  Future<void> _handleViewReport(String reportId, String reportName) async {
    setState(() {
      _loadingReports.add(reportId);
    });

    try {
      // Show loading message
      _showSnackBar('Loading $reportName...', isLoading: true);

      // Simulate report loading delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would navigate to the actual report view
      // Navigator.pushNamed(context, '/report-view', arguments: reportId);

      _showSnackBar('$reportName loaded successfully!', isSuccess: true);
    } catch (e) {
      _showSnackBar(
        'Failed to load $reportName. Please try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _loadingReports.remove(reportId);
      });
    }
  }

  Future<void> _handleDownloadReport(String reportId, String reportName) async {
    setState(() {
      _downloadingReports.add(reportId);
    });

    try {
      // Show downloading message
      _showSnackBar('Downloading $reportName...', isLoading: true);

      // Simulate download delay
      await Future.delayed(const Duration(seconds: 3));

      // Here you would implement the actual download logic
      // await _downloadService.downloadReport(reportId);

      _showSnackBar('$reportName downloaded successfully!', isSuccess: true);
    } catch (e) {
      _showSnackBar(
        'Failed to download $reportName. Please try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _downloadingReports.remove(reportId);
      });
    }
  }

  void _showSnackBar(
    String message, {
    bool isLoading = false,
    bool isSuccess = false,
    bool isError = false,
  }) {
    Color backgroundColor;
    IconData icon;

    if (isLoading) {
      backgroundColor = Colors.blue.shade600;
      icon = Icons.info_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade600;
      icon = Icons.check_circle_outline;
    } else if (isError) {
      backgroundColor = Colors.red.shade600;
      icon = Icons.error_outline;
    } else {
      backgroundColor = Colors.grey.shade600;
      icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
      ),
    );
  }

  // Helper methods for date range functionality
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2a5298),
              onPrimary: Colors.white,
              surface: Color(0xFF1a252f),
              onSurface: Colors.white,
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
      _showSnackBar('Date range updated successfully!', isSuccess: true);
    }
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'Select Date Range';

    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
  }

  Widget _buildQuickInfoCard() {
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
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports for selected period',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDateRange != null
                        ? 'From ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} to ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                        : 'Select a date range to filter reports',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showDateRangePicker,
              child: const Text(
                'Change',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCardWithButtons(
    BuildContext context, {
    required String reportId,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onViewTap,
    required VoidCallback onDownloadTap,
  }) {
    final isViewLoading = _loadingReports.contains(reportId);
    final isDownloadLoading = _downloadingReports.contains(reportId);

    return Semantics(
      label: '$title card. $subtitle',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: 'Click to view or download $title',
          child: Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: AppConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildReportIcon(icon),
                        const Spacer(),
                        _buildStatusIndicator(
                          isViewLoading || isDownloadLoading,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButtons(
                      context,
                      onViewTap: onViewTap,
                      onDownloadTap: onDownloadTap,
                      gradientColors: gradientColors,
                      isViewLoading: isViewLoading,
                      isDownloadLoading: isDownloadLoading,
                      reportTitle: title,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.iconContainerRadius),
      ),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }

  Widget _buildStatusIndicator(bool isLoading) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      width: 20,
      height: 20,
      padding: const EdgeInsets.all(2),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required VoidCallback onViewTap,
    required VoidCallback onDownloadTap,
    required List<Color> gradientColors,
    required bool isViewLoading,
    required bool isDownloadLoading,
    required String reportTitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'View $reportTitle',
            button: true,
            child: ElevatedButton.icon(
              onPressed: isViewLoading || isDownloadLoading ? null : onViewTap,
              icon: isViewLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.visibility, size: 16),
              label: Text(isViewLoading ? 'Loading...' : 'View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonBorderRadius,
                  ),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: 'Download $reportTitle',
            button: true,
            child: ElevatedButton.icon(
              onPressed: isViewLoading || isDownloadLoading
                  ? null
                  : onDownloadTap,
              icon: isDownloadLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download, size: 16),
              label: Text(isDownloadLoading ? 'Downloading...' : 'Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradientColors[1].withOpacity(0.8),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonBorderRadius,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
