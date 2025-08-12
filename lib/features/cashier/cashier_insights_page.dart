import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cashier_history_page.dart'; // ⬅️ import the history tabs page

class CashierInsightsPage extends StatelessWidget {
  const CashierInsightsPage({super.key});

  // ---- Mock data (replace with your real data source) ----
  List<Map<String, dynamic>> get _mockSales => [
        {
          'billId': 'B-1001',
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'amount': 2350.75,
          'cashier': 'John Doe',
        },
        {
          'billId': 'B-1000',
          'date': DateTime.now().subtract(const Duration(hours: 5)),
          'amount': 1490.00,
          'cashier': 'Jane Smith',
        },
        {
          'billId': 'B-0999',
          'date': DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          'amount': 3575.25,
          'cashier': 'John Doe',
        },
      ];

  double _totalSales(List<Map<String, dynamic>> sales) =>
      sales.fold(0.0, (sum, s) => sum + (s['amount'] as num).toDouble());

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd • hh:mm a').format(dt);

  String _money(num v) =>
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs. ').format(v);

  @override
  Widget build(BuildContext context) {
    final sales = _mockSales;
    final total = _totalSales(sales);
    const currentCashier = 'John Doe'; // ⬅️ pass your real cashier name here

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          backgroundColor: const Color(0xFF0D1B2A),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Total Sales Card =====
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Sales',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          _money(total),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== History Card (header is tappable to open tabs page) =====
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row → tap to open History tabs page
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'History',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('View'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CashierHistoryPage(
                                currentCashier: currentCashier,
                                sales: sales,
                              ),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CashierHistoryPage(
                              currentCashier: currentCashier,
                              sales: sales,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // quick preview of a few recent items (keep this, optional)
                    ...sales.take(3).map((s) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long),
                        title:
                            Text('${s['billId']}  •  ${_money(s['amount'])}'),
                        subtitle: Text(_fmt(s['date'] as DateTime)),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            // TODO: open bill details if you have them
                          },
                        ),
                      );
                    }).toList(),
                    if (sales.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No history yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== Reports Card (unchanged, optional) =====
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Reports',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.today),
                          label: const Text('Today Report'),
                          onPressed: () {
                            // TODO
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: const Text('This Week'),
                          onPressed: () {
                            // TODO
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('This Month'),
                          onPressed: () {
                            // TODO
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export CSV'),
                          onPressed: () {
                            // TODO
                          },
                        ),
                      ],
                    ),
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
