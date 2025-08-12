import 'package:flutter/material.dart';
import 'summary_card.dart'; // Import the new summary card widget

class ReportPreviewDialog extends StatelessWidget {
  final String reportName;
  final Map<String, dynamic> filters;

  const ReportPreviewDialog({
    Key? key,
    required this.reportName,
    required this.filters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.green),
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
              _buildAppliedFilters(),
              const SizedBox(height: 20),
              const Text(
                'Report Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSummaryMetrics(),
              const SizedBox(height: 20),
              const Text(
                'Detailed Breakdown:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _getReportColumns(),
                  rows: _generateReportData(),
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
            _showSnackBar(context, '$reportName exported to PDF successfully!');
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export PDF'),
        ),
      ],
    );
  }

  Widget _buildAppliedFilters() {
    return Container(
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...filters.entries.map(
            (entry) => Text('• ${entry.key}: ${entry.value}'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    bool isPaymentReport = _isPaymentRelatedReport(reportName);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                isPaymentReport ? 'Total Payments' : 'Total Sales',
                '\$${1000 + (reportName.length * 100)}',
                isPaymentReport ? Icons.payment : Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                isPaymentReport ? 'Payment Methods' : 'Items Sold',
                isPaymentReport ? '5' : '${50 + (reportName.length * 5)}',
                isPaymentReport ? Icons.credit_card : Icons.shopping_cart,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                'Profit',
                '\$${300 + (reportName.length * 30)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                'Transactions',
                '${15 + (reportName.length * 2)}',
                Icons.receipt,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<DataColumn> _getReportColumns() {
    if (_isPaymentRelatedReport(reportName)) {
      if (reportName == 'Payment Types by Users') {
        return const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Payment Method')),
          DataColumn(label: Text('Amount')),
        ];
      }
      return const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Transactions')),
        DataColumn(label: Text('Amount')),
      ];
    }
    return const [
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Item')),
      DataColumn(label: Text('Quantity')),
      DataColumn(label: Text('Amount')),
      DataColumn(label: Text('Profit')),
    ];
  }

  List<DataRow> _generateReportData() {
    // This is placeholder data generation logic
    return List.generate(5, (i) {
      if (_isPaymentRelatedReport(reportName)) {
        return DataRow(
          cells: [
            DataCell(Text('${DateTime.now().day - i}/${DateTime.now().month}')),
            DataCell(Text('Method ${i + 1}')),
            DataCell(Text('${20 + i * 5}')),
            DataCell(Text('\$${(500 + i * 150).toStringAsFixed(2)}')),
          ],
        );
      }
      return DataRow(
        cells: [
          DataCell(Text('${DateTime.now().day - i}/${DateTime.now().month}')),
          DataCell(Text('Item ${i + 1}')),
          DataCell(Text('${10 + i}')),
          DataCell(Text('\$${(100 + i * 25).toStringAsFixed(2)}')),
          DataCell(Text('\$${(30 + i * 8).toStringAsFixed(2)}')),
        ],
      );
    });
  }

  bool _isPaymentRelatedReport(String reportName) {
    return reportName.contains('Payment Types');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
