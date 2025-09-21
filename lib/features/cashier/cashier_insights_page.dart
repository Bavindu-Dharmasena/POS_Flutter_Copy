import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cashier_history_page.dart';
import '../../data/repositories/cashier/cashier_repository.dart';
import '../cashier/sale_details_page.dart';
import 'package:pos_system/core/services/secure_storage_service.dart';

class CashierInsightsPage extends StatefulWidget {
  const CashierInsightsPage({super.key});

  @override
  State<CashierInsightsPage> createState() => _CashierInsightsPageState();
}

class _CashierInsightsPageState extends State<CashierInsightsPage> {
  // Repo instance
  final CashierRepository _cashierrepo = CashierRepository();

  // Logged-in user id
  int? userId;
  String? userName;

  // Cache the future so we can refresh explicitly
  late Future<List<Map<String, dynamic>>> _futureSales;

  @override
  void initState() {
    super.initState();
    _futureSales = _loadSales();
    _loadUserId();
    _loadUserName();
  }

  Future<void> _loadUserId() async {
    final id = await SecureStorageService.instance.getUserId();
    setState(() {
      userId = id != null ? int.tryParse(id) : null;
    });
  }

  Future<void> _loadUserName() async {
    final name = await SecureStorageService.instance.getName();
    setState(() {
      userName = name;
    });
  }

  /// Load payments and map them into the "sales" shape that the UI uses:
  /// { billId: String, date: DateTime, amount: double, cashier: String }
  Future<List<Map<String, dynamic>>> _loadSales() async {
    final payments = await _cashierrepo.getAllPayments();
    return payments.map<Map<String, dynamic>>((p) {
      final int epoch = (p['date'] as int);
      final dt = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: false);
      return {
        'billId': p['sale_invoice_id'].toString(),
        'date': dt,
        'amount': (p['amount'] as num).toDouble(),
        // TODO: if you can join user_id->user_name, replace 'Unknown'
        'cashier': userName ?? 'Unknown',
        'userId': p['user_id'],
      };
    }).toList();
  }

  void _refresh() {
    setState(() {
      _futureSales = _loadSales();
    });
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

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
    // replace with real cashier if available
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          backgroundColor: const Color(0xFF0D1B2A),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>( 
          future: _futureSales,
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
            print(  'sales loaded: ${sales}');
            final todayTotal = _todayTotalSales(sales);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ===== Today Total Sales Card =====
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
                            'My History',
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
                                    currentCashier: userName ?? 'Unknown',
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
                                  currentCashier: userName ?? 'Unknown',
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
                          ...sales
                            .where((s) =>
                                _isToday(s['date'] as DateTime) &&
                                s['userId'] == userId) // Filter by today and userId
                            .take(3)
                            .map((s) {
                              final dt = s['date'] as DateTime;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.receipt_long),
                                title: Text(
                                  '${s['billId']}  •  ${_money(s['amount'])}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmt(dt)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () {
                                    final String saleId =
                                        (s['billId'] ?? '').toString();
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
                            })
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
