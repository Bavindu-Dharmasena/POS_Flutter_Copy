// lib/data/models/manager/creditor_payment.dart
class CreditorPayment {
  final int id;               // autoincrement
  final String creditorId;    // FK -> creditor_account.id
  final double amount;        // Rs paid (partial or full)
  final int paidAt;           // epoch millis
  final String? note;

  CreditorPayment({
    required this.id,
    required this.creditorId,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  factory CreditorPayment.fromMap(Map<String, Object?> m) => CreditorPayment(
        id: (m['id'] ?? 0) as int,
        creditorId: (m['creditor_id'] ?? '') as String,
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        paidAt: (m['paid_at'] ?? 0) as int,
        note: m['note'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'creditor_id': creditorId,
        'amount': amount,
        'paid_at': paidAt,
        'note': note,
      };
}
