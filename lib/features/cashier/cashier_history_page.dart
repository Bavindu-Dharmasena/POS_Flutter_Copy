import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashierHistoryPage extends StatelessWidget {
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

  List<Map<String, dynamic>> _filter(bool myOnly) {
    if (!myOnly) return sales;
    return sales.where((s) => (s['cashier'] ?? '') == currentCashier).toList();
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
          child: Text('No history yet.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    // (Optional) sort newest first
    list.sort((a, b) {
      final da = a['date'] is DateTime ? a['date'] as DateTime : DateTime.tryParse(a['date'].toString()) ?? DateTime(1970);
      final db = b['date'] is DateTime ? b['date'] as DateTime : DateTime.tryParse(b['date'].toString()) ?? DateTime(1970);
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
            '${(s['cashier'] != null && s['cashier'].toString().isNotEmpty) ? ' • ${s['cashier']}' : ''}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              // TODO: open bill details page/modal if you have one
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
            title: const Text('History'),
            backgroundColor: const Color(0xFF0D1B2A),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'My History'),
                Tab(text: 'All'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              // My History
              _HistoryTab(myOnly: true),
              // All
              _HistoryTab(myOnly: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal tab widget so we can access the parent InheritedWidget (CashierHistoryPage)
class _HistoryTab extends StatelessWidget {
  final bool myOnly;
  const _HistoryTab({required this.myOnly});

  @override
  Widget build(BuildContext context) {
    // Access the nearest CashierHistoryPage to reuse its helpers/data
    final element = context.findAncestorWidgetOfExactType<CashierHistoryPage>()!;
    // Reuse its list builder
    return element._buildHistoryList(myOnly);
  }
}
