import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/data/repositories/stockkeeper/item_lookup_repository.dart';
import 'package:pos_system/data/models/stockkeeper/item_scan_model.dart';

// ===== Product model used by the page =====
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

// ===== Update entry DTO =====
class RestockEntry {
  final Product product;
  double unitPrice;
  double salePrice;
  double permanentDiscount;
  int quantity;

  RestockEntry({
    required this.product,
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

class _RestockPageState extends State<RestockPage> {
  // Local list holds items you scanned this session (for preview/update math)
  late List<Product> _all;

  // ---- barcode scan state ----
  final TextEditingController _barcodeCtl = TextEditingController();

  // ---- current form selection ----
  Product? _selectedProduct;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitPriceCtl = TextEditingController();
  final TextEditingController _salePriceCtl = TextEditingController();
  final TextEditingController _discountCtl = TextEditingController(text: '0');
  final TextEditingController _qtyCtl = TextEditingController(text: '1');

  // ---- added entries list ----
  final List<RestockEntry> _entries = [];

  // ESC focus
  final FocusNode _focus = FocusNode();
  final FocusNode _barcodeFocus = FocusNode();

  // SQLite repo
  final ItemLookupRepository _repo = ItemLookupRepository();

  // Colors
  final Color _primaryColor = const Color(0xFF0A74DA);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _all = []; // start empty: only real DB items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
      // scanners often send newline
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
  void dispose() {
    _focus.dispose();
    _barcodeFocus.dispose();
    _barcodeCtl.dispose();
    _unitPriceCtl.dispose();
    _salePriceCtl.dispose();
    _discountCtl.dispose();
    _qtyCtl.dispose();
    super.dispose();
  }

  void _pickProduct(Product p) {
    setState(() {
      _selectedProduct = p;
      _unitPriceCtl.text = p.price.toStringAsFixed(2);
      _salePriceCtl.text = p.price.toStringAsFixed(2);
      _discountCtl.text = '0';
      _qtyCtl.text = '1';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedProduct = null;
      _unitPriceCtl.clear();
      _salePriceCtl.clear();
      _discountCtl.text = '0';
      _qtyCtl.text = '1';
    });
    _barcodeFocus.requestFocus();
  }

  void _submitForm() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a product first.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final unitPrice = double.tryParse(_unitPriceCtl.text.trim()) ?? 0;
    final salePrice = double.tryParse(_salePriceCtl.text.trim()) ?? 0;
    final discount = double.tryParse(_discountCtl.text.trim()) ?? 0;
    final qty = int.tryParse(_qtyCtl.text.trim()) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be at least 1')),
      );
      return;
    }

    final entry = RestockEntry(
      product: _selectedProduct!,
      unitPrice: unitPrice,
      salePrice: salePrice,
      permanentDiscount: discount,
      quantity: qty,
    );

    setState(() {
      final idx = _entries.indexWhere((e) => e.product.id == entry.product.id);
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
    setState(() => _entries.removeWhere((x) => x.product.id == e.product.id));
  }

  void _applyUpdates() async {
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
            onPressed: () {
              Navigator.pop(context);
              _applyEntriesToLocalProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Applied ${_entries.length} stock update(s).')),
              );
              setState(() => _entries.clear());
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
        final entry = _entries.firstWhere(
          (e) => e.product.id == p.id,
          orElse: () => RestockEntry(
            product: p,
            unitPrice: 0,
            salePrice: 0,
            permanentDiscount: 0,
            quantity: 0,
          ),
        );
        if (entry.quantity > 0) {
          updated.add(p.copyWith(currentStock: p.currentStock + entry.quantity));
        } else {
          updated.add(p);
        }
      }
      _all = updated;
    });
  }

  // ==== BARCODE SUBMIT → pure SQLite lookup ====
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
        return;
      }

      final product = Product(
        id: item.id.toString(),
        name: item.name,
        category: item.category,
        currentStock: item.currentStock,
        minStock: item.reorderLevel,
        maxStock: item.reorderLevel * 5, // simple heuristic
        price: item.price,
        barcode: item.barcode,
        image: null,
        supplier: item.supplier,
      );

      final idx = _all.indexWhere((p) => p.id == product.id);
      if (idx == -1) {
        _all.add(product);
      } else {
        _all[idx] = product; // refresh with latest data
      }

      _pickProduct(product);
      _barcodeCtl.clear();
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
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
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
                  // BARCODE SECTION
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: cs.surfaceContainerHighest.withOpacity(.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                            TextField(
                              controller: _barcodeCtl,
                              focusNode: _barcodeFocus,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (v) async => _onBarcodeSubmit(v),
                              decoration: InputDecoration(
                                hintText: 'Scan barcode or enter product ID',
                                prefixIcon: const Icon(FontAwesome.barcode),
                                filled: true,
                                fillColor: cs.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // FORM SECTION
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _FormCard(
                        product: _selectedProduct,
                        formKey: _formKey,
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
                  ),

                  // BOTTOM ENTRIES BAR
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

// ========== FORM WIDGET ==========
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.product,
    required this.formKey,
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
                const Text('Stock Update Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            if (product == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Feather.package, size: 64, color: cs.onSurface.withOpacity(.3)),
                      const SizedBox(height: 16),
                      Text('No Product Selected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(.7),
                          )),
                      const SizedBox(height: 8),
                      Text('Scan a barcode or enter a product ID above to begin',
                          style: TextStyle(color: cs.onSurface.withOpacity(.5)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProductHeader(product: product!),
                      const SizedBox(height: 20),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
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
                ),
              ),
          ],
        ),
      ),
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
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Icon(Feather.package, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${product.category} • ID: ${product.id}',
                    style: TextStyle(color: cs.onSurface.withOpacity(.7), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20)),
                  child: Text('Current Stock: ${product.currentStock}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs.${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Current Price',
                  style: TextStyle(color: cs.onSurface.withOpacity(.6), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Bottom entries bar =====
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
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline.withOpacity(.2))),
      ),
      padding: const EdgeInsets.all(16),
      child: entries.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Feather.list, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    const Text('Items to Update',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${entries.length} item${entries.length == 1 ? '' : 's'}',
                        style: TextStyle(color: cs.onSurface.withOpacity(.7))),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.length == 1)
                  _EntryCard(
                    entry: entries.first,
                    onRemove: () => onRemove(entries.first),
                    errorColor: errorColor,
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return _EntryCard(
                          entry: e,
                          onRemove: () => onRemove(e),
                          isCompact: true,
                          errorColor: errorColor,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total Impact: Rs.${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
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
                  ],
                ),
              ],
            )
          : Text(
              'No items added yet. Scan products and add quantities to update stock.',
              style: TextStyle(color: cs.onSurface.withOpacity(.7)),
              textAlign: TextAlign.center,
            ),
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
      constraints: BoxConstraints(
        minWidth: isCompact ? 200 : double.infinity,
        maxWidth: isCompact ? 280 : double.infinity,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Current: ${entry.product.currentStock} → New: ${entry.newStock} (+${entry.quantity})',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(.7)),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  Text('Rs.${entry.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (isCompact) ...[
            const SizedBox(width: 8),
            Text('Rs.${entry.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: Icon(Feather.trash_2, size: 16, color: errorColor),
            style: IconButton.styleFrom(
              foregroundColor: errorColor,
              backgroundColor: errorColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Simple "Esc" action intent ----
class ActivateIntent extends Intent {
  const ActivateIntent();
}
