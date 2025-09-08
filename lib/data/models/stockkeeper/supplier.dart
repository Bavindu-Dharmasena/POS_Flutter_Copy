import 'package:flutter/material.dart';

class Supplier {
  final int? id;
  final String name;
  final String contact;
  final String? email;
  final String? address;
  final String brand;
  final String colorCode;      // HEX like "#3B82F6"
  final String location;
  final String status;         // 'ACTIVE' | 'INACTIVE' | 'PENDING'
  final bool preferred;        // stored as 0/1 in DB
  final String? paymentTerms;  // 'CASH', 'NET 7', 'NET 15', 'NET 30', 'NET 60'
  final String? notes;
  final int createdAt;         // msSinceEpoch
  final int updatedAt;         // msSinceEpoch

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

  factory Supplier.fromMap(Map<String, Object?> m) => Supplier(
        id: m['id'] as int?,
        name: (m['name'] ?? '') as String,
        contact: (m['contact'] ?? '') as String,
        email: m['email'] as String?,
        address: m['address'] as String?,
        brand: (m['brand'] ?? '') as String,
        colorCode: (m['color_code'] ?? '#000000') as String,
        location: (m['location'] ?? '') as String,
        status: (m['status'] ?? 'ACTIVE') as String,
        preferred: ((m['preferred'] ?? 0) as int) == 1,
        paymentTerms: m['payment_terms'] as String?,
        notes: m['notes'] as String?,
        createdAt: (m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt: (m['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, Object?> toMap() => {
        'id': id,
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

  /// Helper for your SupplierCard (Map-based)
  Map<String, dynamic> toUiCard() => {
        'id': (id ?? '').toString(),
        'name': name,
        'location': location,
        'phone': contact,
        'email': email,
        'address': address,
        'brand': brand,
        'status': status == 'ACTIVE'
            ? 'Active'
            : status == 'INACTIVE'
                ? 'Inactive'
                : 'Pending',
        'color': _hexToColor(colorCode),
        '_raw': toMap(),
      };

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16) ?? 0xFF000000;
    return Color(v);
  }
}
