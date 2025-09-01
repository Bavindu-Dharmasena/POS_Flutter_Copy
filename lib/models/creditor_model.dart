// lib/models/creditor_model.dart
import 'package:flutter/material.dart';

class CreditorModel {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String contactPerson;
  final int creditLimit;
  final bool isActive;
  final bool enableReminders;
  final int reminderDays;
  final Set<String> tags;
  final String notes;

  const CreditorModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.contactPerson,
    required this.creditLimit,
    required this.isActive,
    required this.enableReminders,
    required this.reminderDays,
    required this.tags,
    required this.notes,
  });

  factory CreditorModel.empty() {
    return const CreditorModel(
      name: '',
      phone: '',
      email: '',
      address: '',
      contactPerson: '',
      creditLimit: 0,
      isActive: true,
      enableReminders: false,
      reminderDays: 7,
      tags: <String>{},
      notes: '',
    );
  }

  CreditorModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? contactPerson,
    int? creditLimit,
    bool? isActive,
    bool? enableReminders,
    int? reminderDays,
    Set<String>? tags,
    String? notes,
  }) {
    return CreditorModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      creditLimit: creditLimit ?? this.creditLimit,
      isActive: isActive ?? this.isActive,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderDays: reminderDays ?? this.reminderDays,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'contactPerson': contactPerson,
      'creditLimit': creditLimit,
      'isActive': isActive,
      'enableReminders': enableReminders,
      'reminderDays': enableReminders ? reminderDays : null,
      'tags': tags.toList(),
      'notes': notes,
    };
  }

  factory CreditorModel.fromJson(Map<String, dynamic> json) {
    return CreditorModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      creditLimit: json['creditLimit'] ?? 0,
      isActive: json['isActive'] ?? true,
      enableReminders: json['enableReminders'] ?? false,
      reminderDays: json['reminderDays'] ?? 7,
      tags: Set<String>.from(json['tags'] ?? []),
      notes: json['notes'] ?? '',
    );
  }

  bool get isEmpty {
    return name.trim().isEmpty &&
           phone.trim().isEmpty &&
           email.trim().isEmpty &&
           address.trim().isEmpty &&
           contactPerson.trim().isEmpty &&
           creditLimit == 0 &&
           tags.isEmpty &&
           notes.trim().isEmpty;
  }

  RiskLevel get riskLevel {
    if (creditLimit >= 1000000) return RiskLevel.high;
    if (creditLimit >= 250000) return RiskLevel.medium;
    if (creditLimit > 0) return RiskLevel.low;
    return RiskLevel.none;
}

}

enum RiskLevel {
  none,
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case RiskLevel.none:
        return 'None';
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case RiskLevel.high:
        return Colors.red.shade400;
      case RiskLevel.medium:
        return Colors.orange.shade400;
      case RiskLevel.low:
        return Colors.green.shade400;
      case RiskLevel.none:
        return Theme.of(context).colorScheme.outline;
    }
  }
}
