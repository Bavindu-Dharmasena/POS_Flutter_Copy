import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cashier_history_page.dart';
import '../../data/repositories/cashier/cashier_repository.dart';
import '../cashier/sale_details_page.dart';

class CashierInsightsPage extends StatelessWidget {
  const CashierInsightsPage({super.key});

  // Repo as static so const constructor is valid
  static final CashierRepository _cashierrepo = CashierRepository();

  /// Load payments and map them into the "sales" shape that the UI uses.
  /// sales item: { billId: String, date: DateTime, amount: double, cashier: String }
  Future<List<Map<String, dynamic>>> _loadSales() async {
    final payments = await _cashierrepo.getAllPayments();
    return payments.map<Map<String, dynamic>>((p) {
      final int epoch = (p['date'] as int);
      final dt = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: false);
      return {
        'billId': p['sale_invoice_id'].toString(),
        'date': dt,
        'amount': (p['amount'] as num).toDouble(),
        'cashier': 'Unknown', // TODO: map from user_id if you can join
      };
    }).toList();
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  // double _totalSales(List<Map<String, dynamic>> sales) =>
  //     sales.fold(0.0, (sum, s) => sum + (s['amount'] as num).toDouble());

  double _todayTotalSales(List<Map<String, dynamic>> sales) {
    return sales
        .where((s) => _isToday(s['date'] as DateTime))
        .fold(0.0, (sum, s) => sum + (s['amount'] as num).toDouble());
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd • hh:mm a').format(dt);

  String _money(num v) =>
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs. ').format(v);

  @override
  Widget build(BuildContext context) {
    const currentCashier = 'John Doe'; // replace with real cashier if available

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          backgroundColor: const Color(0xFF0D1B2A),
          actions: [
            // Manual refresh trigger by rebuilding FutureBuilder via setState is not available in StatelessWidget.
            // For a quick test button, you can navigate away/back or convert to StatefulWidget.
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadSales(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading payments: ${snapshot.error}'),
                ),
              );
            }

            final sales = snapshot.data ?? const <Map<String, dynamic>>[];
            final todayTotal = _todayTotalSales(sales);

            return ListView(
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
                            const Text(
                              'Today Total Sales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _money(todayTotal),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== History Card =====
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

                        if (sales.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No history yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          ...sales.take(3).map((s) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.receipt_long),
                              title: Text(
                                '${s['billId']}  •  ${_money(s['amount'])}',
                              ),
                              subtitle: Text(_fmt(s['date'] as DateTime)),
                              // trailing: IconButton(
                              //   icon: const Icon(Icons.visibility),
                              //   onPressed: () {
                              //     // TODO: open bill details if you have them
                              //   },
                              // ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  final String saleId = (s['billId'] ?? '')
                                      .toString();
                                  if (saleId.isEmpty) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SaleDetailsPage(
                                        saleInvoiceId: saleId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== Reports Card =====
                // Card(
                //   elevation: 2,
                //   child: Padding(
                //     padding: const EdgeInsets.all(12),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.stretch,
                //       children: [
                //         const Text(
                //           'Reports',
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.w600,
                //           ),
                //         ),
                //         const SizedBox(height: 8),
                //         Wrap(
                //           spacing: 10,
                //           runSpacing: 10,
                //           children: [
                //             OutlinedButton.icon(
                //               icon: const Icon(Icons.today),
                //               label: const Text('Today Report'),
                //               onPressed: () {
                //                 // TODO
                //               },
                //             ),
                //             OutlinedButton.icon(
                //               icon: const Icon(Icons.date_range),
                //               label: const Text('This Week'),
                //               onPressed: () {
                //                 // TODO
                //               },
                //             ),
                //             OutlinedButton.icon(
                //               icon: const Icon(Icons.calendar_month),
                //               label: const Text('This Month'),
                //               onPressed: () {
                //                 // TODO
                //               },
                //             ),
                //             OutlinedButton.icon(
                //               icon: const Icon(Icons.file_download),
                //               label: const Text('Export CSV'),
                //               onPressed: () {
                //                 // TODO
                //               },
                //             ),
                //           ],
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}
