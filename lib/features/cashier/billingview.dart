import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      'colourCode': '#FF5733', // Color code for Drinks
      'items': [
        {
          'id': 1,
          'name': 'Coke',
          'colourCode': '#FF6347', // Color code for Coke item
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
      'colourCode': '#C70039', // Color code for Snacks
      'items': [
        {
          'id': 2,
          'name': 'Chips',
          'colourCode': '#D2691E', // Color code for Chips item
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
          'colourCode': '#8B4513', // Color code for Chocolate item
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
      'colourCode': '#900C3F', // Color code for Grocery
      'items': [
        {
          'id': 4,
          'name': 'Rice',
          'colourCode': '#D3D3D3', // Color code for Rice item
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
          'colourCode': '#F0E68C', // Color code for Sugar item
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
      'colourCode': '#581845', // Color code for Bakery
      'items': [
        {
          'id': 6,
          'name': 'Bread',
          'colourCode': '#FFD700', // Color code for Bread item
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
          'colourCode': '#BC8F8F', // Color code for Bun item
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

  void _resumeBill(int index) {
    setState(() {
      cartItems.clear();
      cartItems.addAll(pausedBills[index]);
      pausedBills.removeAt(index);
    });
  }

  void _showPausedBillsDialog() {
    if (pausedBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No paused bills available")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paused Bills'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pausedBills.length,
            itemBuilder: (context, index) {
              final bill = pausedBills[index];
              final itemNames = bill.map((item) => item['name']).join(', ');
              return ListTile(
                title: Text('Bill ${index + 1}'),
                subtitle: Text(itemNames),
                onTap: () {
                  Navigator.pop(context);
                  _resumeBill(index);
                },
              );
            },
          ),
        ),
      ),
    );
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
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          controller: cashController,
          decoration: const InputDecoration(hintText: 'Enter cash amount'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cashGiven = double.tryParse(cashController.text) ?? 0;
              double total = _calculateTotal();

              if (cashGiven < total) {
                // Show error if cash given is less than total
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cash amount is less than total'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              double balance = cashGiven - total;
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

    StringBuffer bill = StringBuffer();
    bill.writeln('------- AASA POS BILL -------\n');
    bill.writeln('Date: $formattedDateTime');
    bill.writeln('------------------------------');
    bill.writeln('Items:');
    bill.writeln('------------------------------');

    for (var item in cartItems) {
      String name = item['name'];
      int qty = item['quantity'];
      double price = item['price'];
      double itemDiscount = item['itemDiscount'] ?? 0.0;
      bool isPercentage = item['isItemDiscountPercentage'] ?? false;

      double finalUnitPrice = price;
      if (isPercentage) {
        finalUnitPrice -= price * itemDiscount / 100;
      } else {
        finalUnitPrice -= itemDiscount;
      }

      double total = finalUnitPrice * qty;

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
      String discountText = isPercentageDiscount
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
        searchQuery = ''; // ✅ clear search bar
      }
    });

    if (!fromSearch) {
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      ); // ✅ go back to billing view
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
          onChanged: (value) {
            quantity = int.tryParse(value) ?? 1;
          },
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
    double itemDiscount = cartItems[index]['itemDiscount'] ?? 0.0;
    bool isPercentage = cartItems[index]['isItemDiscountPercentage'] ?? false;

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
    Color selectedColor = Colors.deepOrange; // Default color

    final barcodeController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedCategory = value;
                  },
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                      setState(() => selectedColor = color),
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

  double _calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      double unitPrice = item['price'];
      double itemDiscount = item['itemDiscount'] ?? 0;
      if (item['isItemDiscountPercentage'] == true) {
        unitPrice -= unitPrice * itemDiscount / 100;
      } else {
        unitPrice -= itemDiscount;
      }
      total += unitPrice * item['quantity'];
    }
    return isPercentageDiscount
        ? total - (total * discount / 100)
        : total - discount;
  }

  Widget _buildResponsiveCartTable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal, // allow horizontal scroll if needed
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                // spacing responsive to width
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
                      'Item',
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Qty',
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price',
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: TextStyle(fontSize: isMobile ? 8 : 14),
                    ),
                  ),
                ],
                rows: cartItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  double unitPrice = item['price'];
                  final itemDiscount = item['itemDiscount'] ?? 0;
                  unitPrice -= (item['isItemDiscountPercentage'] == true)
                      ? unitPrice * itemDiscount / 100
                      : itemDiscount;
                  final totalPrice = unitPrice * item['quantity'];

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item['name'],
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item['quantity']}',
                          style: TextStyle(fontSize: isMobile ? 8 : 14),
                        ),
                      ),
                      DataCell(
                        Text(
                          'Rs. ${item['price']}',
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
                              onPressed: () => _editCartItem(index),
                              padding: EdgeInsets.all(isMobile ? 2 : 6),
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: isMobile ? 16 : 18,
                              ),
                              onPressed: () =>
                                  setState(() => cartItems.removeAt(index)),
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

  @override
  Widget build(BuildContext context) {
    final searchedItems = itemsByCategory
        .expand((cat) => cat['items'] as List<Map<String, dynamic>>)
        .where((item) {
          final name = item['name'].toString().toLowerCase();
          final idStr = item['id'].toString();
          return name.contains(searchQuery.toLowerCase()) ||
              idStr == searchQuery.trim();
        })
        .toList();

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0D1B2A),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Cashier'),
              Text(
                'John Doe',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1000;
            final isMobile = MediaQuery.of(context).size.width < 600;

            if (isWideScreen) {
              // ... (keep your existing wide screen layout here)
              return Theme(
                data: ThemeData.dark(),
                child: Scaffold(
                  body: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          // 🔵 LEFT SIDE: Search + Categories
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: TextField(
                                    onChanged: (value) =>
                                        setState(() => searchQuery = value),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search item or scan barcode...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: searchQuery.isEmpty
                                      ? GridView.count(
                                          crossAxisCount: 4,
                                          padding: const EdgeInsets.all(10),
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          children: categories.map((cat) {
                                            final colorCode = itemsByCategory
                                                .firstWhere(
                                                  (item) =>
                                                      item['category'] == cat,
                                                )['colourCode'];

                                            return GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CategoryItemsPage(
                                                    category: cat,
                                                    items: itemsByCategory
                                                        .firstWhere(
                                                          (c) =>
                                                              c['category'] ==
                                                              cat,
                                                        )['items'],
                                                    onItemSelected:
                                                        _showBatchSelectionDialog,
                                                  ),
                                                ),
                                              ),
                                              child: Card(
                                                color: Color(
                                                  int.parse(
                                                    "0xFF${colorCode.replaceAll('#', '')}",
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cat,
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 10
                                                          : 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : ListView(
                                          children: searchedItems.map((item) {
                                            final firstBatch =
                                                item['batches'][0];
                                            return ListTile(
                                              title: Text(item['name']),
                                              trailing: Text(
                                                'Rs. ${firstBatch['price']}',
                                              ),
                                              onTap: () =>
                                                  _showBatchSelectionDialog(
                                                    item,
                                                    fromSearch: true,
                                                  ),
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // 🔴 RIGHT SIDE: Bill Summary
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Bill Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Discount: "),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                        ),
                                        onChanged: (value) => setState(
                                          () => discount =
                                              double.tryParse(value) ?? 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    DropdownButton<bool>(
                                      value: isPercentageDiscount,
                                      items: const [
                                        DropdownMenuItem(
                                          value: true,
                                          child: Text('%'),
                                        ),
                                        DropdownMenuItem(
                                          value: false,
                                          child: Text('Rs'),
                                        ),
                                      ],
                                      onChanged: (value) => setState(
                                        () => isPercentageDiscount = value!,
                                      ),
                                    ),
                                  ],
                                ),
                                // 🧾 Cart Table
                                Expanded(
                                  child: _buildResponsiveCartTable(context),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Total: Rs. ${_calculateTotal().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 10,
                                    left: 40,
                                    right: 40,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _showAddItemDialog,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Item'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          minimumSize: const Size(130, 40),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: cartItems.isEmpty
                                            ? null
                                            : _showPaymentMethodDialog,
                                        child: const Text('Pay'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(130, 40),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: cartItems.isEmpty
                                            ? null
                                            : _pauseCurrentBill,
                                        icon: const Icon(Icons.pause),
                                        label: const Text('Pause'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          minimumSize: const Size(130, 40),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: pausedBills.isEmpty
                                            ? null
                                            : _showPausedBillsDialog,
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Resume'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          minimumSize: const Size(130, 40),
                                        ),
                                      ),
                                    ],
                                  ),
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
                    },
                  ),
                ),
              );
            } else {
              // MOBILE/TABLET VIEW: Column layout for small screens
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search item or scan barcode...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Categories or Searched Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 300,
                        child: searchQuery.isEmpty
                            ? GridView.count(
                                crossAxisCount: 4,
                                padding: const EdgeInsets.all(10),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                children: categories.map((cat) {
                                  final colorCode = itemsByCategory.firstWhere(
                                    (item) => item['category'] == cat,
                                  )['colourCode'];

                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryItemsPage(
                                          category: cat,
                                          items: itemsByCategory.firstWhere(
                                            (c) => c['category'] == cat,
                                          )['items'],
                                          onItemSelected:
                                              _showBatchSelectionDialog,
                                        ),
                                      ),
                                    ),
                                    child: Card(
                                      color: Color(
                                        int.parse(
                                          "0xFF${colorCode.replaceAll('#', '')}",
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          cat,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : ListView(
                                children: searchedItems.map((item) {
                                  final firstBatch = item['batches'][0];
                                  return ListTile(
                                    title: Text(item['name']),
                                    trailing: Text(
                                      'Rs. ${firstBatch['price']}',
                                    ),
                                    onTap: () => _showBatchSelectionDialog(
                                      item,
                                      fromSearch: true,
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Discount: "),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            onChanged: (value) => setState(
                              () => discount = double.tryParse(value) ?? 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<bool>(
                          value: isPercentageDiscount,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('%')),
                            DropdownMenuItem(value: false, child: Text('Rs')),
                          ],
                          onChanged: (value) =>
                              setState(() => isPercentageDiscount = value!),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: _buildResponsiveCartTable(context),
                    ),

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

                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                        left: 40,
                        right: 40,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              minimumSize: const Size(130, 40),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : _showPaymentMethodDialog,
                            child: const Text('Pay'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(130, 40),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : _pauseCurrentBill,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              minimumSize: const Size(130, 40),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: pausedBills.isEmpty
                                ? null
                                : _showPausedBillsDialog,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(130, 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
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
          },
        ),
      ),
    );
  }
}

class CategoryItemsPage extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onItemSelected;

  const CategoryItemsPage({
    super.key,
    required this.category,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(category)),
        body: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(10),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: items.map((item) {
            final firstBatch = item['batches']?[0];
            final price = firstBatch != null ? firstBatch['price'] : 'N/A';
            final itemColorCode =
                item['colourCode']; // Retrieve item color code

            return GestureDetector(
              onTap: () => onItemSelected(item),
              child: Card(
                color: Color(
                  int.parse("0xFF${itemColorCode.replaceAll('#', '')}"),
                ), // Apply the item's color code
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Rs. $price', style: TextStyle(fontSize: 10)),
                    ],
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
