// import 'package:flutter/material.dart';

// class PrimaryActionsRow extends StatelessWidget {
//   final VoidCallback onAddItem;
//   final VoidCallback? onPay;
//   final bool payEnabled;
//   final double horizontalPadding;

//   const PrimaryActionsRow({
//     super.key,
//     required this.onAddItem,
//     required this.onPay,
//     required this.payEnabled,
//     this.horizontalPadding = 40,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Get screen size
//     final screenWidth = MediaQuery.of(context).size.width;

//     // Scale button width and height
//     final buttonWidth = screenWidth * 0.2; // 20% of screen width
//     final buttonHeight = screenWidth * 0.01; // 6% of screen height

//     // Scale font size
//     final fontSize = screenWidth * 0.03; // Adjust this ratio as needed

//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: 10,
//         left: horizontalPadding,
//         right: horizontalPadding,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           ElevatedButton.icon(
//             onPressed: onAddItem,
//             icon: Icon(Icons.add, size: fontSize + 4),
//             label: Text('Item', style: TextStyle(fontSize: fontSize)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               minimumSize: Size(buttonWidth, buttonHeight),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: payEnabled ? onPay : null,
//             child: Text('Pay', style: TextStyle(fontSize: fontSize)),
//             style: ElevatedButton.styleFrom(
//               minimumSize: Size(buttonWidth, buttonHeight),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class PrimaryActionsRow extends StatelessWidget {
  final VoidCallback onQuickSale; // REPLACED onAddItem -> onQuickSale
  final VoidCallback? onPay;
  final bool payEnabled;
  final double horizontalPadding;

  const PrimaryActionsRow({
    super.key,
    required this.onQuickSale, // required
    required this.onPay,
    required this.payEnabled,
    this.horizontalPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Keep your Pay button scaling logic (you were using screenWidth)
    final buttonWidth = screenWidth * 0.20; // 20% of screen width
    final buttonHeight = screenWidth * 0.01; // same as your code
    final fontSize = screenWidth * 0.03;

    // Match your _buildQuickSaleButton behavior
    final isWideScreen = screenWidth >= 1000;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---- Quick Sale button (replaces "+ Item") ----
          ElevatedButton.icon(
            onPressed: onQuickSale,
            icon: Icon(Icons.flash_on, size: isWideScreen ? 30 : 20),
            label: Text(
              'Quick Sale',
              style: TextStyle(
                fontSize: isWideScreen ? 22 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 22,
                vertical: isWideScreen ? 20 : 14,
              ),
              minimumSize: isWideScreen ? const Size(200, 60) : null,
            ),
          ),

          // ---- Pay button (unchanged behavior) ----
          // ElevatedButton(
          //   onPressed: payEnabled ? onPay : null,
          //   child: Text('Pay', style: TextStyle(fontSize: fontSize)),
          //   style: ElevatedButton.styleFrom(
          //     minimumSize: Size(buttonWidth, buttonHeight),
          //   ),
          // ),

          //-----------------------------------------------------
          ElevatedButton(
            onPressed: payEnabled ? onPay : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 22,
                vertical: isWideScreen ? 20 : 14,
              ),
              minimumSize: isWideScreen ? const Size(200, 60) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: isWideScreen ? 30 : 20),
                SizedBox(width: 10), // Space between icon and text
                Text(
                  'Pay',
                  style: TextStyle(
                    fontSize: isWideScreen ? 22 : 16,
                    fontWeight: FontWeight.bold,
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
