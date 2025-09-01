// lib/utils/currency_formatter.dart
import 'package:flutter/services.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String formatAmount(int amount) {
    final digits = amount.toString();
    return _addCommas(digits);
  }

  static int parseCurrencyToInt(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }

  static String _addCommas(String value) {
    final reversed = value.split('').reversed.toList();
    final chunks = <String>[];
    
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3) > reversed.length ? reversed.length : (i + 3);
      chunks.add(reversed.sublist(i, end).join());
    }
    
    return chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join(',');
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final String symbol;
  
  const CurrencyInputFormatter({required this.symbol});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';

    final withCommas = CurrencyFormatter._addCommas(digits);
    final formatted = '$symbol$withCommas';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}