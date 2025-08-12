import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../widget/search_and_categories.dart';
import '../../widget/cart_table.dart';
import '../../widget/discount_row.dart';
import '../../widget/primary_actions_row.dart';
import 'category_items_page.dart';
import 'cashier_insights_page.dart';

class CashierViewPage extends StatefulWidget {
  const CashierViewPage({super.key});

  @override
  State<CashierViewPage> createState() => _CashierViewPageState();
}

class _CashierViewPageState extends State<CashierViewPage> {
  List<String> get categories =>
      itemsByCategory.map((cat) => cat['category'] as String).toList();
  final List<List<Map<String, dynamic>>> pausedBills = [];

  final List<Map<String, dynamic>> itemsByCategory = [
    {
      'id': 1,
      'category': 'Drinks',
      'colourCode': '#FF5733',
      'items': [
        {
          'id': 1,
          'name': 'Coke',
          'colourCode': '#FF6347',
          'batches': [
            {
              'batchID': '123234',
              'pprice': 120.00,
              'price': 150.0,
              'quantity': 20,
            },
            {
              'batchID': '123237',
              'pprice': 130.00,
              'price': 160.0,
              'quantity': 20,
            },
          ],
        },
      ],
    },
    {
      'id': 2,
      'category': 'Snacks',
      'colourCode': '#C70039',
      'items': [
        {
          'id': 2,
          'name': 'Chips',
          'colourCode': '#D2691E',
          'batches': [
            {
              'batchID': '223234',
              'pprice': 90.00,
              'price': 100.0,
              'quantity': 30,
            },
          ],
        },
        {
          'id': 3,
          'name': 'Chocolate',
          'colourCode': '#8B4513',
          'batches': [
            {
              'batchID': '223237',
              'pprice': 100.00,
              'price': 120.0,
              'quantity': 25,
            },
          ],
        },
      ],
    },
    {
      'id': 3,
      'category': 'Grocery',
      'colourCode': '#900C3F',
      'items': [
        {
          'id': 4,
          'name': 'Rice',
          'colourCode': '#D3D3D3',
          'batches': [
            {
              'batchID': '323234',
              'pprice': 80.00,
              'price': 90.0,
              'quantity': 50,
            },
          ],
        },
        {
          'id': 5,
          'name': 'Sugar',
          'colourCode': '#F0E68C',
          'batches': [
            {
              'batchID': '323237',
              'pprice': 60.00,
              'price': 70.0,
              'quantity': 40,
            },
          ],
        },
      ],
    },
    {
      'id': 4,
      'category': 'Bakery',
      'colourCode': '#581845',
      'items': [
        {
          'id': 6,
          'name': 'Bread',
          'colourCode': '#FFD700',
          'batches': [
            {
              'batchID': '423234',
              'pprice': 70.00,
              'price': 80.0,
              'quantity': 15,
            },
          ],
        },
        {
          'id': 7,
          'name': 'Bun',
          'colourCode': '#BC8F8F',
          'batches': [
            {
              'batchID': '423237',
              'pprice': 50.00,
              'price': 60.0,
              'quantity': 20,
            },
          ],
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> cartItems = [];
  String searchQuery = '';
  bool isPercentageDiscount = true;
  double discount = 0;

  // ----------------- EXISTING BILLING FUNCTIONS -----------------

  void _pauseCurrentBill() {
    if (cartItems.isEmpty) return;

    pausedBills.add(List<Map<String, dynamic>>.from(cartItems));
    setState(() {
      cartItems.clear();
      discount = 0;
      searchQuery = '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bill paused successfully")));
  }

  // Auto resume (no button)
  void _autoResumeNextPausedBill() {
    if (pausedBills.isEmpty) return;
    final next = pausedBills.removeAt(0);
    setState(() {
      cartItems.clear();
      cartItems.addAll(next);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Resumed paused bill")));
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Card'),
              onTap: () {
                Navigator.pop(context);
                _printBill(paymentMethod: 'Card');
              },
            ),
            ListTile(
              title: const Text('Cash'),
              onTap: () {
                Navigator.pop(context);
                _showCashPaymentDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCashPaymentDialog() {
    double cashGiven = 0;
    final cashController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Cash Amount'),
        content: TextField(
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: cashController,
          decoration: const InputDecoration(hintText: 'Enter cash amount'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cashGiven = double.tryParse(cashController.text) ?? 0;
              final total = _calculateTotal();

              if (cashGiven < total) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cash amount is less than total'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final balance = cashGiven - total;
              _printBill(
                paymentMethod: 'Cash',
                cashGiven: cashGiven,
                balance: balance,
              );
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _printBill({
    required String paymentMethod,
    double cashGiven = 0,
    double balance = 0,
  }) {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    final bill = StringBuffer();
    bill.writeln('------- AASA POS BILL -------\n');
    bill.writeln('Date: $formattedDateTime');
    bill.writeln('------------------------------');
    bill.writeln('Items:');
    bill.writeln('------------------------------');

    for (var item in cartItems) {
      final name = item['name'];
      final qty = item['quantity'];
      final price = (item['price'] as num).toDouble();
      final itemDiscount = (item['itemDiscount'] as num?)?.toDouble() ?? 0.0;
      final isPercentage = item['isItemDiscountPercentage'] == true;

      double finalUnitPrice = price;
      if (isPercentage) {
        finalUnitPrice -= price * itemDiscount / 100;
      } else {
        finalUnitPrice -= itemDiscount;
      }

      final total = finalUnitPrice * qty;

      bill.writeln('$name\n  Qty: $qty x Rs. ${price.toStringAsFixed(2)}');
      if (itemDiscount > 0) {
        bill.writeln(
          '  Discount: ${itemDiscount.toStringAsFixed(2)} ${isPercentage ? "%" : "Rs"}',
        );
      }
      bill.writeln('  Final Price: Rs. ${finalUnitPrice.toStringAsFixed(2)}');
      bill.writeln('  Line Total: Rs. ${total.toStringAsFixed(2)}\n');
    }

    bill.writeln('------------------------------');
    bill.writeln('Subtotal: Rs. ${_calculateTotal().toStringAsFixed(2)}');

    if (discount > 0) {
      final discountText = isPercentageDiscount
          ? '$discount%'
          : 'Rs. ${discount.toStringAsFixed(2)}';
      bill.writeln('Overall Discount: $discountText');
    }

    bill.writeln('Payment Method: $paymentMethod');
    if (paymentMethod == 'Cash') {
      bill.writeln('Cash Given: Rs. ${cashGiven.toStringAsFixed(2)}');
      bill.writeln('Balance: Rs. ${balance.toStringAsFixed(2)}');
    }

    bill.writeln('\nThank you for shopping with us!');
    bill.writeln('------------------------------');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bill Printed'),
        content: SingleChildScrollView(child: Text(bill.toString())),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                cartItems.clear();
                discount = 0;
                searchQuery = '';
              });

              // 👉 show the picker only if there are paused bills
              if (pausedBills.isNotEmpty) {
                _promptSelectPausedBill();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _addToCart(
    Map<String, dynamic> batch, {
    int quantity = 1,
    bool fromSearch = false,
  }) {
    final existingIndex = cartItems.indexWhere(
      (i) => i['name'] == batch['name'] && i['batchID'] == batch['batchID'],
    );
    if (existingIndex >= 0) {
      cartItems[existingIndex]['quantity'] += quantity;
    } else {
      cartItems.add({
        'name': batch['name'],
        'price': batch['price'],
        'batchID': batch['batchID'],
        'quantity': quantity,
        'itemDiscount': 0.0,
        'isItemDiscountPercentage': false,
      });
    }
    setState(() {
      if (fromSearch) {
        searchQuery = '';
      }
    });

    if (!fromSearch) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showBatchSelectionDialog(
    Map<String, dynamic> item, {
    bool fromSearch = false,
  }) {
    final List<Map<String, dynamic>> batchList =
        List<Map<String, dynamic>>.from(item['batches'] ?? []);
    if (batchList.isEmpty) return;

    if (batchList.length == 1) {
      final selectedBatch = batchList[0];
      selectedBatch['name'] = item['name'];
      _showQuantityInputDialog(selectedBatch);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Select Batch for ${item['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: batchList.length,
            itemBuilder: (context, index) {
              final batch = batchList[index];
              return ListTile(
                title: Text(
                  'Batch: ${batch['batchID']} - Price: Rs. ${batch['price']}',
                ),
                onTap: () {
                  batch['name'] = item['name'];
                  Navigator.pop(context);
                  _showQuantityInputDialog(batch);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showQuantityInputDialog(Map<String, dynamic> batch) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Enter quantity for ${batch['name']} (Batch: ${batch['batchID']})',
        ),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (value) => quantity = int.tryParse(value) ?? 1,
          onSubmitted: (value) {
            quantity = int.tryParse(value) ?? 1;
            Navigator.pop(context);
            _addToCart(batch, quantity: quantity);
          },
          decoration: const InputDecoration(hintText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addToCart(batch, quantity: quantity);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCartItem(int index) {
    int quantity = cartItems[index]['quantity'];
    double itemDiscount =
        (cartItems[index]['itemDiscount'] as num?)?.toDouble() ?? 0.0;
    bool isPercentage = cartItems[index]['isItemDiscountPercentage'] == true;

    final quantityController = TextEditingController(text: quantity.toString());
    final discountController = TextEditingController(
      text: itemDiscount.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${cartItems[index]['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              controller: quantityController,
              onChanged: (value) => quantity = int.tryParse(value) ?? quantity,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: isPercentage ? 'Discount (%)' : 'Discount (Rs)',
              ),
              keyboardType: TextInputType.number,
              controller: discountController,
              onChanged: (value) =>
                  itemDiscount = double.tryParse(value) ?? itemDiscount,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Discount Type: '),
                DropdownButton<bool>(
                  value: isPercentage,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('%')),
                    DropdownMenuItem(value: false, child: Text('Rs')),
                  ],
                  onChanged: (value) => setState(() => isPercentage = value!),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (quantity <= 0) {
                  cartItems.removeAt(index);
                } else {
                  cartItems[index]['quantity'] = quantity;
                  cartItems[index]['itemDiscount'] = itemDiscount;
                  cartItems[index]['isItemDiscountPercentage'] = isPercentage;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    String barcode = '';
    String itemName = '';
    String selectedCategory = categories.first;
    double sellingPrice = 0.0;
    Color selectedColor = const Color.fromARGB(255, 236, 236, 236);

    final barcodeController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Scan or enter barcode',
                  ),
                  onChanged: (value) => barcode = value.trim(),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  onChanged: (value) => itemName = value.trim(),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedCategory = value;
                  },
                ),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (Rs)',
                  ),
                  onChanged: (value) =>
                      sellingPrice = double.tryParse(value) ?? 0.0,
                ),
                const SizedBox(height: 10),
                const Text('Pick Item Color'),
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) =>
                      setStateSB(() => selectedColor = color),
                  showLabel: false,
                  pickerAreaHeightPercent: 0.6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                barcode = barcodeController.text.trim();
                itemName = nameController.text.trim();
                sellingPrice = double.tryParse(priceController.text) ?? 0.0;

                if (barcode.isEmpty ||
                    itemName.isEmpty ||
                    sellingPrice <= 0.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all fields correctly."),
                    ),
                  );
                  return;
                }

                final newItem = {
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'colourCode':
                      '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  'name': itemName,
                  'batches': [
                    {
                      'batchID': barcode,
                      'pprice': 0.0,
                      'price': sellingPrice,
                      'quantity': 100,
                    },
                  ],
                };

                setState(() {
                  final category = itemsByCategory.firstWhere(
                    (cat) => cat['category'] == selectedCategory,
                    orElse: () => {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'category': selectedCategory,
                      'colourCode': '#FF9800',
                      'items': [],
                    },
                  );

                  category['items'].add(newItem);

                  if (!itemsByCategory.contains(category)) {
                    itemsByCategory.add(category);
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Item added successfully.")),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptSelectPausedBill() {
    if (pausedBills.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resume a paused bill?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pausedBills.length,
            itemBuilder: (context, index) {
              final bill = pausedBills[index];
              final itemNames = bill.map((i) => i['name']).join(', ');
              // compute approx total
              double total = 0;
              for (final it in bill) {
                final price = (it['price'] as num).toDouble();
                final qty = (it['quantity'] as int);
                final d = (it['itemDiscount'] as num?)?.toDouble() ?? 0;
                final isPct = it['isItemDiscountPercentage'] == true;
                double unit = price - (isPct ? price * d / 100 : d);
                total += unit * qty;
              }

              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  'Bill ${index + 1} • Rs. ${total.toStringAsFixed(2)}',
                ),
                subtitle: Text(
                  itemNames,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _resumeBill(index);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  void _resumeBill(int index) {
    setState(() {
      cartItems.clear();
      cartItems.addAll(pausedBills[index]);
      pausedBills.removeAt(index);
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      double unitPrice = (item['price'] as num).toDouble();
      final itemDiscount = (item['itemDiscount'] as num?)?.toDouble() ?? 0;
      if (item['isItemDiscountPercentage'] == true) {
        unitPrice -= unitPrice * itemDiscount / 100;
      } else {
        unitPrice -= itemDiscount;
      }
      total += unitPrice * (item['quantity'] as int);
    }
    return isPercentageDiscount
        ? total - (total * discount / 100)
        : total - discount;
  }

  Widget _buildResponsiveCartTable(BuildContext context) {
    return CartTable(
      cartItems: cartItems,
      onEdit: _editCartItem,
      onRemove: (index) => setState(() => cartItems.removeAt(index)),
    );
  }

  // Simple pause-only row (replaces PauseResumeRow)
  Widget _buildPauseOnlyRow({
    required VoidCallback? onPause,
    double horizontalPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: onPause,
          icon: const Icon(Icons.pause_circle_filled),
          label: const Text('Pause Bill'),
          style: ElevatedButton.styleFrom(
            disabledForegroundColor: Colors.white54,
            disabledBackgroundColor: Colors.white12,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ===================== QUICK SALE: NEW CODE =====================

  /// Entry point for Quick Sale. If there is an active bill, pause it first.
  void _handleQuickSale() async {
    // Pause current bill if needed
    if (cartItems.isNotEmpty) {
      _pauseCurrentBill();
    }
    // Collect quick sale details
    final item = await _showQuickSaleInputDialog();
    if (item == null) return; // user cancelled

    // Separate payment flow for quick sale
    _showQuickSalePaymentMethodDialog(item);
  }

  /// Dialog to collect: Name, Quantity, Unit Cost, Price.
  /// Returns a map or null if cancelled.
  Future<Map<String, dynamic>?> _showQuickSaleInputDialog() async {
    String name = '';
    int qty = 1;
    double unitCost = 0.0;
    double price = 0.0;

    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible:
          true, // Allows closing the dialog when tapping outside
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          String? errorText;

          void validate() {
            final q = int.tryParse(qtyCtrl.text.trim()) ?? 0;
            final uc = double.tryParse(costCtrl.text.trim()) ?? -1;
            final pr = double.tryParse(priceCtrl.text.trim()) ?? -1;
            if (nameCtrl.text.trim().isEmpty || q <= 0 || uc < 0 || pr <= 0) {
              errorText =
                  'Please enter a name and positive values for quantity and price.';
            } else {
              errorText = null;
            }
            setSB(() {});
          }

          return AlertDialog(
            title: const Text('Quick Sale'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (_) => validate(),
                  ),
                  TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => validate(),
                  ),
                  TextField(
                    controller: costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost (Rs)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => validate(),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (Rs)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => validate(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                label: const Text('Pay'),
                onPressed: () {
                  name = nameCtrl.text.trim();
                  qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  unitCost = double.tryParse(costCtrl.text.trim()) ?? -1;
                  price = double.tryParse(priceCtrl.text.trim()) ?? -1;

                  if (name.isEmpty || qty <= 0 || price <= 0 || unitCost < 0) {
                    return; // validation message shown above
                  }

                  Navigator.pop(context, {
                    'name': name,
                    'quantity': qty,
                    'unitCost': unitCost,
                    'price': price,
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Separate payment chooser for quick sale.
  void _showQuickSalePaymentMethodDialog(Map<String, dynamic> quickItem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Card'),
              onTap: () {
                Navigator.pop(context);
                _printQuickSaleBill(item: quickItem, paymentMethod: 'Card');
              },
            ),
            ListTile(
              title: const Text('Cash'),
              onTap: () {
                Navigator.pop(context);
                _showQuickSaleCashDialog(quickItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Cash flow for quick sale only.
  void _showQuickSaleCashDialog(Map<String, dynamic> quickItem) {
    final total =
        (quickItem['price'] as double) * (quickItem['quantity'] as int);

    final cashCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Cash Amount'),
        content: TextField(
          autofocus: true,
          controller: cashCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Enter cash amount'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final cash = double.tryParse(cashCtrl.text.trim()) ?? 0;
              if (cash < total) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cash amount is less than total'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _printQuickSaleBill(
                item: quickItem,
                paymentMethod: 'Cash',
                cashGiven: cash,
                balance: cash - total,
              );
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  /// Prints a bill specifically for a single quick-sale item.
  void _printQuickSaleBill({
    required Map<String, dynamic> item,
    required String paymentMethod,
    double cashGiven = 0,
    double balance = 0,
  }) {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    final name = item['name'] as String;
    final qty = item['quantity'] as int;
    final unitCost = (item['unitCost'] as num).toDouble();
    final price = (item['price'] as num).toDouble();
    final total = price * qty;

    final bill = StringBuffer();
    bill.writeln('------- AASA POS QUICK SALE -------\n');
    bill.writeln('Date: $formattedDateTime');
    bill.writeln('------------------------------');
    bill.writeln('Item: $name');
    bill.writeln('Qty: $qty');
    bill.writeln('Unit Cost: Rs. ${unitCost.toStringAsFixed(2)}');
    bill.writeln('Price (per unit): Rs. ${price.toStringAsFixed(2)}');
    bill.writeln('------------------------------');
    bill.writeln('Total: Rs. ${total.toStringAsFixed(2)}');
    bill.writeln('Payment Method: $paymentMethod');
    if (paymentMethod == 'Cash') {
      bill.writeln('Cash Given: Rs. ${cashGiven.toStringAsFixed(2)}');
      bill.writeln('Balance: Rs. ${balance.toStringAsFixed(2)}');
    }
    bill.writeln('\nThank you for your purchase!');
    bill.writeln('------------------------------');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quick Sale Bill Printed'),
        content: SingleChildScrollView(child: Text(bill.toString())),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // After quick sale, if there are paused bills, offer to resume
              if (pausedBills.isNotEmpty) {
                _promptSelectPausedBill();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Reusable Quick Sale button (for both layouts)
  Widget _buildQuickSaleButton({
    double horizontalPadding = 0,
    bool isWideScreen = false, // <— NEW PARAM
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _handleQuickSale,
          icon: Icon(
            Icons.flash_on,
            size: isWideScreen ? 30 : 20, // bigger icon on wide screens
          ),
          label: Text(
            'Quick Sale',
            style: TextStyle(
              fontSize: isWideScreen ? 22 : 16, // bigger text on wide screens
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 40 : 22, // bigger horizontal padding
              vertical: isWideScreen ? 20 : 14, // bigger vertical padding
            ),
            minimumSize: isWideScreen
                ? const Size(200, 60)
                : null, // fixed big size
          ),
        ),
      ),
    );
  }

  // =================== UI / LAYOUT ===================

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0D1B2A),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cashier'),
              Row(
                children: [
                  const Text(
                    'John Doe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashierInsightsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 1000;
            return isWideScreen
                ? _buildDesktopLayout(context)
                : _buildCompactLayout(context, constraints.maxWidth);
          },
        ),
      ),
    );
  }

  /// ===== Desktop / Wide layout (>= 1000px) =====
  Widget _buildDesktopLayout(BuildContext context) {
    final searchedItems = itemsByCategory
        .expand((cat) => cat['items'] as List<Map<String, dynamic>>)
        .where((item) {
          final name = item['name'].toString().toLowerCase();
          final idStr = item['id'].toString();
          return name.contains(searchQuery.toLowerCase()) ||
              idStr == searchQuery.trim();
        })
        .toList();

    return Row(
      children: [
        // LEFT
        Expanded(
          flex: 3,
          child: SearchAndCategories(
            searchQuery: searchQuery,
            onSearchChange: (v) => setState(() => searchQuery = v),
            itemsByCategory: itemsByCategory,
            categories: categories,
            searchedItems: searchedItems,
            onCategoryTap: (cat) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryItemsPage(
                    category: cat,
                    items: itemsByCategory.firstWhere(
                      (c) => c['category'] == cat,
                    )['items'],
                    onItemSelected: _showBatchSelectionDialog,
                  ),
                ),
              );
            },
            onSearchedItemTap: (item) =>
                _showBatchSelectionDialog(item, fromSearch: true),
          ),
        ),

        // RIGHT
        Expanded(
          flex: 4,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Bill Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              DiscountRow(
                discount: discount,
                isPercentageDiscount: isPercentageDiscount,
                onDiscountChange: (v) =>
                    setState(() => discount = double.tryParse(v) ?? 0),
                onTypeChange: (v) => setState(() => isPercentageDiscount = v),
              ),
              Expanded(child: _buildResponsiveCartTable(context)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Total: Rs. ${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PrimaryActionsRow(
                onAddItem: _showAddItemDialog,
                onPay: cartItems.isEmpty ? null : _showPaymentMethodDialog,
                payEnabled: cartItems.isNotEmpty,
              ),

              // NEW: Quick Sale button
              _buildQuickSaleButton(isWideScreen: true),

              // pause-only row (no resume button)
              _buildPauseOnlyRow(
                onPause: cartItems.isEmpty ? null : _pauseCurrentBill,
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Powered by AASA IT',
                  style: TextStyle(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ===== Compact layout (< 1000px) =====
  Widget _buildCompactLayout(BuildContext context, double width) {
    final crossAxisCount = width >= 800
        ? 6
        : width >= 700
        ? 5
        : width >= 600
        ? 4
        : 4;

    final searchedItems = itemsByCategory
        .expand((cat) => cat['items'] as List<Map<String, dynamic>>)
        .where((item) {
          final name = item['name'].toString().toLowerCase();
          final idStr = item['id'].toString();
          return name.contains(searchQuery.toLowerCase()) ||
              idStr == searchQuery.trim();
        })
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: SearchAndCategories(
              searchQuery: searchQuery,
              onSearchChange: (v) => setState(() => searchQuery = v),
              itemsByCategory: itemsByCategory,
              categories: categories,
              searchedItems: searchedItems,
              gridHeight: 300,
              gridCrossAxisCount: crossAxisCount,
              onCategoryTap: (cat) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryItemsPage(
                      category: cat,
                      items: itemsByCategory.firstWhere(
                        (c) => c['category'] == cat,
                      )['items'],
                      onItemSelected: _showBatchSelectionDialog,
                    ),
                  ),
                );
              },
              onSearchedItemTap: (item) =>
                  _showBatchSelectionDialog(item, fromSearch: true),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Bill Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          DiscountRow(
            discount: discount,
            isPercentageDiscount: isPercentageDiscount,
            onDiscountChange: (v) =>
                setState(() => discount = double.tryParse(v) ?? 0),
            onTypeChange: (v) => setState(() => isPercentageDiscount = v),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: _buildResponsiveCartTable(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Total: Rs. ${_calculateTotal().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          PrimaryActionsRow(
            onAddItem: _showAddItemDialog,
            onPay: cartItems.isEmpty ? null : _showPaymentMethodDialog,
            payEnabled: cartItems.isNotEmpty,
            horizontalPadding: 40,
          ),

          // NEW: Quick Sale button
          _buildQuickSaleButton(horizontalPadding: 40),

          // pause-only row (no resume button)
          _buildPauseOnlyRow(
            onPause: cartItems.isEmpty ? null : _pauseCurrentBill,
            horizontalPadding: 40,
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Center(
              child: Text(
                'Powered by AASA IT',
                style: TextStyle(
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
