import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ===== Product model =====
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

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
  bool get isOutOfStock => currentStock == 0;
}

// ===== Restock entry DTO (per selected line) =====
class RestockEntry {
  final Product product;
  double unitPrice;
  double salePrice;
  double permanentDiscount; // per-unit absolute
  int quantity;

  RestockEntry({
    required this.product,
    required this.unitPrice,
    required this.salePrice,
    required this.permanentDiscount,
    required this.quantity,
  });

  num get lineTotal => math.max(0, (salePrice - permanentDiscount)) * quantity;
}

class RestockPage extends StatefulWidget {
  const RestockPage({super.key, this.products});
  final List<Product>? products;

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  // --- demo data (replace with live data) ---
  List<Product> get _demo => const [
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 6,
      minStock: 20,
      maxStock: 100,
      price: 250.00,
      barcode: '123456789',
      supplier: 'Cadbury Lanka',
    ),
    Product(
      id: '002',
      name: 'Maliban Cream Crackers',
      category: 'Biscuits',
      currentStock: 10,
      minStock: 15,
      maxStock: 80,
      price: 180.00,
      barcode: '987654321',
      supplier: 'Maliban Biscuits',
    ),
    Product(
      id: '003',
      name: 'Coca Cola 330ml',
      category: 'Beverages',
      currentStock: 0,
      minStock: 25,
      maxStock: 120,
      price: 150.00,
      barcode: '456789123',
      supplier: 'Coca Cola Lanka',
    ),
    Product(
      id: '004',
      name: 'Anchor Milk Powder 400g',
      category: 'Dairy',
      currentStock: 8,
      minStock: 10,
      maxStock: 50,
      price: 850.00,
      barcode: '789123456',
      supplier: 'Fonterra Lanka',
    ),
  ];

  late final List<Product> _all;

  // ---- search + scan state ----
  final TextEditingController _searchCtl = TextEditingController();
  final TextEditingController _barcodeCtl = TextEditingController();
  String _query = '';
  List<Product> get _matches {
    if (_query.trim().isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((p) {
      return p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q);
    }).toList();
  }

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

  @override
  void initState() {
    super.initState();
    _all = [...(widget.products ?? _demo)];
  }

  @override
  void dispose() {
    _focus.dispose();
    _searchCtl.dispose();
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
  }

  void _submitForm() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item first.')),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item added to restock list')));
  }

  void _removeEntry(RestockEntry e) {
    setState(() => _entries.removeWhere((x) => x.product.id == e.product.id));
  }

  void _sendAll() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to send.')),
      );
      return;
    }

    // TODO: POST _entries to your backend.
    final total = _entries.fold<double>(0, (s, e) => s + e.lineTotal);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Restock Request'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._entries.map(
                (e) => ListTile(
                  dense: true,
                  title: Text(e.product.name),
                  subtitle: Text(
                    'Unit Rs.${e.unitPrice.toStringAsFixed(2)}  •  Sale Rs.${e.salePrice.toStringAsFixed(2)}  •  Disc Rs.${e.permanentDiscount.toStringAsFixed(2)}  •  Qty ${e.quantity}',
                  ),
                  trailing: Text('Rs.${e.lineTotal.toStringAsFixed(2)}'),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Estimated Total: Rs.${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sent ${_entries.length} item(s). Total Rs.${total.toStringAsFixed(2)}',
                  ),
                ),
              );
              setState(() => _entries.clear());
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // Barcode enter -> pick item
  void _onBarcodeSubmit(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    final p = _all.firstWhere(
      (e) =>
          e.barcode == trimmed || e.id.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => const Product(
        id: '',
        name: '',
        category: '',
        currentStock: 0,
        minStock: 0,
        maxStock: 0,
        price: 0,
        barcode: '',
        supplier: '',
      ),
    );

    if (p.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item matched this code')),
      );
    } else {
      _pickProduct(p);
    }
    _barcodeCtl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focus,
          child: Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Re‑Stock',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back (Esc)',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Column(
              children: [
                // ===== TOP SEARCH + BARCODE =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      // Search by ID / Name
                      Expanded(
                        child: TextField(
                          controller: _searchCtl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search item by ID or Name',
                            prefixIcon: const Icon(Feather.search),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(.35),
                            border: _fieldBorder(),
                            enabledBorder: _fieldBorder(),
                            focusedBorder: _focusedBorder(cs),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Barcode box - Made more responsive
                      SizedBox(
                        width: isDesktop ? 260 : 160,
                        child: TextField(
                          controller: _barcodeCtl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _onBarcodeSubmit,
                          decoration: InputDecoration(
                            hintText: isDesktop
                                ? 'Scan / Enter barcode or ID'
                                : 'Scan barcode',
                            prefixIcon: const Icon(FontAwesome.barcode),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(.35),
                            border: _fieldBorder(),
                            enabledBorder: _fieldBorder(),
                            focusedBorder: _focusedBorder(cs),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== RESULTS + (desktop) FORM =====
                Expanded(
                  child: Row(
                    children: [
                      // left: results
                      Expanded(
                        flex: isDesktop ? 6 : 10,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: _ResultList(
                            items: _matches,
                            onPick: _pickProduct,
                            selectedId: _selectedProduct?.id,
                          ),
                        ),
                      ),
                      // right: form (desktop only here)
                      if (isDesktop)
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                            child: _FormCard(
                              product: _selectedProduct,
                              formKey: _formKey,
                              unitCtrl: _unitPriceCtl,
                              saleCtrl: _salePriceCtl,
                              discCtrl: _discountCtl,
                              qtyCtrl: _qtyCtl,
                              onCancel: _clearForm,
                              onSubmit: _submitForm,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // mobile: form below results
                if (!isDesktop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: _FormCard(
                      product: _selectedProduct,
                      formKey: _formKey,
                      unitCtrl: _unitPriceCtl,
                      saleCtrl: _salePriceCtl,
                      discCtrl: _discountCtl,
                      qtyCtrl: _qtyCtl,
                      onCancel: _clearForm,
                      onSubmit: _submitForm,
                    ),
                  ),

                // ===== ADDED ENTRIES + SEND (FIXED OVERFLOW) =====
                _BottomEntriesBar(
                  entries: _entries,
                  onRemove: _removeEntry,
                  onSend: _sendAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
  );

  OutlineInputBorder _focusedBorder(ColorScheme cs) => _fieldBorder().copyWith(
    borderSide: BorderSide(color: cs.primary.withOpacity(.6)),
  );
}

// ========== WIDGETS ==========

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.items,
    required this.onPick,
    required this.selectedId,
  });

  final List<Product> items;
  final void Function(Product) onPick;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No matching items',
          style: TextStyle(color: cs.onSurface.withOpacity(.7)),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final p = items[i];
          final picked = p.id == (selectedId ?? '');
          final badgeText = p.isOutOfStock
              ? 'OUT OF STOCK'
              : (p.isLowStock ? 'LOW STOCK' : 'OK');
          final badgeColor = p.isOutOfStock
              ? Colors.red.withOpacity(.12)
              : (p.isLowStock
                    ? const Color(0xFFFFF3CD)
                    : cs.surfaceVariant.withOpacity(.35));
          final badgeTextColor = p.isOutOfStock
              ? Colors.red.shade700
              : (p.isLowStock ? const Color(0xFF8A6D3B) : cs.onSurface);

          return Material(
            color: picked
                ? cs.surfaceVariant.withOpacity(.4)
                : cs.surfaceVariant.withOpacity(.25),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onPick(p),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.surfaceVariant,
                      child: const Icon(Feather.box),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.category} • ${p.id}',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$badgeText • Stock ${p.currentStock} / Min ${p.minStock}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rs.${p.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
  });

  final Product? product;
  final GlobalKey<FormState> formKey;
  final TextEditingController unitCtrl;
  final TextEditingController saleCtrl;
  final TextEditingController discCtrl;
  final TextEditingController qtyCtrl;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surfaceVariant.withOpacity(.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(icon: Feather.sliders, text: 'Add to Restock'),
            const SizedBox(height: 8),
            if (product == null)
              Text(
                'Select an item from the list or scan a barcode to start.',
                style: TextStyle(color: cs.onSurface.withOpacity(.7)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductHeader(product: product!),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _numField('Unit Price', unitCtrl)),
                            const SizedBox(width: 10),
                            Expanded(child: _numField('Sale Price', saleCtrl)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _numField('Permanent Discount', discCtrl),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _intField('Quantity', qtyCtrl)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: onCancel,
                              icon: const Icon(Feather.x),
                              label: const Text('Cancel'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: onSubmit,
                              icon: const Icon(Feather.plus_square),
                              label: const Text('Submit'),
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

  Widget _numField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _fieldDecoration(label),
      validator: (v) {
        final val = double.tryParse((v ?? '').trim());
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
        if (val == null) return 'Enter an integer';
        if (val <= 0) return 'Must be ≥ 1';
        return null;
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = product.isOutOfStock
        ? 'OUT OF STOCK'
        : (product.isLowStock ? 'LOW STOCK' : 'OK');
    final statusColor = product.isOutOfStock
        ? Colors.red.withOpacity(.12)
        : (product.isLowStock
              ? const Color(0xFFFFF3CD)
              : cs.surfaceVariant.withOpacity(.35));
    final statusTextColor = product.isOutOfStock
        ? Colors.red.shade700
        : (product.isLowStock ? const Color(0xFF8A6D3B) : cs.onSurface);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.surfaceVariant,
          child: const Icon(Feather.box),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${product.category} • ${product.id}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$status • Stock ${product.currentStock} / Min ${product.minStock}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Rs.${product.price.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

// ===== Bottom bar (FIXED OVERFLOW ISSUES) =====
class _BottomEntriesBar extends StatelessWidget {
  const _BottomEntriesBar({
    required this.entries,
    required this.onRemove,
    required this.onSend,
  });

  final List<RestockEntry> entries;
  final void Function(RestockEntry) onRemove;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = entries.fold<double>(0, (s, e) => s + e.lineTotal);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          // Limit the maximum height to prevent overflow
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(.08))),
        ),
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          // Add extra bottom padding for safe area
          12 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entries.isNotEmpty) ...[
              const _SectionTitle(
                icon: Feather.shopping_cart,
                text: 'Items to Send',
              ),
              const SizedBox(height: 8),
              // Fixed height container with proper overflow handling
              Container(
                height: isSmallScreen ? 120 : 140,
                child: entries.length == 1
                    ? _EntryCard(
                        entry: entries.first,
                        onRemove: () => onRemove(entries.first),
                        isCompact: true,
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          return _EntryCard(
                            entry: e,
                            onRemove: () => onRemove(e),
                            isCompact: true,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              // Total and send button with responsive layout
              Flexible(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: Rs.${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onSend,
                      icon: const Icon(Feather.send),
                      label: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ] else
              Flexible(
                child: Text(
                  'No items added yet — select an item, fill the form, and press Submit.',
                  style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onRemove,
    this.isCompact = false,
  });

  final RestockEntry entry;
  final VoidCallback onRemove;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isCompact ? 260 : 280,
        maxWidth: isCompact ? 320 : 360,
        minHeight: isCompact ? 110 : 130,
        maxHeight: isCompact ? 130 : 150,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with better overflow handling
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 13 : 14,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: Icon(Feather.trash_2, size: isCompact ? 16 : 18),
                ),
              ],
            ),
            // Category and ID
            Text(
              '${entry.product.category} • ${entry.product.id}',
              style: TextStyle(
                color: cs.onSurface.withOpacity(.7),
                fontSize: isCompact ? 10 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Pills with better spacing for compact mode
            Flexible(
              child: Wrap(
                spacing: isCompact ? 6 : 8,
                runSpacing: isCompact ? 4 : 6,
                children: [
                  _pill(
                    'Unit',
                    'Rs.${entry.unitPrice.toStringAsFixed(2)}',
                    isCompact,
                  ),
                  _pill(
                    'Sale',
                    'Rs.${entry.salePrice.toStringAsFixed(2)}',
                    isCompact,
                  ),
                  _pill(
                    'Disc',
                    'Rs.${entry.permanentDiscount.toStringAsFixed(2)}',
                    isCompact,
                  ),
                  _pill('Qty', '${entry.quantity}', isCompact),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Total with proper overflow handling
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Total: Rs.${entry.lineTotal.toStringAsFixed(2)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
          Text(value, style: TextStyle(fontSize: isCompact ? 10 : 11)),
        ],
      ),
    );
  }
}
