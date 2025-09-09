import 'package:flutter/foundation.dart';

@immutable
class Supplier {
  final int? id;
  final String name;
  final String contact;
  final String? email;
  final String? address;
  final String brand;
  final String colorCode;     // DB: color_code (kept for DB; UI ignores it)
  final String location;
  final String status;        // 'ACTIVE' | 'INACTIVE' | 'PENDING'
  final bool preferred;       // INTEGER 0/1
  final String paymentTerms;  // 'CASH' | 'NET 7' | 'NET 15' | 'NET 30' | 'NET 60'
  final String? notes;
  final int createdAt;
  final int updatedAt;

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
    required this.paymentTerms,
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

  factory Supplier.fromMap(Map<String, Object?> row) => Supplier(
        id: row['id'] as int?,
        name: (row['name'] ?? '') as String,
        contact: (row['contact'] ?? '') as String,
        email: row['email'] as String?,
        address: row['address'] as String?,
        brand: (row['brand'] ?? '') as String,
        colorCode: (row['color_code'] ?? '#000000') as String, // kept in DB only
        location: (row['location'] ?? 'N/A') as String,
        status: (row['status'] ?? 'ACTIVE') as String,
        preferred: ((row['preferred'] ?? 0) as int) == 1,
        paymentTerms: (row['payment_terms'] ?? 'CASH') as String,
        notes: row['notes'] as String?,
        createdAt: (row['created_at'] ?? 0) as int,
        updatedAt: (row['updated_at'] ?? 0) as int,
      );
}
