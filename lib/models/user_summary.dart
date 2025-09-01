import 'package:flutter/material.dart';

class UserSummary {
  final String name;
  final String email;
  final String role; // Admin, Manager, Cashier, StockKeeper
  final String colorCode; // e.g. #7C3AED
  final DateTime createdAt;

  const UserSummary({
    required this.name,
    required this.email,
    required this.role,
    required this.colorCode,
    required this.createdAt,
  });

  Color get color {
    try {
      final hex = colorCode.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}
    return Colors.deepPurple; // fallback
  }
}
