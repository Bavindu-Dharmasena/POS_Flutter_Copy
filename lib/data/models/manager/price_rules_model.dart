import 'package:flutter/material.dart';

enum RuleType { percentageDiscount, fixedDiscount, markup, bogo }

extension RuleTypeExtension on RuleType {
  String get value {
    switch (this) {
      case RuleType.percentageDiscount:
        return 'PERCENTAGE_DISCOUNT';
      case RuleType.fixedDiscount:
        return 'FIXED_DISCOUNT';
      case RuleType.markup:
        return 'MARKUP';
      case RuleType.bogo:
        return 'BOGO';
    }
  }

  static RuleType fromValue(String value) {
    switch (value) {
      case 'PERCENTAGE_DISCOUNT':
        return RuleType.percentageDiscount;
      case 'FIXED_DISCOUNT':
        return RuleType.fixedDiscount;
      case 'MARKUP':
        return RuleType.markup;
      case 'BOGO':
        return RuleType.bogo;
      default:
        return RuleType.percentageDiscount;
    }
  }

  String get label {
    switch (this) {
      case RuleType.percentageDiscount:
        return 'Percentage Discount';
      case RuleType.fixedDiscount:
        return 'Fixed Discount';
      case RuleType.markup:
        return 'Markup';
      case RuleType.bogo:
        return 'BOGO';
    }
  }

  IconData get icon {
    switch (this) {
      case RuleType.percentageDiscount:
        return Icons.percent;
      case RuleType.fixedDiscount:
        return Icons.price_check;
      case RuleType.markup:
        return Icons.trending_up;
      case RuleType.bogo:
        return Icons.local_offer;
    }
  }
}

enum ScopeKind { all, category, product, customerGroup }

extension ScopeKindExtension on ScopeKind {
  String get value {
    switch (this) {
      case ScopeKind.all:
        return 'ALL';
      case ScopeKind.category:
        return 'CATEGORY';
      case ScopeKind.product:
        return 'PRODUCT';
      case ScopeKind.customerGroup:
        return 'CUSTOMER_GROUP';
    }
  }

  static ScopeKind fromValue(String value) {
    switch (value) {
      case 'ALL':
        return ScopeKind.all;
      case 'CATEGORY':
        return ScopeKind.category;
      case 'PRODUCT':
        return ScopeKind.product;
      case 'CUSTOMER_GROUP':
        return ScopeKind.customerGroup;
      default:
        return ScopeKind.all;
    }
  }
}

class PriceRule {
  final String id;
  final String name;
  final RuleType type;
  final ScopeKind scopeKind;
  final String scopeValue;
  final double value;
  final bool stackable;
  final bool active;
  final int priority;
  final int? perCustomerLimit;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<int> daysOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;

  PriceRule({
    required this.id,
    required this.name,
    required this.type,
    required this.scopeKind,
    required this.scopeValue,
    required this.value,
    required this.stackable,
    required this.active,
    required this.priority,
    this.perCustomerLimit,
    this.startTime,
    this.endTime,
    this.startDate,
    this.endDate,
    Set<int>? daysOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : daysOfWeek = daysOfWeek ?? <int>{},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isScheduled =>
      startDate != null || 
      endDate != null || 
      startTime != null || 
      endTime != null || 
      daysOfWeek.isNotEmpty;

  bool get isCurrentlyEffective {
    final now = DateTime.now();
    if (!active) return false;

    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    if (daysOfWeek.isNotEmpty) {
      final dow = now.weekday; // 1..7
      if (!daysOfWeek.contains(dow)) return false;
    }

    if (startTime != null && endTime != null) {
      final nowTOD = TimeOfDay(hour: now.hour, minute: now.minute);
      bool afterStart = _compareTOD(nowTOD, startTime!) >= 0;
      bool beforeEnd = _compareTOD(nowTOD, endTime!) <= 0;
      if (!(afterStart && beforeEnd)) return false;
    }
    return true;
  }

  static int _compareTOD(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) return a.hour.compareTo(b.hour);
    return a.minute.compareTo(b.minute);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'scope_kind': scopeKind.value,
      'scope_value': scopeValue,
      'value': value,
      'stackable': stackable ? 1 : 0,
      'active': active ? 1 : 0,
      'priority': priority,
      'per_customer_limit': perCustomerLimit,
      'start_time': startTime != null ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}' : null,
      'end_time': endTime != null ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}' : null,
      'start_date': startDate?.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'days_of_week': daysOfWeek.isEmpty ? '' : daysOfWeek.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory PriceRule.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    Set<int> parseDaysOfWeek(String? daysStr) {
      if (daysStr == null || daysStr.isEmpty) return <int>{};
      return daysStr.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toSet();
    }

    return PriceRule(
      id: map['id'] as String,
      name: map['name'] as String,
      type: RuleTypeExtension.fromValue(map['type'] as String),
      scopeKind: ScopeKindExtension.fromValue(map['scope_kind'] as String),
      scopeValue: map['scope_value'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      stackable: (map['stackable'] as int?) == 1,
      active: (map['active'] as int?) == 1,
      priority: map['priority'] as int? ?? 10,
      perCustomerLimit: map['per_customer_limit'] as int?,
      startTime: parseTime(map['start_time'] as String?),
      endTime: parseTime(map['end_time'] as String?),
      startDate: map['start_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int) : null,
      endDate: map['end_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int) : null,
      daysOfWeek: parseDaysOfWeek(map['days_of_week'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  PriceRule copyWith({
    String? id,
    String? name,
    RuleType? type,
    ScopeKind? scopeKind,
    String? scopeValue,
    double? value,
    bool? stackable,
    bool? active,
    int? priority,
    int? perCustomerLimit,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? startDate,
    DateTime? endDate,
    Set<int>? daysOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PriceRule(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeValue: scopeValue ?? this.scopeValue,
      value: value ?? this.value,
      stackable: stackable ?? this.stackable,
      active: active ?? this.active,
      priority: priority ?? this.priority,
      perCustomerLimit: perCustomerLimit ?? this.perCustomerLimit,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PriceRule{id: $id, name: $name, type: $type, active: $active}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRule && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}