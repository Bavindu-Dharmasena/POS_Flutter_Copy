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
    // Get screen size
    final screenWidth = MediaQuery.of(context).size.width;

    // Scale button width and height
    final buttonWidth = screenWidth * 0.2; // 20% of screen width
    final buttonHeight = screenWidth * 0.01; // 6% of screen height

    // Scale font size
    final fontSize = screenWidth * 0.03; // Adjust this ratio as needed

    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: Icon(Icons.add, size: fontSize + 4),
            label: Text('Item', style: TextStyle(fontSize: fontSize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: Size(buttonWidth, buttonHeight),
            ),
          ),
          ElevatedButton(
            onPressed: payEnabled ? onPay : null,
            child: Text('Pay', style: TextStyle(fontSize: fontSize)),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(buttonWidth, buttonHeight),
            ),
          ),
        ],
      ),
    );
  }
}
