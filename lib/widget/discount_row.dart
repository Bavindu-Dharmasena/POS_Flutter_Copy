import 'package:flutter/material.dart';

class DiscountRow extends StatelessWidget {
  final double discount;
  final bool isPercentageDiscount;
  final ValueChanged<String> onDiscountChange;
  final ValueChanged<bool> onTypeChange;
  final double totalAmount;

  const DiscountRow({
    super.key,
    required this.discount,
    required this.isPercentageDiscount,
    required this.onDiscountChange,
    required this.onTypeChange,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Discount controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Discount: ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onChanged: onDiscountChange,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<bool>(
                value: isPercentageDiscount,
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('%', style: TextStyle(fontSize: 16)),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('Rs', style: TextStyle(fontSize: 16)),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) onTypeChange(v);
                },
              ),
            ],
          ),

          // Right side: Total amount
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Total: ',
                  style: const TextStyle(
                    fontSize: 14, // smaller size for "Total:"
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 25, // larger size for amount
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
