import 'package:flutter/foundation.dart';

@immutable
class SalesRecord {
  const SalesRecord({
    required this.orderId,
    required this.timestamp,
    required this.store,          // we’ll show the cashier/user name here
    required this.paymentMethod,  // payment.type
    required this.amount,         // payment.amount
  });

  final String orderId;
  final DateTime timestamp;
  final String store;
  final String paymentMethod;
  final double amount;

  factory SalesRecord.fromRow(Map<String, Object?> r) {
    final tsMs = (r['date'] as num).toInt();
    final amt = (r['amount'] as num).toDouble();
    return SalesRecord(
      orderId: r['order_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
      store: (r['store'] as String?) ?? 'Main Store',
      paymentMethod: r['payment_method'] as String,
      amount: amt,
    );
    }
}
