import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../cashier/sale_details_page.dart';
import 'package:pos_system/core/services/secure_storage_service.dart';

class CashierHistoryPage extends StatefulWidget {
  /// Current cashier name to filter "My History"
  final String currentCashier;

  /// Sales history list. Each item should include:
  /// { 'billId': String, 'date': DateTime or ISO String, 'amount': num, 'cashier': String }
  final List<Map<String, dynamic>> sales;

  const CashierHistoryPage({
    super.key,
    required this.currentCashier,
    required this.sales,
  });

  @override
  State<CashierHistoryPage> createState() => _CashierHistoryPageState();
}

class _CashierHistoryPageState extends State<CashierHistoryPage> {
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SecureStorageService.instance.getUserId();
    setState(() {
      userId = id != null ? int.tryParse(id) : null;
    });
  }

  // Updated to show all payments or only payments by the logged-in cashier and userId
  List<Map<String, dynamic>> _filter(bool myOnly) {
    if (!myOnly) return List<Map<String, dynamic>>.from(widget.sales);


    // Return only the sales by the current cashier and userId
    return widget.sales
        .where((s) => s['userId'] == userId) // Filter based on user_id
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _fmtDate(dynamic d) {
    DateTime? dt;
    if (d is DateTime) {
      dt = d;
    } else if (d is String) {
      dt = DateTime.tryParse(d);
    }
    return dt != null ? DateFormat('yyyy-MM-dd • hh:mm a').format(dt) : '--';
  }

  String _money(num? v) =>
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs. ').format(v ?? 0);

  Widget _buildHistoryList(bool myOnly) {
    final list = _filter(myOnly);

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No history yet.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Sort newest first (work on the copied list)
    list.sort((a, b) {
      final da = a['date'] is DateTime
          ? a['date'] as DateTime
          : DateTime.tryParse(a['date'].toString()) ?? DateTime(1970);
      final db = b['date'] is DateTime
          ? b['date'] as DateTime
          : DateTime.tryParse(b['date'].toString()) ?? DateTime(1970);
      return db.compareTo(da);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = list[i];
        return ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text('${s['billId'] ?? '-'}  •  ${_money(s['amount'])}'),
          subtitle: Text(
            '${_fmtDate(s['date'])}'
          ),
          trailing: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              final String saleId = (s['billId'] ?? '').toString();
              if (saleId.isEmpty) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SaleDetailsPage(saleInvoiceId: saleId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My History'),
            backgroundColor: const Color(0xFF0D1B2A),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'My History'),
                Tab(text: 'All'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // My History - filter by current cashier and userId
              _buildHistoryList(true),
              // All - display all sales
              _buildHistoryList(false),
            ],
          ),
        ),
      ),
    );
  }
}
