import 'package:flutter/foundation.dart';

@immutable
class LowStockSelection {
  final int itemId;
  final int quantity; // what user typed in "Req. Qty"
  const LowStockSelection({required this.itemId, required this.quantity});
}
