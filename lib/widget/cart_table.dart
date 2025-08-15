import "package:flutter/material.dart";

class CartTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                horizontalMargin: isMobile ? 4 : 20,
                columnSpacing: isMobile ? 8 : 40,
                headingRowHeight: isMobile ? 20 : 32,
                dataRowMinHeight: isMobile ? 20 : 36,
                dataRowMaxHeight: isMobile ? 30 : 44,
                headingRowColor: MaterialStateColor.resolveWith(
                  (_) => Colors.grey.shade700,
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      "Item",
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Qty",
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Price",
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total",
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Action",
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                ],
                rows: cartItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  double unitPrice = item["price"];
                  final itemDiscount = item["itemDiscount"] ?? 0;
                  unitPrice -= (item["isItemDiscountPercentage"] == true)
                      ? unitPrice * itemDiscount / 100
                      : itemDiscount;
                  final totalPrice = unitPrice * item["quantity"];

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item["name"],
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item["quantity"]}',
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          'Rs. ${item["price"]}',
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          'Rs. ${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                              onPressed: () => onEdit(index),
                              padding: EdgeInsets.all(isMobile ? 2 : 6),
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: isMobile ? 16 : 18,
                              ),
                              onPressed: () => onRemove(index),
                              padding: EdgeInsets.all(isMobile ? 2 : 6),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
