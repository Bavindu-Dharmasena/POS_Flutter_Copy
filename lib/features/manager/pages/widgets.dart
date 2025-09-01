import 'package:flutter/material.dart';

class PeriodFilterRow extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final Widget? trailing;

  const PeriodFilterRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Filter:'),
        DropdownButton<String>(
          value: value,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
