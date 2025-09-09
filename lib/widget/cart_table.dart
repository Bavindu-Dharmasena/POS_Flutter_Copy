// import "package:flutter/material.dart";

// class CartTable extends StatelessWidget {
//   final List<Map<String, dynamic>> cartItems;
//   final void Function(int index) onEdit;
//   final void Function(int index) onRemove;

//   const CartTable({
//     required this.cartItems,
//     required this.onEdit,
//     required this.onRemove,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isMobile = constraints.maxWidth < 600;

//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: ConstrainedBox(
//             constraints: BoxConstraints(minWidth: constraints.maxWidth),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: DataTable(
//                 horizontalMargin: isMobile ? 4 : 20,
//                 columnSpacing: isMobile ? 8 : 40,
//                 headingRowHeight: isMobile ? 20 : 32,
//                 dataRowMinHeight: isMobile ? 20 : 36,
//                 dataRowMaxHeight: isMobile ? 30 : 44,
//                 headingRowColor: MaterialStateColor.resolveWith(
//                   (_) => Colors.grey.shade700,
//                 ),
//                 columns: [
//                   DataColumn(
//                     label: Text(
//                       "Item",
//                       style: TextStyle(fontSize: isMobile ? 8 : 14),
//                     ),
//                   ),
//                   DataColumn(
//                     label: Text(
//                       "Qty",
//                       style: TextStyle(fontSize: isMobile ? 8 : 14),
//                     ),
//                   ),
//                   DataColumn(
//                     label: Text(
//                       "Price",
//                       style: TextStyle(fontSize: isMobile ? 8 : 14),
//                     ),
//                   ),
//                   DataColumn(
//                     label: Text(
//                       "Total",
//                       style: TextStyle(fontSize: isMobile ? 8 : 14),
//                     ),
//                   ),
//                   DataColumn(
//                     label: Text(
//                       "Action",
//                       style: TextStyle(fontSize: isMobile ? 8 : 14),
//                     ),
//                   ),
//                 ],
//                 rows: cartItems.asMap().entries.map((entry) {
//                   final index = entry.key;
//                   final item = entry.value;

//                   double unitPrice = item["price"];
//                   final itemDiscount = item["itemDiscount"] ?? 0;
//                   unitPrice -= (item["isItemDiscountPercentage"] == true)
//                       ? unitPrice * itemDiscount / 100
//                       : itemDiscount;
//                   final totalPrice = unitPrice * item["quantity"];

//                   return DataRow(
//                     cells: [
//                       DataCell(
//                         Text(
//                           item["name"],
//                           style: TextStyle(fontSize: isMobile ? 8 : 14),
//                         ),
//                       ),
//                       DataCell(
//                         Text(
//                           '${item["quantity"]}',
//                           style: TextStyle(fontSize: isMobile ? 8 : 14),
//                         ),
//                       ),
//                       DataCell(
//                         Text(
//                           'Rs. ${item["price"]}',
//                           style: TextStyle(fontSize: isMobile ? 8 : 14),
//                         ),
//                       ),
//                       DataCell(
//                         Text(
//                           'Rs. ${totalPrice.toStringAsFixed(2)}',
//                           style: TextStyle(fontSize: isMobile ? 8 : 14),
//                         ),
//                       ),
//                       DataCell(
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
//                               onPressed: () => onEdit(index),
//                               padding: EdgeInsets.all(isMobile ? 2 : 6),
//                               constraints: const BoxConstraints(),
//                             ),
//                             IconButton(
//                               icon: Icon(
//                                 Icons.delete,
//                                 size: isMobile ? 16 : 18,
//                               ),
//                               onPressed: () => onRemove(index),
//                               padding: EdgeInsets.all(isMobile ? 2 : 6),
//                               constraints: const BoxConstraints(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';

class CartTable extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;

  const CartTable({
    required this.cartItems,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  @override
  State<CartTable> createState() => _CartTableState();
}

class _CartTableState extends State<CartTable> {
  int? _focusedIndex;

  @override
  Widget build(BuildContext context) {
    // Calculate the height needed for 2 items
    final double itemHeight = 120.0; // Increased height for larger fonts
    final double containerHeight = itemHeight * 2 + 32;

    return SizedBox(
      height: containerHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: widget.cartItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            double unitPrice = item["price"];
            final itemDiscount = item["itemDiscount"] ?? 0;
            unitPrice -= (item["isItemDiscountPercentage"] == true)
                ? unitPrice * itemDiscount / 100
                : itemDiscount;
            final totalPrice = unitPrice * item["quantity"];

            final bool isFocused = _focusedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _focusedIndex = isFocused ? null : index;
                });
                widget.onEdit(index);
              },
              onTapDown: (_) {
                setState(() {
                  _focusedIndex = index;
                });
              },
              onTapCancel: () {
                setState(() {
                  _focusedIndex = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: isFocused ? 12 : 16,
                ),
                transform: Matrix4.identity()..scale(isFocused ? 1.03 : 1.0),
                child: Card(
                  color: Colors.grey.shade100,
                  elevation: isFocused ? 4 : 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // First Column: Item name and price
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"],
                                style: TextStyle(
                                  fontSize: isFocused ? 26 : 24, // Larger when focused
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Price: Rs. ${item["price"]}',
                                style: TextStyle(
                                  fontSize: isFocused ? 22 : 20, // Larger when focused
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Second Column: Quantity and total price
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qty: ${item["quantity"]}',
                                style: TextStyle(
                                  fontSize: isFocused ? 22 : 20, // Larger when focused
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Total: Rs. ${totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isFocused ? 22 : 20, // Larger when focused
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Third Column: Delete icon only
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete, 
                              color: Colors.red,
                              size: isFocused ? 55 : 50, // Larger when focused
                            ),
                            onPressed: () => widget.onRemove(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}