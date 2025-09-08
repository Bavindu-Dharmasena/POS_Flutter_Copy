// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:dio/dio.dart';

// import '../../widget/search_and_categories.dart';
// import '../../widget/cart_table.dart';
// import '../../widget/discount_row.dart';
// import 'category_items_page.dart';
// import 'cashier_insights_page.dart';
// import '../../widget/primary_actions_row.dart';
// import '../../data/repositories/cashier/cashier_repository.dart';
// import '../../data/models/cashier/cashier.dart';

// // ---- Keyboard Intents ----
// class ActivateSearchIntent extends Intent { const ActivateSearchIntent(); }
// class QuickSaleIntent extends Intent { const QuickSaleIntent(); }
// class PauseBillIntent extends Intent { const PauseBillIntent(); }
// class ResumeBillIntent extends Intent { const ResumeBillIntent(); }
// class PayIntent extends Intent { const PayIntent(); }
// class ShowHelpIntent extends Intent { const ShowHelpIntent(); }
// class BackIntent extends Intent { const BackIntent(); }
// class FocusCategoriesIntent extends Intent { const FocusCategoriesIntent(); }
// class FocusHeaderMenuIntent extends Intent { const FocusHeaderMenuIntent(); }

// class CashierViewPage extends StatefulWidget {
//   const CashierViewPage({super.key});
//   @override
//   State<CashierViewPage> createState() => _CashierViewPageState();
// }

// class _CashierViewPageState extends State<CashierViewPage> {
//   // ----------------- SAMPLE DATA -----------------
//   final CashierRepository _cashierrepo = CashierRepository();
//   List<String> get categories =>
//       itemsByCategory.map((cat) => (cat['category'] ?? '').toString()).toList();

//   final List<List<Map<String, dynamic>>> pausedBills = [];
//   List<Map<String, dynamic>> itemsByCategory = []; // will be filled from API
//   bool _loading = true;
//   String? _error;

//   final List<Map<String, dynamic>> cartItems = [];
//   String searchQuery = '';
//   bool isPercentageDiscount = true;
//   double discount = 0;

//   // ----------------- FOCUS NODES -----------------
//   final FocusNode _quickSaleBtnNode = FocusNode(debugLabel: 'QuickSaleBtn');
//   final FocusNode _payBtnNode = FocusNode(debugLabel: 'PayBtn');
//   final FocusNode _newSaleBtnNode = FocusNode(debugLabel: 'NewSaleBtn');
//   final FocusNode _cartAreaNode = FocusNode(debugLabel: 'CartArea');
//   final FocusNode _discountAreaNode = FocusNode(debugLabel: 'DiscountArea');
//   final FocusNode _categoriesFocusNode = FocusNode(debugLabel: 'CategoriesArea');
//   final FocusNode _searchFieldNode = FocusNode(debugLabel: 'SearchField');
//   final FocusNode _headerMenuBtnNode = FocusNode(debugLabel: 'HeaderMenuBtn');
//   final TextEditingController _searchController = TextEditingController();

//   // static const String _path = '/cashier/categories';
//   // static const String _baseUrl = "http://localhost:3001";

//   // final Dio _dio = Dio(BaseOptions(
//   //   // ⭐ sensible timeouts
//   //   connectTimeout: const Duration(seconds: 8),
//   //   receiveTimeout: const Duration(seconds: 8),
//   //   sendTimeout: const Duration(seconds: 8),
//   //   // ⭐ JSON
//   //   responseType: ResponseType.json,
//   //   // You can add headers/auth here if needed
//   // ));

//   // ----------------- Scanner state -----------------
//   bool _scannerOpen = false;

//   // ⭐ INIT: actually load the catalog on page open
//   @override
//   void initState() {
//     super.initState();
//     _loadCatalog();
//   }

//   @override
//   void dispose() {
//     _quickSaleBtnNode.dispose();
//     _payBtnNode.dispose();
//     _newSaleBtnNode.dispose();
//     _cartAreaNode.dispose();
//     _discountAreaNode.dispose();
//     _categoriesFocusNode.dispose();
//     _searchFieldNode.dispose();
//     _searchController.dispose();
//     _headerMenuBtnNode.dispose();
//     super.dispose();
//   }

//   // ⭐ Fetch from your API and map to the UI shape
//   // Future<void> _loadCatalog() async {
//   //   setState(() {
//   //     _loading = true;
//   //     _error = null;
//   //   });

//   //   try {
//   //     final res = await _dio.get('$_baseUrl$_path');
//   //     final data = res.data;

//   //     if (data is! List) {
//   //       throw const FormatException('Unexpected JSON shape (expected List)');
//   //     }

//   //     itemsByCategory = _mapApiToUi(data);
//   //     setState(() => _loading = false);
//   //   } catch (e) {
//   //     setState(() {
//   //       _error = e.toString();
//   //       _loading = false;
//   //     });
//   //   }
//   // }

//   // /// Transform API → same shape as dummy
//   // List<Map<String, dynamic>> _mapApiToUi(List<dynamic> api) {
//   //   return api.map<Map<String, dynamic>>((rawCat) {
//   //     final Map<String, dynamic> cat = Map<String, dynamic>.from(rawCat as Map);
//   //     final items = (cat['items'] as List? ?? const [])
//   //         .map<Map<String, dynamic>>((rawIt) {
//   //       final it = Map<String, dynamic>.from(rawIt as Map);
//   //       final batches = (it['batches'] as List? ?? const [])
//   //           .map<Map<String, dynamic>>((b) => Map<String, dynamic>.from(b as Map))
//   //           .toList();

//   //       return {
//   //         'id': it['id'],
//   //         'itemcode': it['itemcode'],
//   //         'name': it['name'],
//   //         'colourCode': it['colorCode'] ?? it['colourCode'] ?? '#777777',
//   //         'itemImage': _itemImageFor((it['name'] ?? '').toString()),
//   //         'batches': batches,
//   //       };
//   //     }).toList();

//   //     final catName = (cat['category'] ?? '').toString();
//   //     return {
//   //       'id': cat['id'],
//   //       'category': catName,
//   //       'colourCode': cat['colorCode'] ?? cat['colourCode'] ?? '#555555',
//   //       'categoryImage': _categoryImageFor(catName),
//   //       'items': items,
//   //     };
//   //   }).toList();
//   // }

//   // String _categoryImageFor(String cat) =>
//   //     'assets/cat/${cat.toLowerCase().replaceAll(' ', '_')}.png';
//   // String _itemImageFor(String name) => 'assets/item/default.png';

//   Future<void> _loadCatalog() async {
//   setState(() => _loading = true);

//   final data = await _cashierrepo.getCategoriesWithItemsAndBatches();

//   setState(() {
//     itemsByCategory = data; // _categories is List<Category>
//     _loading = false;
//   });
// }


//   void _focusSearchField({bool selectAll = false}) {
//     _searchFieldNode.requestFocus();
//     if (selectAll) {
//       _searchController.selection = TextSelection(
//         baseOffset: 0,
//         extentOffset: _searchController.text.length,
//       );
//     } else {
//       _searchController.selection =
//           TextSelection.collapsed(offset: _searchController.text.length);
//     }
//   }

//   // ----------------- BILLING FUNCTIONS -----------------
//   void _pauseCurrentBill() {
//     if (cartItems.isEmpty) return;
//     pausedBills.add(List<Map<String, dynamic>>.from(cartItems));
//     setState(() {
//       cartItems.clear();
//       discount = 0;
//       searchQuery = '';
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Bill paused (New Sale started)")),
//     );
//   }

//   void _showPaymentMethodDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Select Payment Method'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               title: const Text('Card'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _printBill(paymentMethod: 'Card');
//               },
//             ),
//             ListTile(
//               title: const Text('Cash'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showCashPaymentDialog();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showCashPaymentDialog() {
//     final cashController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Enter Cash Amount'),
//         content: TextField(
//           autofocus: true,
//           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//           controller: cashController,
//           decoration: const InputDecoration(hintText: 'Enter cash amount'),
//           onSubmitted: (_) => _tryCashPay(cashController, refocus: true),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => _tryCashPay(cashController),
//             child: const Text('Pay'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _tryCashPay(TextEditingController cashController, {bool refocus = false}) {
//     final cashGiven = double.tryParse(cashController.text) ?? 0;
//     final total = _calculateTotal();
//     if (cashGiven < total) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cash amount is less than total')),
//       );
//       return;
//     }
//     Navigator.pop(context);
//     final balance = cashGiven - total;
//     _printBill(paymentMethod: 'Cash', cashGiven: cashGiven, balance: balance);
//     if (refocus) _payBtnNode.requestFocus();
//   }

//   void _printBill({
//     required String paymentMethod,
//     double cashGiven = 0,
//     double balance = 0,
//   }) {
//     final now = DateTime.now();
//     final formattedDateTime = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

//     final bill = StringBuffer();
//     bill.writeln('------- AASA POS BILL -------\n');
//     bill.writeln('Date: $formattedDateTime');
//     bill.writeln('------------------------------');
//     bill.writeln('Items:');
//     bill.writeln('------------------------------');

//     for (var item in cartItems) {
//       final name = item['name'];
//       final qty = item['quantity'];
//       final price = (item['price'] as num).toDouble();
//       final itemDiscount = (item['itemDiscount'] as num?)?.toDouble() ?? 0.0;
//       final isPercentage = item['isItemDiscountPercentage'] == true;

//       double finalUnitPrice = price;
//       if (isPercentage) {
//         finalUnitPrice -= price * itemDiscount / 100;
//       } else {
//         finalUnitPrice -= itemDiscount;
//       }
//       final total = finalUnitPrice * qty;

//       bill.writeln('$name\n  Qty: $qty x Rs. ${price.toStringAsFixed(2)}');
//       if (itemDiscount > 0) {
//         bill.writeln(
//           '  Discount: ${itemDiscount.toStringAsFixed(2)} ${isPercentage ? "%" : "Rs"}',
//         );
//       }
//       bill.writeln('  Final Price: Rs. ${finalUnitPrice.toStringAsFixed(2)}');
//       bill.writeln('  Line Total: Rs. ${total.toStringAsFixed(2)}\n');
//     }

//     bill.writeln('------------------------------');
//     bill.writeln('Subtotal: Rs. ${_calculateTotal().toStringAsFixed(2)}');
//     if (discount > 0) {
//       final discountText =
//           isPercentageDiscount ? '$discount%' : 'Rs. ${discount.toStringAsFixed(2)}';
//       bill.writeln('Overall Discount: $discountText');
//     }
//     bill.writeln('Payment Method: $paymentMethod');
//     if (paymentMethod == 'Cash') {
//       bill.writeln('Cash Given: Rs. ${cashGiven.toStringAsFixed(2)}');
//       bill.writeln('Balance: Rs. ${balance.toStringAsFixed(2)}');
//     }
//     bill.writeln('\nThank you for shopping with us!');
//     bill.writeln('------------------------------');

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Bill Printed'),
//         content: SingleChildScrollView(child: Text(bill.toString())),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 cartItems.clear();
//                 discount = 0;
//                 searchQuery = '';
//               });
//               if (pausedBills.isNotEmpty) {
//                 _promptSelectPausedBill();
//               }
//               _focusSearchField();
//             },
//             child: const Text('Done'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _addToCart(Map<String, dynamic> batch, {int quantity = 1, bool fromSearch = false}) {
//     final existingIndex = cartItems.indexWhere(
//       (i) => i['name'] == batch['name'] && i['batchID'] == batch['batchID'],
//     );
//     if (existingIndex >= 0) {
//       cartItems[existingIndex]['quantity'] += quantity;
//     } else {
//       cartItems.add({
//         'name': batch['name'],
//         'price': (batch['price'] as num).toDouble() -
//             ((batch['discountAmount'] as num?)?.toDouble() ?? 0.0),
//         'batchID': batch['batchID'],
//         'quantity': quantity,
//         'itemDiscount': 0.0,
//         'isItemDiscountPercentage': false,
//       });
//     }
//     setState(() {
//       if (fromSearch) searchQuery = '';
//     });
//     _cartAreaNode.requestFocus();
//   }

//   Future<void> _openCategory(String cat) async {
//     final categoryItems =
//         (itemsByCategory.firstWhere((c) => c['category'] == cat)['items'] as List)
//             .cast<Map<String, dynamic>>();

//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CategoryItemsPage(
//           category: cat,
//           items: categoryItems,
//           onItemSelected: (_) {},
//         ),
//       ),
//     );

//     if (result != null && mounted) {
//       final item = result['item'] as Map<String, dynamic>;
//       final batch = Map<String, dynamic>.from(result['batch'] as Map<String, dynamic>);
//       final qty = result['quantity'] as int;

//       final batchForCart = {
//         'name': item['name'],
//         'price': batch['price'],
//         'batchID': batch['batchID'],
//         'discountAmount': batch['discountAmount'] ?? 0.0,
//       };
//       _addToCart(batchForCart, quantity: qty);
//     }
//   }

//   void _showBatchSelectionDialog(Map<String, dynamic> item, {bool fromSearch = false}) async {
//     final List<Map<String, dynamic>> batchList =
//         List<Map<String, dynamic>>.from(item['batches'] ?? []);
//     if (batchList.isEmpty) return;

//     if (batchList.length == 1) {
//       final selectedBatch = Map<String, dynamic>.from(batchList[0]);
//       selectedBatch['name'] = item['name'];
//       final qty = await _showQuantityInputDialog(selectedBatch);
//       if (qty != null) _addToCart(selectedBatch, quantity: qty, fromSearch: fromSearch);
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Select Batch for ${item['name']}'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: batchList.length,
//             itemBuilder: (context, index) {
//               final batch = batchList[index];
//               final dynamic discount = batch['discountAmount'] ?? 0.0;
//               return ListTile(
//                 title: Text('Batch: ${batch['batchID']} - Price: Rs. ${batch['price']}'),
//                 subtitle: (discount is num && discount > 0)
//                     ? Text('Discount: Rs. $discount')
//                     : null,
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final selectedBatch = Map<String, dynamic>.from(batch)..['name'] = item['name'];
//                   final qty = await _showQuantityInputDialog(selectedBatch);
//                   if (qty != null) {
//                     _addToCart(selectedBatch, quantity: qty, fromSearch: fromSearch);
//                   }
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Future<int?> _showQuantityInputDialog(Map<String, dynamic> batch) {
//     int quantity = 1;
//     return showDialog<int>(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         title: Text('Enter quantity for ${batch['name']} (Batch: ${batch['batchID']})'),
//         content: TextField(
//           autofocus: true,
//           keyboardType: TextInputType.number,
//           onChanged: (value) => quantity = int.tryParse(value) ?? 1,
//           onSubmitted: (value) {
//             quantity = int.tryParse(value) ?? 1;
//             Navigator.of(dialogCtx).pop(quantity);
//           },
//           decoration: const InputDecoration(hintText: 'Quantity'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(dialogCtx).pop(quantity),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _editCartItem(int index) {
//     int quantity = cartItems[index]['quantity'];
//     double itemDiscount = (cartItems[index]['itemDiscount'] as num?)?.toDouble() ?? 0.0;
//     bool isPercentage = cartItems[index]['isItemDiscountPercentage'] == true;

//     final quantityController = TextEditingController(text: quantity.toString());
//     final discountController = TextEditingController(text: itemDiscount.toString());

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Edit ${cartItems[index]['name']}'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               decoration: const InputDecoration(labelText: 'Quantity'),
//               keyboardType: TextInputType.number,
//               controller: quantityController,
//               onChanged: (value) => quantity = int.tryParse(value) ?? quantity,
//             ),
//             TextField(
//               decoration: InputDecoration(
//                 labelText: isPercentage ? 'Discount (%)' : 'Discount (Rs)',
//               ),
//               keyboardType: TextInputType.number,
//               controller: discountController,
//               onChanged: (value) => itemDiscount = double.tryParse(value) ?? itemDiscount,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text('Discount Type: '),
//                 DropdownButton<bool>(
//                   value: isPercentage,
//                   items: const [
//                     DropdownMenuItem(value: true, child: Text('%')),
//                     DropdownMenuItem(value: false, child: Text('Rs')),
//                   ],
//                   onChanged: (value) => setState(() => isPercentage = value!),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 if (quantity <= 0) {
//                   cartItems.removeAt(index);
//                 } else {
//                   cartItems[index]['quantity'] = quantity;
//                   cartItems[index]['itemDiscount'] = itemDiscount;
//                   cartItems[index]['isItemDiscountPercentage'] = isPercentage;
//                 }
//               });
//               Navigator.pop(context);
//               _cartAreaNode.requestFocus();
//             },
//             child: const Text('Update'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ⭐ Guard: avoid crash if categories not loaded yet
//   void _showAddItemDialog() {
//     if (itemsByCategory.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Categories not loaded yet. Try again after it loads.')),
//       );
//       return;
//     }

//     String barcode = '';
//     String itemName = '';
//     String selectedCategory = categories.isNotEmpty ? categories.first : '';
//     double sellingPrice = 0.0;
//     Color selectedColor = const Color.fromARGB(255, 236, 236, 236);

//     final barcodeController = TextEditingController();
//     final nameController = TextEditingController();
//     final priceController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setStateSB) => AlertDialog(
//           title: const Text('Add New Item'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: barcodeController,
//                   decoration: const InputDecoration(
//                     labelText: 'Barcode',
//                     hintText: 'Scan or enter barcode',
//                   ),
//                   onChanged: (value) => barcode = value.trim(),
//                 ),
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Item Name'),
//                   onChanged: (value) => itemName = value.trim(),
//                 ),
//                 DropdownButtonFormField<String>(
//                   value: selectedCategory.isEmpty ? null : selectedCategory,
//                   decoration: const InputDecoration(labelText: 'Category'),
//                   items: categories
//                       .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
//                       .toList(),
//                   onChanged: (value) {
//                     if (value != null) selectedCategory = value;
//                   },
//                 ),
//                 TextField(
//                   controller: priceController,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   decoration: const InputDecoration(labelText: 'Selling Price (Rs)'),
//                   onChanged: (value) => sellingPrice = double.tryParse(value) ?? 0.0,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text('Pick Item Color'),
//                 ColorPicker(
//                   pickerColor: selectedColor,
//                   onColorChanged: (color) => setStateSB(() => selectedColor = color),
//                   showLabel: false,
//                   pickerAreaHeightPercent: 0.6,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 barcode = barcodeController.text.trim();
//                 itemName = nameController.text.trim();
//                 sellingPrice = double.tryParse(priceController.text) ?? 0.0;

//                 if (barcode.isEmpty || itemName.isEmpty || sellingPrice <= 0.0) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Please fill all fields correctly.")),
//                   );
//                   return;
//                 }

//                 final newItem = {
//                   'id': DateTime.now().millisecondsSinceEpoch,
//                   'itemcode': barcode,
//                   'colourCode':
//                       '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
//                   'name': itemName,
//                   'batches': [
//                     {
//                       'batchID': barcode,
//                       'pprice': 0.0,
//                       'price': sellingPrice,
//                       'quantity': 100,
//                     },
//                   ],
//                 };

//                 setState(() {
//                   final idx =
//                       itemsByCategory.indexWhere((cat) => cat['category'] == selectedCategory);
//                   if (idx >= 0) {
//                     (itemsByCategory[idx]['items'] as List).add(newItem);
//                   } else {
//                     itemsByCategory.add({
//                       'id': DateTime.now().millisecondsSinceEpoch,
//                       'category': selectedCategory,
//                       'colourCode': '#FF9800',
//                       'items': [newItem],
//                       'categoryImage': _categoryImageFor(selectedCategory),
//                     });
//                   }
//                 });

//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Item added successfully.")),
//                 );
//                 _focusSearchField();
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _promptSelectPausedBill() {
//     if (pausedBills.isEmpty) return;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Resume a paused bill?'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: pausedBills.length,
//             itemBuilder: (context, index) {
//               final bill = pausedBills[index];
//               final itemNames = bill.map((i) => i['name']).join(', ');
//               double total = 0;
//               for (final it in bill) {
//                 final price = (it['price'] as num).toDouble();
//                 final qty = (it['quantity'] as int);
//                 final d = (it['itemDiscount'] as num?)?.toDouble() ?? 0;
//                 final isPct = it['isItemDiscountPercentage'] == true;
//                 double unit = price - (isPct ? price * d / 100 : d);
//                 total += unit * qty;
//               }
//               return ListTile(
//                 leading: CircleAvatar(child: Text('${index + 1}')),
//                 title: Text('Bill ${index + 1} • Rs. ${total.toStringAsFixed(2)}'),
//                 subtitle: Text(
//                   itemNames,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _resumeBill(index);
//                 },
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Later'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _resumeBill(int index) {
//     setState(() {
//       cartItems.clear();
//       cartItems.addAll(pausedBills[index]);
//       pausedBills.removeAt(index);
//     });
//     _cartAreaNode.requestFocus();
//   }

//   double _calculateTotal() {
//     double total = 0;
//     for (var item in cartItems) {
//       double unitPrice = (item['price'] as num).toDouble();
//       final itemDiscount = (item['itemDiscount'] as num?)?.toDouble() ?? 0;
//       if (item['isItemDiscountPercentage'] == true) {
//         unitPrice -= unitPrice * itemDiscount / 100;
//       } else {
//         unitPrice -= itemDiscount;
//       }
//       total += unitPrice * (item['quantity'] as int);
//     }
//     return isPercentageDiscount ? total - (total * discount / 100) : total - discount;
//   }

//   // ----------------- QUICK SALE (button), Ctrl+Q focuses search -----------------
//   void _handleQuickSale() async {
//     final item = await _showQuickSaleInputDialog();
//     if (item == null) return;
//     _addToCart(item, quantity: item['quantity']);
//   }

//   Future<Map<String, dynamic>?> _showQuickSaleInputDialog() async {
//     String name = 'Item';
//     int qty = 1;
//     double unitCost = 0.0;
//     double price = 0.0;

//     final nameCtrl = TextEditingController(text: 'Item');
//     final qtyCtrl = TextEditingController(text: '1');
//     final costCtrl = TextEditingController();
//     final priceCtrl = TextEditingController();

//     return showDialog<Map<String, dynamic>>(
//       context: context,
//       barrierDismissible: true,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setSB) {
//           String? errorText;

//           void validate() {
//             final q = int.tryParse(qtyCtrl.text.trim()) ?? 0;
//             final pr = double.tryParse(priceCtrl.text.trim()) ?? -1;
//             errorText =
//                 (q <= 0 || pr <= 0) ? 'Please enter positive values for quantity and price.' : null;
//             setSB(() {});
//           }

//           return AlertDialog(
//             title: const Text('Quick Sale'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
//                   TextField(
//                     controller: qtyCtrl,
//                     decoration: const InputDecoration(labelText: 'Quantity'),
//                     keyboardType: TextInputType.number,
//                     onChanged: (_) => validate(),
//                   ),
//                   TextField(
//                     controller: costCtrl,
//                     decoration: const InputDecoration(labelText: 'Unit Cost (Rs)'),
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   ),
//                   TextField(
//                     controller: priceCtrl,
//                     decoration: const InputDecoration(labelText: 'Price (Rs)'),
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     onChanged: (_) => validate(),
//                   ),
//                   if (errorText != null) ...[
//                     const SizedBox(height: 8),
//                     Text(errorText!, style: const TextStyle(color: Colors.redAccent)),
//                   ],
//                 ],
//               ),
//             ),
//             actions: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.check),
//                 label: const Text('Add'),
//                 onPressed: () {
//                   name = nameCtrl.text.trim();
//                   qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
//                   unitCost = double.tryParse(costCtrl.text.trim()) ?? 0;
//                   price = double.tryParse(priceCtrl.text.trim()) ?? -1;

//                   if (qty <= 0 || price <= 0) return;

//                   Navigator.pop(context, {
//                     'name': name,
//                     'quantity': qty,
//                     'unitCost': unitCost,
//                     'price': price,
//                     'batchID': 'QUICK-${DateTime.now().millisecondsSinceEpoch}',
//                   });
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // ----------------- Scanner helpers (added) -----------------
//   Future<void> _openScanner() async {
//     if (_scannerOpen) return;
//     _scannerOpen = true;

//     String? code;

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.black,
//       builder: (_) => SizedBox(
//         height: MediaQuery.of(context).size.height * 0.9,
//         child: Stack(
//           children: [
//             MobileScanner(
//               onDetect: (capture) {
//                 final barcodes = capture.barcodes;
//                 if (barcodes.isEmpty) return;
//                 final raw = barcodes.first.rawValue;
//                 if (raw == null || raw.trim().isEmpty) return;
//                 Navigator.of(context).pop(raw.trim());
//               },
//             ),
//             Positioned(
//               top: 16,
//               right: 16,
//               child: IconButton(
//                 color: Colors.white,
//                 icon: const Icon(Icons.close),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ).then((value) {
//       if (value is String) code = value.trim();
//     });

//     _scannerOpen = false;

//     if (!mounted) return;
//     if (code == null || code!.isEmpty) return;

//     await _handleScannedCode(code!);
//   }

//   Future<void> _handleScannedCode(String code) async {
//     Map<String, dynamic>? foundItem;
//     Map<String, dynamic>? foundBatch;

//     // 1) Prefer exact batchID match
//     outer:
//     for (final cat in itemsByCategory) {
//       final items = (cat['items'] as List).cast<Map<String, dynamic>>();
//       for (final it in items) {
//         final batches = (it['batches'] as List).cast<Map<String, dynamic>>();
//         for (final b in batches) {
//           if (b['batchID'].toString() == code) {
//             foundItem = it;
//             foundBatch = b;
//             break outer;
//           }
//         }
//       }
//     }

//     // 2) If not found, try itemcode
//     if (foundBatch == null) {
//       outer2:
//       for (final cat in itemsByCategory) {
//         final items = (cat['items'] as List).cast<Map<String, dynamic>>();
//         for (final it in items) {
//           if (it['itemcode']?.toString() == code) {
//             foundItem = it;
//             break outer2;
//           }
//         }
//       }
//     }

//     if (foundItem == null && foundBatch == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('No item found for code: $code')));
//       return;
//     }

//     // Case A: exact batch match
//     if (foundBatch != null && foundItem != null) {
//       final selected = Map<String, dynamic>.from(foundBatch)..['name'] = foundItem['name'];
//       final qty = await _showQuantityInputDialog(selected);
//       if (qty != null) _addToCart(selected, quantity: qty);
//       return;
//     }

//     // Case B: itemcode match only
//     final batches = List<Map<String, dynamic>>.from(foundItem!['batches'] ?? []);
//     if (batches.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Item has no batches to sell')));
//       return;
//     }
//     if (batches.length == 1) {
//       final selected = Map<String, dynamic>.from(batches.first)..['name'] = foundItem['name'];
//       final qty = await _showQuantityInputDialog(selected);
//       if (qty != null) _addToCart(selected, quantity: qty);
//     } else {
//       _showBatchSelectionDialog(foundItem);
//     }
//   }

//   // ----------------- UI / LAYOUT WITH KEYBOARD SHORTCUTS -----------------
//   @override
//   Widget build(BuildContext context) {
//     final shortcuts = <LogicalKeySet, Intent>{
//       // Primary actions
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): const QuickSaleIntent(),
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): const PayIntent(),
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const PauseBillIntent(),
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const ResumeBillIntent(),

//       // Navigation / utility
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const ActivateSearchIntent(),
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG): const FocusCategoriesIntent(),
//       LogicalKeySet(LogicalKeyboardKey.f2): const FocusCategoriesIntent(),

//       LogicalKeySet(LogicalKeyboardKey.f1): const ShowHelpIntent(),
//       LogicalKeySet(LogicalKeyboardKey.escape): const BackIntent(),

//       // Fallback traversal
//       LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
//       LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
//       LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
//       LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
//       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.backquote):
//           const FocusHeaderMenuIntent(),
//     };

//     final actions = <Type, Action<Intent>>{
//       QuickSaleIntent: CallbackAction<QuickSaleIntent>(onInvoke: (i) { _handleQuickSale(); return null; }),
//       PayIntent: CallbackAction<PayIntent>(onInvoke: (i) { if (cartItems.isNotEmpty) _showPaymentMethodDialog(); return null; }),
//       PauseBillIntent: CallbackAction<PauseBillIntent>(onInvoke: (i) { if (cartItems.isNotEmpty) _pauseCurrentBill(); return null; }),
//       ResumeBillIntent: CallbackAction<ResumeBillIntent>(onInvoke: (i) { _promptSelectPausedBill(); return null; }),
//       ActivateSearchIntent: CallbackAction<ActivateSearchIntent>(onInvoke: (i) { _focusSearchField(selectAll: true); return null; }),
//       FocusCategoriesIntent: CallbackAction<FocusCategoriesIntent>(onInvoke: (i) { _categoriesFocusNode.requestFocus(); return null; }),
//       ShowHelpIntent: CallbackAction<ShowHelpIntent>(onInvoke: (i) { _showHotkeysHelp(); return null; }),
//       BackIntent: CallbackAction<BackIntent>(onInvoke: (i) { if (Navigator.canPop(context)) Navigator.pop(context); return null; }),
//       NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) { FocusScope.of(context).nextFocus(); return null; }),
//       PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) { FocusScope.of(context).previousFocus(); return null; }),
//       FocusHeaderMenuIntent: CallbackAction<FocusHeaderMenuIntent>(onInvoke: (i) { _headerMenuBtnNode.requestFocus(); return null; }),
//     };

//     return Shortcuts(
//       shortcuts: shortcuts,
//       child: Actions(
//         actions: actions,
//         child: FocusTraversalGroup(
//           policy: WidgetOrderTraversalPolicy(),
//           child: Theme(
//             data: ThemeData.dark(),
//             child: Scaffold(
//               appBar: AppBar(
//                 automaticallyImplyLeading: false,
//                 backgroundColor: const Color(0xFF0D1B2A),
//                 title: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Cashier'),
//                     Row(
//                       children: [
//                         const Text('John Doe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           focusNode: _headerMenuBtnNode,
//                           icon: const Icon(Icons.menu),
//                           tooltip: 'Insights (F1 for Help)',
//                           onPressed: () {
//                             Navigator.push(context, MaterialPageRoute(builder: (_) => const CashierInsightsPage()));
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//               ),
//               body: _buildBody(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ⭐ Centralized body that handles loading/error/empty states
//   Widget _buildBody() {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
//             const SizedBox(height: 8),
//             Text('Failed to load catalog', style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 6),
//             Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: _loadCatalog,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }
//     if (itemsByCategory.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('No categories returned from API.'),
//             const SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: _loadCatalog,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Reload'),
//             ),
//           ],
//         ),
//       );
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isWideScreen = constraints.maxWidth >= 1000;
//         return isWideScreen ? _buildDesktopLayout(context) : _buildCompactLayout(context, constraints.maxWidth);
//       },
//     );
//   }

//   void _showHotkeysHelp() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Keyboard Shortcuts'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Ctrl + F  → Focus search bar'),
//             Text('Ctrl + Q  → Quick Sale'),
//             Text('Ctrl + G / F2 → Focus categories'),
//             Text('Arrow keys (in categories) → Move between cards'),
//             Text('Enter / Space (in categories) → Open category'),
//             Text('From search field: Arrow ↓ → Move into results'),
//             Text('In results: ↑/↓ to move, Enter to pick, Esc back to search'),
//             Text('Ctrl + P  → Pay'),
//             Text('Ctrl + B  → New Sale (Pause current)'),
//             Text('Ctrl + Y  → Resume paused bill'),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
//         ],
//       ),
//     );
//   }

//   // =================== UI SECTIONS (with scan button after search bar) ===================

//   Widget _buildSearchWithOverlayScanner({
//     required Widget searchAndCategories,
//     EdgeInsets overlayPadding = const EdgeInsets.only(top: 8, right: 10),
//   }) {
//     return Stack(
//       children: [
//         searchAndCategories,
//         Positioned(
//           right: overlayPadding.right,
//           top: overlayPadding.top,
//           child: Material(
//             color: Colors.transparent,
//             child: Tooltip(
//               message: 'Scan (QR/Barcode)',
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(24),
//                 onTap: _openScanner,
//                 child: const Padding(
//                   padding: EdgeInsets.all(6.0),
//                   child: CircleAvatar(
//                     radius: 18,
//                     backgroundColor: Color(0xFF1F2A44),
//                     child: Icon(Icons.qr_code_scanner, size: 20, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildResponsiveCartTable(BuildContext context) {
//     return Focus(
//       focusNode: _cartAreaNode,
//       child: CartTable(
//         cartItems: cartItems,
//         onEdit: _editCartItem,
//         onRemove: (index) => setState(() => cartItems.removeAt(index)),
//       ),
//     );
//   }

//   Widget _buildDesktopLayout(BuildContext context) {
//     final searchedItems = itemsByCategory
//         .expand((cat) => cat['items'] as List<Map<String, dynamic>>)
//         .where((item) {
//           final name = item['name'].toString().toLowerCase();
//           final idStr = item['id'].toString();
//           final code = (item['itemcode'] ?? '').toString().toLowerCase();
//           final q = searchQuery.toLowerCase().trim();
//           return name.contains(q) || idStr == q || code.contains(q);
//         })
//         .toList();

//     return Row(
//       children: [
//         Expanded(
//           flex: 4,
//           child: _buildSearchWithOverlayScanner(
//             searchAndCategories: SearchAndCategories(
//               searchQuery: searchQuery,
//               onSearchChange: (v) => setState(() => searchQuery = v),
//               itemsByCategory: itemsByCategory,
//               categories: categories,
//               searchedItems: searchedItems,
//               searchFieldFocusNode: _searchFieldNode,
//               searchController: _searchController,
//               categoriesFocusNode: _categoriesFocusNode,
//               onCategoryTap: (cat) async => await _openCategory(cat),
//               onSearchedItemTap: (item) => _showBatchSelectionDialog(item, fromSearch: true),
//             ),
//           ),
//         ),
//         Expanded(
//           flex: 6,
//           child: Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(8.0),
//                 child: Text('Bill Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//               Focus(
//                 focusNode: _discountAreaNode,
//                 child: DiscountRow(
//                   discount: discount,
//                   isPercentageDiscount: isPercentageDiscount,
//                   onDiscountChange: (v) => setState(() => discount = double.tryParse(v) ?? 0),
//                   onTypeChange: (v) => setState(() => isPercentageDiscount = v),
//                   totalAmount: _calculateTotal(),
//                 ),
//               ),
//               Expanded(child: _buildResponsiveCartTable(context)),
//               PrimaryActionsRow(
//                 onAddItem: _showAddItemDialog,
//                 onQuickSale: _handleQuickSale,
//                 onPay: cartItems.isEmpty ? null : _showPaymentMethodDialog,
//                 onNewSale: cartItems.isEmpty ? null : _pauseCurrentBill,
//                 onResumeBill: _promptSelectPausedBill,
//                 payEnabled: cartItems.isNotEmpty,
//                 hasPausedBills: pausedBills.isNotEmpty,
//               ),
//               const Padding(
//                 padding: EdgeInsets.only(bottom: 10),
//                 child: Text('Powered by AASA IT', style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic)),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCompactLayout(BuildContext context, double width) {
//     final crossAxisCount = width >= 800 ? 4 : width >= 700 ? 4 : width >= 600 ? 2 : 2;

//     final bool isVerySmall = width < 380;
//     final bool isSmall = width < 480;

//     final searchedItems = itemsByCategory
//         .expand((cat) => cat['items'] as List<Map<String, dynamic>>)
//         .where((item) {
//           final name = item['name'].toString().toLowerCase();
//           final idStr = item['id'].toString();
//           final code = (item['itemcode'] ?? '').toString().toLowerCase();
//           final q = searchQuery.toLowerCase().trim();
//           return name.contains(q) || idStr == q || code.contains(q);
//         })
//         .toList();

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           SizedBox(
//             height: 300,
//             child: _buildSearchWithOverlayScanner(
//               overlayPadding: const EdgeInsets.only(top: 6, right: 12),
//               searchAndCategories: SearchAndCategories(
//                 searchQuery: searchQuery,
//                 onSearchChange: (v) => setState(() => searchQuery = v),
//                 itemsByCategory: itemsByCategory,
//                 categories: categories,
//                 searchedItems: searchedItems,
//                 gridHeight: 300,
//                 gridCrossAxisCount: crossAxisCount,
//                 searchFieldFocusNode: _searchFieldNode,
//                 searchController: _searchController,
//                 categoriesFocusNode: _categoriesFocusNode,
//                 onCategoryTap: (cat) async => await _openCategory(cat),
//                 onSearchedItemTap: (item) => _showBatchSelectionDialog(item, fromSearch: true),
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text('Bill Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           ),
//           Focus(
//             focusNode: _discountAreaNode,
//             child: DiscountRow(
//               discount: discount,
//               isPercentageDiscount: isPercentageDiscount,
//               onDiscountChange: (v) => setState(() => discount = double.tryParse(v) ?? 0),
//               onTypeChange: (v) => setState(() => isPercentageDiscount = v),
//               totalAmount: _calculateTotal(),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: _buildResponsiveCartTable(context),
//           ),
//           PrimaryActionsRow(
//             onAddItem: _showAddItemDialog,
//             onQuickSale: _handleQuickSale,
//             onPay: cartItems.isEmpty ? null : _showPaymentMethodDialog,
//             onNewSale: cartItems.isEmpty ? null : _pauseCurrentBill,
//             onResumeBill: _promptSelectPausedBill,
//             payEnabled: cartItems.isNotEmpty,
//             hasPausedBills: pausedBills.isNotEmpty,
//           ),
//           const Padding(
//             padding: EdgeInsets.only(bottom: 10),
//             child: Center(
//               child: Text('Powered by AASA IT', style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
