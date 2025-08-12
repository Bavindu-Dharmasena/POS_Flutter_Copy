import 'package:flutter/material.dart';

class PrimaryActionsRow extends StatelessWidget {
  final VoidCallback onAddItem;
  final VoidCallback? onPay;
  final bool payEnabled;
  final double horizontalPadding;

  const PrimaryActionsRow({
    super.key,
    required this.onAddItem,
    required this.onPay,
    required this.payEnabled,
    this.horizontalPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: 10, left: horizontalPadding, right: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(130, 40),
            ),
          ),
          ElevatedButton(
            onPressed: payEnabled ? onPay : null,
            child: const Text('Pay'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(130, 40)),
          ),
        ],
      ),
    );
  }
}
