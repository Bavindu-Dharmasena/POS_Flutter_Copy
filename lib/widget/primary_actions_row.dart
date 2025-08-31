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
  final VoidCallback onQuickSale;
  final VoidCallback? onPay; // Keep as nullable
  final VoidCallback? onNewSale; // Keep as nullable
  final VoidCallback onResumeBill;
  final bool payEnabled;
  final bool hasPausedBills;
  final double horizontalPadding;

  const PrimaryActionsRow({
    super.key,
    required this.onQuickSale,
    required this.onPay,
    required this.onNewSale,
    required this.onResumeBill,
    required this.payEnabled,
    required this.hasPausedBills,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 1000;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 10,
      ),
      child: Row(
        children: [
          // First column: New Sale and Resume buttons
          Expanded(
            child: Column(
              children: [
                // New Sale button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNewSale, // This will handle null automatically
                    icon: Icon(
                      Icons.note_add,
                      size: isWideScreen ? 30 : 24,
                      // Remove color from Icon widget, let button style handle it
                    ),
                    label: Text(
                      'New Sale',
                      style: TextStyle(
                        fontSize: isWideScreen ? 20 : 25,
                        fontWeight: FontWeight.bold,
                        // Remove color from Text widget, let button style handle it
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onNewSale != null
                          ? Colors.green
                          : Colors
                                .grey[700], // Change background color based on state
                      foregroundColor: onNewSale != null
                          ? Colors.white
                          : Colors
                                .grey[700], // White when active, light gray when inactive
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 16 : 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Resume button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasPausedBills ? onResumeBill : null,
                    icon: Icon(
                      Icons.history,
                      size: isWideScreen ? 30 : 24,
                      color: hasPausedBills ? Colors.black : Colors.grey[700],
                    ),
                    label: Text(
                      'Resume',
                      style: TextStyle(
                        color: hasPausedBills ? Colors.black : Colors.grey[700],
                        fontSize: isWideScreen ? 20 : 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 16 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Second column: Quick Sale and Pay buttons
          Expanded(
            child: Column(
              children: [
                // Quick Sale button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onQuickSale,
                    icon: Icon(
                      Icons.flash_on,
                      size: isWideScreen ? 30 : 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Quick Sale',
                      style: TextStyle(
                        fontSize: isWideScreen ? 20 : 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 16 : 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Pay button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: payEnabled
                        ? onPay
                        : null, // This handles null properly
                    icon: Icon(
                      Icons.payment,
                      size: isWideScreen ? 30 : 24,
                      color: payEnabled ? Colors.white : Colors.grey[700],
                    ),
                    label: Text(
                      'Pay',
                      style: TextStyle(
                        fontSize: isWideScreen ? 20 : 25,
                        fontWeight: FontWeight.bold,
                        color: payEnabled ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 16 : 12,
                      ),
                    ),
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
