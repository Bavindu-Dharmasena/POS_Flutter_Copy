import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';

class PastelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const PastelTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.keyboardType,
    this.validator,
    this.maxLines = 1, required List<FilteringTextInputFormatter> inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        hintText: hint,
      ),
    );
  }
}
