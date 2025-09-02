// lib/utils/form_validators.dart
class FormValidators {
  FormValidators._();

  static String? required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Required' : null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 12) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final emailRegex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$");
    return emailRegex.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  static String? creditLimit(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = _parseCurrencyToInt(value);
    if (amount < 0) return 'Credit limit cannot be negative';
    if (amount > 1e12.toInt()) return 'Credit limit is too large';
    return null;
  }

  static int _parseCurrencyToInt(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }
}