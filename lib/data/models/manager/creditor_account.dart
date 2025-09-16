class CreditorAccount {
  final String id;                 // e.g. "CR1001"
  final String name;
  final String company;
  final String phone;
  final String email;
  final DateTime lastInvoiceDate;
  final double dueAmount;
  final double paidAmount;
  final int overdueDays;
  final int createdAt;             // epoch millis
  final int updatedAt;             // epoch millis

  CreditorAccount({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.lastInvoiceDate,
    required this.dueAmount,
    required this.paidAmount,
    required this.overdueDays,
    required this.createdAt,
    required this.updatedAt,
  });

  CreditorAccount copyWith({
    String? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    DateTime? lastInvoiceDate,
    double? dueAmount,
    double? paidAmount,
    int? overdueDays,
    int? createdAt,
    int? updatedAt,
  }) {
    return CreditorAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      dueAmount: dueAmount ?? this.dueAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      overdueDays: overdueDays ?? this.overdueDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CreditorAccount.fromMap(Map<String, Object?> m) {
    return CreditorAccount(
      id: (m['id'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      company: (m['company'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      lastInvoiceDate: DateTime.fromMillisecondsSinceEpoch((m['last_invoice_date'] as int?) ?? 0),
      dueAmount: ((m['due_amount'] ?? 0) as num).toDouble(),
      paidAmount: ((m['paid_amount'] ?? 0) as num).toDouble(),
      overdueDays: (m['overdue_days'] ?? 0) as int,
      createdAt: (m['created_at'] ?? 0) as int,
      updatedAt: (m['updated_at'] ?? 0) as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'last_invoice_date': lastInvoiceDate.millisecondsSinceEpoch,
      'due_amount': dueAmount,
      'paid_amount': paidAmount,
      'overdue_days': overdueDays,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
