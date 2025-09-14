import 'supplier_model.dart';

extension SupplierDbMaps on Supplier {
  /// Map for INSERT. Includes created_at & updated_at.
  Map<String, Object?> toInsertMap() => {
        'name': name,
        'contact': contact,
        'email': email,
        'address': address,
        'brand': brand,
        'color_code': colorCode, // stored in DB, not used by UI
        'location': location,
        'status': status,
        'preferred': preferred ? 1 : 0,
        'payment_terms': paymentTerms,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Map for UPDATE. ❗Does NOT touch created_at.
  Map<String, Object?> toUpdateMap() => {
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
        'updated_at': updatedAt,
      };

  /// Colorless map for UI (what you pass to SupplierCard / products page).
  Map<String, dynamic> toUiMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'phone': contact,
        'email': email,
        'address': address,
        'brand': brand,
        // color intentionally omitted
        'location': location,
        'status': status,
        'preferred': preferred,
        'paymentTerms': paymentTerms,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
