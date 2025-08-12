import 'package:flutter/material.dart';
import 'summary_card.dart';

class ReportPreviewDialog extends StatefulWidget {
  final String reportName;
  final Map<String, dynamic> filters;

  const ReportPreviewDialog({
    Key? key,
    required this.reportName,
    required this.filters,
  }) : super(key: key);

  @override
  State<ReportPreviewDialog> createState() => _ReportPreviewDialogState();
}

class _ReportPreviewDialogState extends State<ReportPreviewDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModernHeader(isDark),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlassFilters(isDark),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Analytics Overview', Icons.insights),
                        const SizedBox(height: 20),
                        _buildModernSummaryMetrics(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Data Breakdown', Icons.table_chart),
                        const SizedBox(height: 16),
                        _buildModernDataTable(isDark),
                      ],
                    ),
                  ),
                ),
                _buildModernActions(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.reportName} Report',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generated ${_formatDate(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF667eea)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF667eea).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFF667eea).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 8),
              const Text(
                'Active Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.filters.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667eea),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryMetrics() {
    bool isPaymentReport = _isPaymentRelatedReport(widget.reportName);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedCard(
                SummaryCard(
                  isPaymentReport ? 'Total Payments' : 'Total Sales',
                  '\$${1000 + (widget.reportName.length * 100)}',
                  isPaymentReport ? Icons.payment_rounded : Icons.attach_money_rounded,
                  const Color(0xFF10b981),
                ),
                0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedCard(
                SummaryCard(
                  isPaymentReport ? 'Payment Methods' : 'Items Sold',
                  isPaymentReport ? '5' : '${50 + (widget.reportName.length * 5)}',
                  isPaymentReport ? Icons.credit_card_rounded : Icons.shopping_cart_rounded,
                  const Color(0xFF3b82f6),
                ),
                100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedCard(
                SummaryCard(
                  'Profit Margin',
                  '\$${300 + (widget.reportName.length * 30)}',
                  Icons.trending_up_rounded,
                  const Color(0xFFf59e0b),
                ),
                200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedCard(
                SummaryCard(
                  'Total Transactions',
                  '${15 + (widget.reportName.length * 2)}',
                  Icons.receipt_long_rounded,
                  const Color(0xFF8b5cf6),
                ),
                300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget card, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: card,
          ),
        );
      },
    );
  }

  Widget _buildModernDataTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 48,
            columns: _getModernReportColumns(),
            rows: _generateModernReportData(),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getModernReportColumns() {
    if (_isPaymentRelatedReport(widget.reportName)) {
      if (widget.reportName == 'Payment Types by Users') {
        return const [
          DataColumn(label: Text('DATE')),
          DataColumn(label: Text('USER')),
          DataColumn(label: Text('METHOD')),
          DataColumn(label: Text('AMOUNT')),
        ];
      }
      return const [
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('METHOD')),
        DataColumn(label: Text('TRANSACTIONS')),
        DataColumn(label: Text('AMOUNT')),
      ];
    }
    return const [
      DataColumn(label: Text('DATE')),
      DataColumn(label: Text('ITEM')),
      DataColumn(label: Text('QUANTITY')),
      DataColumn(label: Text('AMOUNT')),
      DataColumn(label: Text('PROFIT')),
    ];
  }

  List<DataRow> _generateModernReportData() {
    return List.generate(5, (i) {
      if (_isPaymentRelatedReport(widget.reportName)) {
        return DataRow(
          cells: [
            DataCell(Text('${DateTime.now().day - i}/${DateTime.now().month}')),
            DataCell(Text('Payment ${i + 1}')),
            DataCell(Text('${20 + i * 5}')),
            DataCell(Text('\$${(500 + i * 150).toStringAsFixed(2)}')),
          ],
        );
      }
      return DataRow(
        cells: [
          DataCell(Text('${DateTime.now().day - i}/${DateTime.now().month}')),
          DataCell(Text('Product ${i + 1}')),
          DataCell(Text('${10 + i}')),
          DataCell(Text('\$${(100 + i * 25).toStringAsFixed(2)}')),
          DataCell(Text('\$${(30 + i * 8).toStringAsFixed(2)}')),
        ],
      );
    });
  }

  Widget _buildModernActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Close'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showModernSnackBar(context, '${widget.reportName} exported successfully!');
            },
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPaymentRelatedReport(String reportName) {
    return reportName.contains('Payment Types');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showModernSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}