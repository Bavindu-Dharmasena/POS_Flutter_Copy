import 'package:flutter/material.dart';

class DiscountRow extends StatelessWidget {
  final double discount;
  final bool isPercentageDiscount;
  final ValueChanged<String> onDiscountChange;
  final ValueChanged<bool> onTypeChange;

  const DiscountRow({
    super.key,
    required this.discount,
    required this.isPercentageDiscount,
    required this.onDiscountChange,
    required this.onTypeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Discount: "),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '0'),
            onChanged: onDiscountChange,
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<bool>(
          value: isPercentageDiscount,
          items: const [
            DropdownMenuItem(value: true, child: Text('%')),
            DropdownMenuItem(value: false, child: Text('Rs')),
          ],
          onChanged: (v) {
            if (v != null) onTypeChange(v);
          },
        ),
      ],
    );
  }
}
