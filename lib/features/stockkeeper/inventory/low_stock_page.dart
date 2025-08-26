import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intent used by Shortcuts/Actions to go back on ESC.
class BackIntent extends Intent {
  const BackIntent();
}

/// ---- Dark table palette (extracted from your screenshot) ----
const _kDarkCard     = Color(0xFF0F1318); // outer container / card
const _kDarkHeader   = Color(0xFF1F2631); // header row
const _kDarkRow      = Color(0xFF141A21); // body rows
const _kDarkDivider  = Color(0xFF2A3240); // table grid lines
const _kDarkTextMain = Color(0xFFE6EAF0); // main text
const _kDarkTextMute = Color(0xFFB7C0CC); // secondary text

/// If you already have a shared Product model, delete this one and import yours.
class Product {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double price; // unit/sale price if needed
  final String supplier;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.supplier,
  });

  // Low stock = >0 and below/equal min (adjust if you prefer strict < min)
  bool get isLowStock => currentStock > 0 && currentStock <= minStock;
  bool get isOutOfStock => currentStock == 0;
}

/// Low Stock → Request page
class LowStockRequestPage extends StatefulWidget {
  /// Pass your full product list; only low-stock items will be shown.
  final List<Product>? allProducts;
  const LowStockRequestPage({super.key, this.allProducts});

  @override
  State<LowStockRequestPage> createState() => _LowStockRequestPageState();
}

class _LowStockRequestPageState extends State<LowStockRequestPage> {
  // --- demo data (used only if allProducts == null) ---
  static const _demo = <Product>[
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 4,
      minStock: 20,
      maxStock: 100,
      price: 250.00,
      supplier: 'Cadbury Lanka',
    ),
    Product(
      id: '002',
      name: 'Maliban Cream Crackers',
      category: 'Biscuits',
      currentStock: 8,
      minStock: 15,
      maxStock: 80,
      price: 180.00,
      supplier: 'Maliban Biscuits',
    ),
    Product(
      id: '003',
      name: 'Coca Cola 330ml',
      category: 'Beverages',
      currentStock: 6,
      minStock: 25,
      maxStock: 120,
      price: 150.00,
      supplier: 'Coca Cola Lanka',
    ),
    Product(
      id: '004',
      name: 'Anchor Milk Powder 400g',
      category: 'Dairy',
      currentStock: 2,
      minStock: 10,
      maxStock: 50,
      price: 850.00,
      supplier: 'Fonterra Lanka',
    ),
    Product(
      id: '005',
      name: 'Sunquick Orange 700ml',
      category: 'Beverages',
      currentStock: 3,
      minStock: 15,
      maxStock: 60,
      price: 420.00,
      supplier: 'Lanka Beverages',
    ),
  ];

  // --- state ---
  late final List<Product> _source; // full low-stock list (pre-filtered)
  final Map<String, TextEditingController> _qtyCtrls = {};
  final Set<String> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _supplierFilter = 'All';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _source = (widget.allProducts ?? _demo).where((p) => p.isLowStock).toList();

    // preload suggested quantities
    for (final p in _source) {
      _qtyCtrls[p.id] = TextEditingController(text: _suggestQty(p).toString());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- helpers ---
  int _suggestQty(Product p) {
    // Fill up to min(2*min, max), at least 1 more if below min
    final target = (p.minStock * 2).clamp(0, p.maxStock);
    final need = target - p.currentStock;
    if (need > 0) return need;
    final delta = p.minStock - p.currentStock;
    return delta > 0 ? delta : 1;
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _source.where((p) {
      final supplierOK = _supplierFilter == 'All' || p.supplier == _supplierFilter;
      final textOK = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return supplierOK && textOK;
    }).toList()
      ..sort((a, b) {
        int cmp;
        switch (_sortColumnIndex) {
          case 1: // item name
            cmp = a.name.compareTo(b.name);
            break;
          case 2: // supplier
            cmp = a.supplier.compareTo(b.supplier);
            break;
          case 3: // current
            cmp = a.currentStock.compareTo(b.currentStock);
            break;
          case 4: // min
            cmp = a.minStock.compareTo(b.minStock);
            break;
          case 5: // max
            cmp = a.maxStock.compareTo(b.maxStock);
            break;
          default:
            cmp = a.name.compareTo(b.name);
        }
        return _sortAscending ? cmp : -cmp;
      });
  }

  List<String> get _suppliers {
    final s = _source.map((e) => e.supplier).toSet().toList()..sort();
    s.insert(0, 'All');
    return s;
  }

  int _qtyOf(String id) => int.tryParse(_qtyCtrls[id]?.text ?? '') ?? 0;
  int get _selectedCount => _selected.length;

  // --- actions ---
  void _toggleSelectAll(bool? value, List<Product> visible) {
    setState(() {
      if (value == true) {
        _selected.addAll(visible.map((e) => e.id));
      } else {
        _selected.removeAll(visible.map((e) => e.id));
      }
    });
  }

  void _autoFillVisible(List<Product> visible) {
    for (final p in visible) {
      _qtyCtrls[p.id]?.text = _suggestQty(p).toString();
    }
    setState(() {});
  }

  void _clearSelection() => setState(_selected.clear);

  void _requestToSupplier(List<Product> visible) {
    final sel = visible.where((p) => _selected.contains(p.id)).toList();
    if (sel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item.')),
      );
      return;
    }

    // Group by supplier for a clean confirmation
    final Map<String, List<Product>> bySupp = {};
    for (final p in sel) {
      bySupp.putIfAbsent(p.supplier, () => []).add(p);
    }

    final summary = StringBuffer();
    bySupp.forEach((supplier, items) {
      summary.writeln('• $supplier');
      for (final p in items) {
        summary.writeln('   - ${p.name}  ×  ${_qtyOf(p.id)}');
      }
      summary.writeln();
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create supplier request?'),
        content: SingleChildScrollView(child: Text(summary.toString().trim())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Integrate real create-request behavior.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request created for $_selectedCount item(s).')),
              );
              _clearSelection();
            },
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final visible = _filtered;

    // Wrap the whole page with Shortcuts/Actions so ESC triggers back anywhere.
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (intent) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        // A Focus to ensure the Shortcuts are active immediately.
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Low Stock — Request to Supplier'),
              centerTitle: true,
            ),
            floatingActionButton: isWide
                ? null
                : FloatingActionButton.extended(
                    onPressed: visible.isEmpty ? null : () => _requestToSupplier(visible),
                    icon: const Icon(Icons.send),
                    label: Text(_selectedCount > 0 ? 'Request (${_selectedCount})' : 'Request'),
                  ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.surface, cs.surfaceVariant.withOpacity(.35), cs.background],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FilterBar(
                          suppliers: _suppliers,
                          supplier: _supplierFilter,
                          onSupplierChanged: (v) => setState(() => _supplierFilter = v),
                          searchCtrl: _searchCtrl,
                          onSearchChanged: (_) => setState(() {}),
                          onAutofill: () => _autoFillVisible(visible),
                          onClearSelection: _selected.isEmpty ? null : _clearSelection,
                          selectedCount: _selectedCount,
                          onRequest: visible.isEmpty ? null : () => _requestToSupplier(visible),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: visible.isEmpty
                              ? _EmptyState(
                                  text: _source.isEmpty
                                      ? 'No low-stock items.'
                                      : 'No matches. Adjust filters.',
                                )
                              : isWide
                                  ? _buildDesktopTable(cs, visible)
                                  : _buildMobileList(cs, visible),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ---- FULL-SCREEN DESKTOP TABLE + DARK PALETTE ----
  Widget _buildDesktopTable(ColorScheme cs, List<Product> visible) {
    // proper tri-state value for the master checkbox
    final selectedInView = visible.where((p) => _selected.contains(p.id)).length;
    bool? masterValue;
    if (visible.isEmpty) {
      masterValue = false;
    } else if (selectedInView == 0) {
      masterValue = false;
    } else if (selectedInView == visible.length) {
      masterValue = true;
    } else {
      masterValue = null; // indeterminate
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // DataTable theme (dark only). Light mode uses your defaults.
    final themed = Theme.of(context).copyWith(
      cardColor: isDark ? _kDarkCard : Theme.of(context).cardColor,
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStatePropertyAll(isDark ? _kDarkHeader : cs.surfaceVariant),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered) && isDark) {
            return _kDarkRow.withOpacity(.95);
          }
          return isDark ? _kDarkRow : cs.surface;
        }),
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          color: isDark ? _kDarkTextMain : cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: TextStyle(
          color: isDark ? _kDarkTextMute : cs.onSurface,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        return Theme(
          data: themed,
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: isDark ? _kDarkCard : null,
            child: SizedBox(
              width: c.maxWidth,
              height: c.maxHeight, // fill available height (full screen area)
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView( // vertical scroll
                  child: SingleChildScrollView( // horizontal scroll
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Stretch to full width; keep a sensible minimum of 980
                        minWidth: c.maxWidth < 980 ? 980 : c.maxWidth,
                      ),
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        headingRowHeight: 52,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(
                            label: Row(
                              children: [
                                Checkbox(
                                  value: masterValue,
                                  tristate: true,
                                  onChanged: (value) => _toggleSelectAll(value, visible),
                                ),
                                const SizedBox(width: 4),
                                const Text('Select'),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: const Text('Item'),
                            onSort: (i, asc) => setState(() {
                              _sortColumnIndex = i;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Supplier'),
                            onSort: (i, asc) => setState(() {
                              _sortColumnIndex = i;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Curr.'), numeric: true,
                            onSort: (i, asc) => setState(() {
                              _sortColumnIndex = i;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Min'), numeric: true,
                            onSort: (i, asc) => setState(() {
                              _sortColumnIndex = i;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Max'), numeric: true,
                            onSort: (i, asc) => setState(() {
                              _sortColumnIndex = i;
                              _sortAscending = asc;
                            }),
                          ),
                          const DataColumn(label: Text('Req. Qty')),
                        ],
                        rows: visible.map((p) {
                          final selected = _selected.contains(p.id);
                          final ctrl = _qtyCtrls[p.id]!;
                          return DataRow(
                            selected: selected,
                            onSelectChanged: (_) {
                              setState(() {
                                if (selected) {
                                  _selected.remove(p.id);
                                } else {
                                  _selected.add(p.id);
                                }
                              });
                            },
                            cells: [
                              DataCell(Checkbox(
                                value: selected,
                                onChanged: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(p.id);
                                    } else {
                                      _selected.add(p.id);
                                    }
                                  });
                                },
                              )),
                              DataCell(SizedBox(
                                width: 300,
                                child: Text(p.name, overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(Text(p.supplier)),
                              DataCell(Text('${p.currentStock}')),
                              DataCell(Text('${p.minStock}')),
                              DataCell(Text('${p.maxStock}')),
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: Row(
                                    children: [
                                      _qtyBtn(icon: Icons.remove, onTap: () {
                                        final q = (_qtyOf(p.id) - 1).clamp(0, p.maxStock);
                                        ctrl.text = '$q';
                                        setState(() {});
                                      }),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: ctrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _qtyBtn(icon: Icons.add, onTap: () {
                                        final q = (_qtyOf(p.id) + 1).clamp(0, p.maxStock);
                                        ctrl.text = '$q';
                                        setState(() {});
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileList(ColorScheme cs, List<Product> visible) {
    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = visible[i];
        final selected = _selected.contains(p.id);
        final ctrl = _qtyCtrls[p.id]!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckboxListTile(
                  value: selected,
                  onChanged: (_) => setState(() {
                    if (selected) {
                      _selected.remove(p.id);
                    } else {
                      _selected.add(p.id);
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.supplier),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Curr.', '${p.currentStock}', cs),
                    _chip('Min', '${p.minStock}', cs),
                    _chip('Max', '${p.maxStock}', cs),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Req. Qty'),
                    const Spacer(),
                    _qtyBtn(icon: Icons.remove, onTap: () {
                      final q = (_qtyOf(p.id) - 1).clamp(0, p.maxStock);
                      ctrl.text = '$q';
                      setState(() {});
                    }),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 82,
                      child: TextField(
                        controller: ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _qtyBtn(icon: Icons.add, onTap: () {
                      final q = (_qtyOf(p.id) + 1).clamp(0, p.maxStock);
                      ctrl.text = '$q';
                      setState(() {});
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // small UI helpers
  Widget _chip(String label, String value, ColorScheme cs) => Chip(
        label: Text('$label: $value'),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: cs.outlineVariant),
      );

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(icon, size: 18),
        ),
      );
}

/// Top filter/action bar (mobile-friendly)
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.suppliers,
    required this.supplier,
    required this.onSupplierChanged,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onAutofill,
    required this.onClearSelection,
    required this.selectedCount,
    required this.onRequest,
  });

  final List<String> suppliers;
  final String supplier;
  final ValueChanged<String> onSupplierChanged;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAutofill;
  final VoidCallback? onClearSelection;
  final int selectedCount;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final searchField = TextField(
      controller: searchCtrl,
      onChanged: onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Search item or category',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );

    final supplierDrop = DropdownButtonFormField<String>(
      value: supplier,
      isExpanded: true,
      items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => onSupplierChanged(v ?? 'All'),
      decoration: const InputDecoration(
        labelText: 'Supplier',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onAutofill,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Auto-fill suggestions'),
        ),
        if (onClearSelection != null)
          OutlinedButton.icon(
            onPressed: onClearSelection,
            icon: const Icon(Icons.clear_all),
            label: Text('Clear ($selectedCount)'),
          ),
        FilledButton.icon(
          onPressed: onRequest,
          icon: const Icon(Icons.send),
          label: Text(
            selectedCount > 0 ? 'Request to Supplier ($selectedCount)' : 'Request to Supplier',
          ),
        ),
      ],
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  SizedBox(width: 260, child: supplierDrop),
                  const SizedBox(width: 12),
                  actions,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMPORTANT: no Expanded here (fixes mobile “filter not showing”)
                  searchField,
                  const SizedBox(height: 8),
                  supplierDrop,
                  const SizedBox(height: 12),
                  actions,
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: cs.onSurface.withOpacity(.5)),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: cs.onSurface.withOpacity(.75))),
        ],
      ),
    );
  }
}
