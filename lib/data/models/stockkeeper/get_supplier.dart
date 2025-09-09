// lib/data/models/stockkeeper/Supplier.dart

/// DB-backed Supplier entity
class Supplier {
  final int? id;
  final String name;
  final String contact;
  final String? email;
  final String? address;
  final String brand;
  final String colorCode; // DB: color_code
  final String location;
  /// 'ACTIVE' | 'INACTIVE' | 'PENDING'
  final String status;
  final bool preferred; // DB: INTEGER(0/1)
  final String? paymentTerms; // DB: payment_terms
  final String? notes;
  /// millisecondsSinceEpoch
  final int createdAt; // DB: created_at
  final int updatedAt; // DB: updated_at

  const Supplier({
    this.id,
    required this.name,
    required this.contact,
    this.email,
    this.address,
    required this.brand,
    required this.colorCode,
    required this.location,
    required this.status,
    required this.preferred,
    this.paymentTerms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Supplier copyWith({
    int? id,
    String? name,
    String? contact,
    String? email,
    String? address,
    String? brand,
    String? colorCode,
    String? location,
    String? status,
    bool? preferred,
    String? paymentTerms,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      brand: brand ?? this.brand,
      colorCode: colorCode ?? this.colorCode,
      location: location ?? this.location,
      status: status ?? this.status,
      preferred: preferred ?? this.preferred,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool forInsert = false}) {
    return <String, Object?>{
      if (!forInsert && id != null) 'id': id,
      'name': name,
      'contact': contact,
      'email': email,
      'address': address,
      'brand': brand,
      'color_code': colorCode,
      'location': location,
      'status': status,
      'preferred': preferred ? 1 : 0,
      'payment_terms': paymentTerms,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Supplier.fromMap(Map<String, Object?> m) {
    return Supplier(
      id: m['id'] as int?,
      name: m['name'] as String,
      contact: m['contact'] as String,
      email: m['email'] as String?,
      address: m['address'] as String?,
      brand: m['brand'] as String,
      colorCode: m['color_code'] as String,
      location: m['location'] as String,
      status: m['status'] as String,
      preferred: _toBool(m['preferred']),
      paymentTerms: m['payment_terms'] as String?,
      notes: m['notes'] as String?,
      createdAt: (m['created_at'] as num).toInt(),
      updatedAt: (m['updated_at'] as num).toInt(),
    );
  }

  static bool _toBool(Object? v) {
    if (v == null) return false;
    if (v is int) return v == 1;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  /// What your screen passes into SupplierCard / SupplierProductsPage
  SupplierCardData toUiCard() => SupplierCardData(
        id: id,
        name: name,
        brand: brand,
        contact: contact,
        email: email,
        location: location,
        status: status,
        colorCode: colorCode,
      );
}

/// Lightweight DTO used by UI cards/pages
class SupplierCardData {
  final int? id;
  final String name;
  final String brand;
  final String contact;
  final String? email;
  final String location;
  final String status;   // ACTIVE / INACTIVE / PENDING
  final String colorCode;

  const SupplierCardData({
    required this.id,
    required this.name,
    required this.brand,
    required this.contact,
    required this.email,
    required this.location,
    required this.status,
    required this.colorCode,
  });
}
