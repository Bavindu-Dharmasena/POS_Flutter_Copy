import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/data/repositories/stockkeeper/restock/item_lookup_repository.dart';
import 'package:pos_system/data/models/stockkeeper/restock/item_scan_model.dart';
import 'package:pos_system/data/repositories/stockkeeper/restock/stock_repository.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double price;
  final String barcode;
  final String? image;
  final String supplier;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.barcode,
    this.image,
    required this.supplier,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? currentStock,
    int? minStock,
    int? maxStock,
    double? price,
    String? barcode,
    String? image,
    String? supplier,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      image: image ?? this.image,
      supplier: supplier ?? this.supplier,
    );
  }
}

class RestockEntry {
  final Product product;
  String batchId;
  double unitPrice;
  double salePrice;
  double permanentDiscount;
  int quantity;

  RestockEntry({
    required this.product,
    required this.batchId,
    required this.unitPrice,
    required this.salePrice,
    required this.permanentDiscount,
    required this.quantity,
  });

  num get lineTotal => math.max(0, (salePrice - permanentDiscount)) * quantity;
  int get newStock => product.currentStock + quantity;
}

class RestockPage extends StatefulWidget {
  const RestockPage({super.key});
  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> with WidgetsBindingObserver {
  late List<Product> _all;

  final TextEditingController _barcodeCtl = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();
  final GlobalKey _barcodeFieldKey = GlobalKey();

  final ScrollController _scrollCtl = ScrollController();

  Product? _selectedProduct;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _batchIdCtl = TextEditingController();
  final TextEditingController _unitPriceCtl = TextEditingController();
  final TextEditingController _salePriceCtl = TextEditingController();
  final TextEditingController _discountCtl = TextEditingController(text: '0');
  final TextEditingController _qtyCtl = TextEditingController(text: '1');

  final List<RestockEntry> _entries = [];
  final FocusNode _focus = FocusNode();

  final ItemLookupRepository _repo = ItemLookupRepository();
  final StockRepository _stockRepo = StockRepository();

  final Color _primaryColor = const Color(0xFF0A74DA);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _all = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();

      _barcodeFocus.addListener(() {
        if (_barcodeFocus.hasFocus) _ensureBarcodeVisible();
      });

      _barcodeCtl.addListener(() {
        final t = _barcodeCtl.text;
        if (t.contains('\n')) {
          final clean = t.replaceAll('\n', '');
          _barcodeCtl.text = clean;
          _barcodeCtl.selection = TextSelection.collapsed(offset: clean.length);
          _onBarcodeSubmit(clean);
        }
      });
    });
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBarcodeVisible());
  }

  void _ensureBarcodeVisible() {
    if (!_barcodeFocus.hasFocus) return;
    final ctx = _barcodeFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    _barcodeFocus.dispose();
    _barcodeCtl.dispose();
    _batchIdCtl.dispose();
    _unitPriceCtl.dispose();
    _salePriceCtl.dispose();
    _discountCtl.dispose();
    _qtyCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  String _defaultBatchIdFor(Product p) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'RESTOCK-${p.id}-$ts';
  }

  void _pickProduct(Product p) {
    setState(() {
      _selectedProduct = p;
      _batchIdCtl.text = _defaultBatchIdFor(p);
      _unitPriceCtl.text = p.price.toStringAsFixed(2);
      _salePriceCtl.text = p.price.toStringAsFixed(2);
      _discountCtl.text = '0';
      _qtyCtl.text = '1';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedProduct = null;
      _batchIdCtl.clear();
      _unitPriceCtl.clear();
      _salePriceCtl.clear();
      _discountCtl.text = '0';
      _qtyCtl.text = '1';
    });
    _barcodeFocus.requestFocus();
    _ensureBarcodeVisible();
  }

  void _submitForm() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a product first.')),
      );
      _ensureBarcodeVisible();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final batchId = _batchIdCtl.text.trim();
    final unitPrice = double.tryParse(_unitPriceCtl.text.trim()) ?? 0;
    final salePrice = double.tryParse(_salePriceCtl.text.trim()) ?? 0;
    final discount = double.tryParse(_discountCtl.text.trim()) ?? 0;
    final qty = int.tryParse(_qtyCtl.text.trim()) ?? 0;

    if (batchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch ID is required')),
      );
      return;
    }
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be at least 1')),
      );
      return;
    }

    final entry = RestockEntry(
      product: _selectedProduct!,
      batchId: batchId,
      unitPrice: unitPrice,
      salePrice: salePrice,
      permanentDiscount: discount,
      quantity: qty,
    );

    setState(() {
      final idx = _entries.indexWhere(
        (e) => e.product.id == entry.product.id && e.batchId == entry.batchId,
      );
      if (idx >= 0) {
        _entries[idx] = entry;
      } else {
        _entries.add(entry);
      }
    });

    _clearForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to update list')),
    );
  }

  void _removeEntry(RestockEntry e) {
    setState(() => _entries.removeWhere(
        (x) => x.product.id == e.product.id && x.batchId == e.batchId));
  }

  Future<void> _applyUpdates() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to update.')),
      );
      return;
    }

    final total = _entries.fold<double>(0, (s, e) => s + e.lineTotal);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Stock Updates'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._entries.map(
                (e) => ListTile(
                  dense: true,
                  title: Text(e.product.name),
                  subtitle: Text(
                    'Batch: ${e.batchId}\n'
                    'Current: ${e.product.currentStock}  •  +${e.quantity}  →  New: ${e.newStock}\n'
                    'Unit Rs.${e.unitPrice.toStringAsFixed(2)} • Sale Rs.${e.salePrice.toStringAsFixed(2)} • Disc Rs.${e.permanentDiscount.toStringAsFixed(2)}',
                  ),
                  trailing: Text('Rs.${e.lineTotal.toStringAsFixed(2)}'),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Estimated Cost Impact: Rs.${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // close confirm

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Dialog(
                  insetPadding: EdgeInsets.symmetric(horizontal: 80),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Applying updates...'),
                      ],
                    ),
                  ),
                ),
              );

              try {
                final inputs = _entries.map((e) {
                  return StockUpdateInput(
                    itemId: int.parse(e.product.id),
                    batchId: e.batchId,
                    quantityToAdd: e.quantity,
                    unitPrice: e.unitPrice,
                    sellPrice: e.salePrice,
                    discountAmount: e.permanentDiscount,
                  );
                }).toList();

                await _stockRepo.applyRestockEntries(inputs);

                if (mounted) Navigator.of(context).pop(); // close progress

                // Fast UI reflection:
                _applyEntriesToLocalProducts();

                // Optional: refresh from DB to ensure UI matches real data
                final ids = _entries.map((e) => e.product.id).toSet().toList();
                for (final id in ids) {
                  final item = await _repo.findByBarcodeOrId(id); // id works too
                  if (item != null) {
                    final i = _all.indexWhere((p) => p.id == '$id');
                    final p = Product(
                      id: item.id.toString(),
                      name: item.name,
                      category: item.category,
                      currentStock: item.currentStock,
                      minStock: item.reorderLevel,
                      maxStock: item.reorderLevel * 5,
                      price: item.price,
                      barcode: item.barcode,
                      image: null,
                      supplier: item.supplier,
                    );
                    if (i == -1) {
                      _all.add(p);
                    } else {
                      _all[i] = p;
                    }
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Applied ${_entries.length} stock update(s).')),
                  );
                  setState(() => _entries.clear());
                }
              } catch (e, st) {
                debugPrint('Restock apply error: $e\n$st');
                if (mounted) Navigator.of(context).pop(); // close progress
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update stock.')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Apply Updates'),
          ),
        ],
      ),
    );
  }

  void _applyEntriesToLocalProducts() {
    setState(() {
      final updated = <Product>[];
      for (final p in _all) {
        final totalAdded = _entries
            .where((e) => e.product.id == p.id)
            .fold<int>(0, (s, e) => s + e.quantity);
        final lastPrice = _entries.lastWhere(
          (e) => e.product.id == p.id,
          orElse: () => RestockEntry(
            product: p,
            batchId: '',
            unitPrice: 0,
            salePrice: p.price,
            permanentDiscount: 0,
            quantity: 0,
          ),
        ).salePrice;

        if (totalAdded > 0) {
          updated.add(p.copyWith(
            currentStock: p.currentStock + totalAdded,
            price: lastPrice,
          ));
        } else {
          updated.add(p);
        }
      }
      _all = updated;
    });
  }

  Future<void> _onBarcodeSubmit(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    try {
      final ItemScanModel? item = await _repo.findByBarcodeOrId(trimmed);
      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No item matched this code')),
        );
        _barcodeCtl.clear();
        _ensureBarcodeVisible();
        return;
      }

      final product = Product(
        id: item.id.toString(),
        name: item.name,
        category: item.category,
        currentStock: item.currentStock,
        minStock: item.reorderLevel,
        maxStock: item.reorderLevel * 5,
        price: item.price,
        barcode: item.barcode,
        image: null,
        supplier: item.supplier,
      );

      final idx = _all.indexWhere((p) => p.id == product.id);
      if (idx == -1) {
        _all.add(product);
      } else {
        _all[idx] = product;
      }

      _pickProduct(product);
      _barcodeCtl.clear();
      _ensureBarcodeVisible();
    } catch (e, st) {
      debugPrint('SQLite lookup error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lookup error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: { LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(), },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focus,
          child: Scaffold(
            backgroundColor: cs.surface,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              centerTitle: true,
              title: const Text('Update Stock', style: TextStyle(fontWeight: FontWeight.w800)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back (Esc)',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(foregroundColor: _primaryColor),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollCtl,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              color: cs.surfaceContainerHighest.withOpacity(.25),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(FontAwesome.barcode, size: 48, color: _primaryColor),
                                    const SizedBox(height: 16),
                                    Text('Scan or Enter Product Code',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                                    const SizedBox(height: 8),
                                    Text('Use barcode scanner or manually type product ID/barcode',
                                        style: TextStyle(color: cs.onSurface.withOpacity(.7)), textAlign: TextAlign.center),
                                    const SizedBox(height: 20),
                                    KeyedSubtree(
                                      key: _barcodeFieldKey,
                                      child: TextField(
                                        controller: _barcodeCtl,
                                        focusNode: _barcodeFocus,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (v) async => _onBarcodeSubmit(v),
                                        scrollPadding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Scan barcode or enter product ID',
                                          prefixIcon: const Icon(FontAwesome.barcode),
                                          filled: true,
                                          fillColor: cs.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _FormCard(
                              product: _selectedProduct,
                              formKey: _formKey,
                              batchCtrl: _batchIdCtl,
                              unitCtrl: _unitPriceCtl,
                              saleCtrl: _salePriceCtl,
                              discCtrl: _discountCtl,
                              qtyCtrl: _qtyCtl,
                              onCancel: _clearForm,
                              onSubmit: _submitForm,
                              primaryColor: _primaryColor,
                              warningColor: _warningColor,
                              successColor: _successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomEntriesBar(
                    entries: _entries,
                    onRemove: _removeEntry,
                    onApply: _applyUpdates,
                    primaryColor: _primaryColor,
                    successColor: _successColor,
                    errorColor: _errorColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.product,
    required this.formKey,
    required this.batchCtrl,
    required this.unitCtrl,
    required this.saleCtrl,
    required this.discCtrl,
    required this.qtyCtrl,
    required this.onCancel,
    required this.onSubmit,
    required this.primaryColor,
    required this.warningColor,
    required this.successColor,
  });

  final Product? product;
  final GlobalKey<FormState> formKey;
  final TextEditingController batchCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController saleCtrl;
  final TextEditingController discCtrl;
  final TextEditingController qtyCtrl;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final Color primaryColor;
  final Color warningColor;
  final Color successColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surfaceContainerHighest.withOpacity(.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Feather.edit, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                const Text('Stock Update Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            if (product == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Feather.package, size: 64, color: cs.onSurface.withOpacity(.3)),
                      const SizedBox(height: 16),
                      Text('No Product Selected',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.7))),
                      const SizedBox(height: 8),
                      Text('Scan a barcode or enter a product ID above to begin',
                          style: TextStyle(color: cs.onSurface.withOpacity(.5)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductHeader(product: product!),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _textField('Batch ID (Required)', batchCtrl, validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Batch ID is required';
                          return null;
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _numField('Unit Price (Optional)', unitCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _numField('Sale Price (Optional)', saleCtrl)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _numField('Discount (Optional)', discCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _intField('Quantity to Add', qtyCtrl)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(Feather.x),
                                label: const Text('Clear & Scan Next'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: warningColor,
                                  side: BorderSide(color: warningColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onSubmit,
                                icon: const Icon(Feather.plus),
                                label: const Text('Add to Updates'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController c, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: _fieldDecoration(label),
      validator: validator,
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      decoration: _fieldDecoration(label),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        final val = double.tryParse(t);
        if (val == null) return 'Enter a number';
        if (val < 0) return 'Must be ≥ 0';
        return null;
      },
    );
  }

  Widget _intField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _fieldDecoration(label),
      validator: (v) {
        final val = int.tryParse((v ?? '').trim());
        if (val == null) return 'Enter a number';
        if (val <= 0) return 'Must be ≥ 1';
        return null;
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: cs.primary, child: Icon(Feather.package, color: cs.onPrimary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${product.category} • ID: ${product.id}', style: TextStyle(color: cs.onSurface.withOpacity(.7), fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20)),
                child: Text('Current Stock: ${product.currentStock}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Rs.${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('Current Price', style: TextStyle(color: cs.onSurface.withOpacity(.6), fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}

class _BottomEntriesBar extends StatelessWidget {
  const _BottomEntriesBar({
    required this.entries,
    required this.onRemove,
    required this.onApply,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
  });

  final List<RestockEntry> entries;
  final void Function(RestockEntry) onRemove;
  final VoidCallback onApply;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = entries.fold<double>(0, (s, e) => s + e.lineTotal);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outline.withOpacity(.2)))),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: 16 - MediaQuery.of(context).viewInsets.bottom.clamp(0.0, 16.0),
      ),
      child: entries.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Feather.list, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text('Items to Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${entries.length} item${entries.length == 1 ? '' : 's'}', style: TextStyle(color: cs.onSurface.withOpacity(.7))),
                ]),
                const SizedBox(height: 12),
                if (entries.length == 1)
                  _EntryCard(entry: entries.first, onRemove: () => onRemove(entries.first), errorColor: errorColor)
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return _EntryCard(entry: e, onRemove: () => onRemove(e), isCompact: true, errorColor: errorColor);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text('Total Impact: Rs.${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                  FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Feather.check),
                    label: const Text('Apply Updates'),
                    style: FilledButton.styleFrom(
                      backgroundColor: successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ]),
              ],
            )
          : Text('No items added yet. Scan products and add quantities to update stock.',
              style: TextStyle(color: cs.onSurface.withOpacity(.7)), textAlign: TextAlign.center),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onRemove,
    this.isCompact = false,
    required this.errorColor,
  });

  final RestockEntry entry;
  final VoidCallback onRemove;
  final bool isCompact;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(minWidth: isCompact ? 200 : double.infinity, maxWidth: isCompact ? 280 : double.infinity),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(entry.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text('Batch: ${entry.batchId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(.6))),
              const SizedBox(height: 4),
              Text('Current: ${entry.product.currentStock} → New: ${entry.newStock} (+${entry.quantity})',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(.7))),
              if (!isCompact) ...[
                const SizedBox(height: 4),
                Text('Rs.${entry.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ]),
          ),
          if (isCompact) ...[
            const SizedBox(width: 8),
            Text('Rs.${entry.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: Icon(Feather.trash_2, size: 16, color: errorColor),
            style: IconButton.styleFrom(foregroundColor: errorColor, backgroundColor: errorColor.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class ActivateIntent extends Intent {
  const ActivateIntent();
}
