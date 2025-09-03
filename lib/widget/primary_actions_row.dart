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
  final VoidCallback onAddItem;
  final VoidCallback onQuickSale;
  final VoidCallback? onPay;
  final VoidCallback? onNewSale;
  final VoidCallback onResumeBill;
  final bool payEnabled;
  final bool hasPausedBills;
  final double horizontalPadding;

  const PrimaryActionsRow({
    super.key,
    required this.onAddItem,
    required this.onQuickSale,
    required this.onPay,
    required this.onNewSale,
    required this.onResumeBill,
    required this.payEnabled,
    required this.hasPausedBills,
    this.horizontalPadding = 4,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 1000;

    // ✅ Button size
    final double buttonWidth = isWideScreen ? 250 : 125;
    final double buttonHeight = isWideScreen ? 80 : 80;

    // ✅ Font and icon size scale with screen type
    final double fontSize = isWideScreen ? 30 : 16;
    final double iconSize = isWideScreen ? 30 : 30;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Column(
        children: [
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add Item button
              // Add Item button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onAddItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // 👈 smaller corner radius
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: iconSize),
                      Text('Add Item', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Resume button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: hasPausedBills ? onResumeBill : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: hasPausedBills
                        ? Colors.black
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: iconSize),
                      Text('Resume', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Quick Sale button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onQuickSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, size: iconSize),
                      Text('Quick Sale', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // New Sale button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onNewSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onNewSale != null
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // 👈 corner radius
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: iconSize),
                      Text('New Sale', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Pay button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: payEnabled ? onPay : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: payEnabled ? Colors.white : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // 👈 smaller corners
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: iconSize),
                      // const SizedBox(height: 2), // small gap
                      Text('Pay', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
