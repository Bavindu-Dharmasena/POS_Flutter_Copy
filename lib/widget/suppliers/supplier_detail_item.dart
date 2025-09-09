import 'package:flutter/material.dart';

class SupplierDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool isAddress;

  const SupplierDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.isAddress = false,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed color resolution - ensure we always have a non-null Color
    final Color c = color ?? 
        DefaultTextStyle.of(context).style.color ?? 
        Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13, color: c),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}