import 'package:flutter/material.dart';

double passwordStrength(String password) {
  double strength = 0;
  if (password.length >= 8) strength += 0.2;
  if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
  if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
  if (RegExp(r'\d').hasMatch(password)) strength += 0.2;
  if (RegExp(r'''[!@#\$%^&*()_\-+={}\[\]:;'"<>,.?/\\|`~]''').hasMatch(password)) {
    strength += 0.2;
  }
  return strength.clamp(0.0, 1.0);
}

String strengthLabel(double s) {
  if (s < 0.2) return 'Very Weak';
  if (s < 0.4) return 'Weak';
  if (s < 0.6) return 'Fair';
  if (s < 0.8) return 'Good';
  return 'Strong';
}

Color strengthColor(double s) {
  if (s < 0.2) return Colors.red;
  if (s < 0.4) return Colors.deepOrange;
  if (s < 0.6) return Colors.amber.shade700;
  if (s < 0.8) return Colors.lightGreen.shade700;
  return Colors.green;
}

class PasswordChecks {
  final bool hasMinLen;
  final bool hasUpper;
  final bool hasLower;
  final bool hasDigit;
  final bool hasSpecial;

  const PasswordChecks({
    required this.hasMinLen,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
  });

  factory PasswordChecks.from(String password) => PasswordChecks(
        hasMinLen: password.length >= 8,
        hasUpper: RegExp(r'[A-Z]').hasMatch(password),
        hasLower: RegExp(r'[a-z]').hasMatch(password),
        hasDigit: RegExp(r'\d').hasMatch(password),
        hasSpecial: RegExp(r'''[!@#\$%^&*()_\-+={}\[\]:;"'<>,.?/\\|`~]''')
            .hasMatch(password),
      );
}
