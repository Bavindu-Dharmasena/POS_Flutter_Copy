import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// ---------- Demo product model (same shape you already use) ----------
import 'package:pos_system/features/stockkeeper/add_item_page.dart';
import 'package:pos_system/features/stockkeeper/inventory/total_items.dart';

// Your widgets (unused here but left in case you reference later)
import 'package:pos_system/widget/stock_keeper_inventory/dashboard_summary_grid.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_actions_sheet.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_card.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_details_dialog.dart';
import 'package:pos_system/widget/stock_keeper_inventory/search_and_filter_section.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_edit.dart';

/// ===== Small helpers: gradients derived from theme =====
LinearGradient themedHeaderGradient(ColorScheme cs) => LinearGradient(
  colors: [cs.primary, cs.tertiary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient themedBackgroundSheen(ColorScheme cs) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    cs.surface,
    cs.surfaceVariant.withOpacity(.35),
    cs.background,
  ],
);

Gradient themedSweepOverlay(ColorScheme cs) => SweepGradient(
  center: Alignment.topLeft,
  startAngle: 0,
  endAngle: 3.14 * 2,
  colors: [
    cs.primary.withOpacity(.08),
    cs.secondary.withOpacity(.06),
    cs.tertiary.withOpacity(.08),
    cs.primary.withOpacity(.08),
  ],
);

/// ===== Product model =====
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

/// ---------- Stats + Low Stock + Out-of-Stock screen ----------
class InventoryStatsOnly extends StatefulWidget {
  const InventoryStatsOnly({super.key});

  @override
  State<InventoryStatsOnly> createState() => _InventoryStatsOnlyState();
}

class _InventoryStatsOnlyState extends State<InventoryStatsOnly> {
  // Example items – replace with your live data
  final List<Product> products = const [
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      price: 250.00,
      barcode: '123456789',
      image: null,
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
      barcode: '987654321',
      image: null,
      supplier: 'Maliban Biscuits',
    ),
    Product(
      id: '003',
      name: 'Coca Cola 330ml',
      category: 'Beverages',
      currentStock: 67,
      minStock: 25,
      maxStock: 120,
      price: 150.00,
      barcode: '456789123',
      image: null,
      supplier: 'Coca Cola Lanka',
    ),
    Product(
      id: '004',
      name: 'Anchor Milk Powder 400g',
      category: 'Dairy',
      currentStock: 12,
      minStock: 10,
      maxStock: 50,
      price: 850.00,
      barcode: '789123456',
      image: null,
      supplier: 'Fonterra Lanka',
    ),
    Product(
      id: '005',
      name: 'Sunquick Orange 700ml',
      category: 'Beverages',
      currentStock: 23,
      minStock: 15,
      maxStock: 60,
      price: 420.00,
      barcode: '321654987',
      image: null,
      supplier: 'Lanka Beverages',
    ),
    // Example out-of-stock to demonstrate the warning banner:
    Product(
      id: '006',
      name: 'Sprite 1L',
      category: 'Beverages',
      currentStock: 0,
      minStock: 10,
      maxStock: 60,
      price: 260.00,
      barcode: '888888888',
      image: null,
      supplier: 'Coca Cola Lanka',
    ),
  ];

  // Selection state for Low Stock table
  final Set<String> _selectedIds = <String>{};
  final Map<String, TextEditingController> _qtyCtrls = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    // Prepare default quantities for low stock items
    for (final p in _lowStock) {
      _qtyCtrls[p.id] = TextEditingController(text: _suggestQty(p).toString());
    }
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Computed helpers ----------
  List<Product> get _lowStock => products.where((p) => p.isLowStock).toList();
  List<Product> get _outOfStock => products.where((p) => p.isOutOfStock).toList();

  int _suggestQty(Product p) {
    // simple heuristic: fill up to min(maxStock, minStock * 2)
    final target = (p.minStock * 2).clamp(0, p.maxStock);
    final need = target - p.currentStock;
    return need > 0 ? need : (p.minStock - p.currentStock).clamp(1, p.maxStock);
  }

  String _money(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  // ---------- Actions ----------
  void _requestToSupplier() {
    final selectedProducts = _lowStock.where((p) => _selectedIds.contains(p.id)).toList();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to request.')),
      );
      return;
    }

    // Build a simple summary
    final lines = selectedProducts.map((p) {
      final qty = int.tryParse(_qtyCtrls[p.id]?.text ?? '') ?? 0;
      return '• ${p.name} — $qty pcs';
    }).join('\n');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send request to supplier?'),
        content: Text(lines),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: integrate your real flow here.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request sent for ${selectedProducts.length} item(s).')),
              );
              setState(() => _selectedIds.clear());
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Stats
    final totalItems = products.length;
    final lowStockCount = _lowStock.length;
    final outOfStockCount = _outOfStock.length;
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.price * p.currentStock),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (r) => LinearGradient(
            colors: [cs.primary, cs.tertiary],
          ).createShader(r),
          child: const Text(
            'Inventory Management',
            style: TextStyle(
              color: Colors.white, // keep white for ShaderMask
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: const [
          SizedBox(width: 12),
          Icon(Feather.search),
          SizedBox(width: 12),
          Icon(Feather.download),
          SizedBox(width: 12),
        ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ===== Centered, responsive tiles =====
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const double minTileWidth = 300;
                      final int cols = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
                      const double gap = 20;
                      final double tileWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;

                      final tiles = [
                        _StatTile(
                          width: tileWidth,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7386FF), Color(0xFF7286FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color(0xFF8FA3FF),
                          icon: Feather.archive,
                          value: '$totalItems',
                          label: 'Total Items',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TotalItems()),
                          ),
                        ),
                        _StatTile(
                          width: tileWidth,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color(0xFFFFD699),
                          icon: Feather.alert_triangle,
                          value: '$lowStockCount',
                          label: 'Low Stock',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TotalItems()),
                          ),
                        ),
                        _StatTile(
                          width: tileWidth,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5C8A), Color(0xFFFF4D73)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color(0xFFFFA7BE),
                          icon: Feather.slash,
                          value: '$outOfStockCount',
                          label: 'Out of Stock',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TotalItems()),
                          ),
                        ),
                        _StatTile(
                          width: tileWidth,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A085), Color(0xFF129277)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color(0xFF6FD3C1),
                          icon: Feather.trending_up,
                          value: _money(totalValue),
                          label: 'Total Value',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TotalItems()),
                          ),
                        ),
                      ];

                      return Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: gap,
                        runSpacing: gap,
                        children: tiles,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== Out-of-Stock WARNING (not a card) =====
                  if (outOfStockCount > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.error.withOpacity(.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                              const SizedBox(width: 8),
                              Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: cs.onErrorContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($outOfStockCount)',
                                style: TextStyle(
                                  color: cs.onErrorContainer.withOpacity(.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _outOfStock
                                .map((p) => Chip(
                                      label: Text(p.name, overflow: TextOverflow.ellipsis),
                                      backgroundColor:
                                          cs.onErrorContainer.withOpacity(.08),
                                      shape: StadiumBorder(
                                        side: BorderSide(color: cs.onErrorContainer),
                                      ),
                                      labelStyle: TextStyle(color: cs.onErrorContainer),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  if (outOfStockCount > 0) const SizedBox(height: 24),

                  // ===== Low Stock (select + request) =====
                  _LowStockTable(
                    products: _lowStock,
                    selectedIds: _selectedIds,
                    qtyCtrls: _qtyCtrls,
                    onChanged: () => setState(() {}),
                    onRequestToSupplier: _requestToSupplier,
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

/// ---------- Single tile (tappable with ripple) ----------
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.gradient,
    required this.iconBg,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final double width;
  final LinearGradient gradient;
  final Color iconBg;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon bubble
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg.withOpacity(.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white.withOpacity(.9)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.9),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Low Stock table with selection + request button ----------
class _LowStockTable extends StatelessWidget {
  const _LowStockTable({
    required this.products,
    required this.selectedIds,
    required this.qtyCtrls,
    required this.onChanged,
    required this.onRequestToSupplier,
  });

  final List<Product> products;
  final Set<String> selectedIds;
  final Map<String, TextEditingController> qtyCtrls;
  final VoidCallback onChanged;
  final VoidCallback onRequestToSupplier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSelection = selectedIds.isNotEmpty;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Feather.alert_triangle, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Low Stock',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: hasSelection ? onRequestToSupplier : null,
                  icon: const Icon(Icons.send),
                  label: Text(
                    hasSelection
                        ? 'Request to Supplier (${selectedIds.length})'
                        : 'Request to Supplier',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No low-stock items.',
                  style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                ),
              )
            else
              // Responsive horizontally scrollable table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 920),
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    headingTextStyle: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(label: Text('Select')),
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Curr.')),
                      DataColumn(label: Text('Min')),
                      DataColumn(label: Text('Max')),
                      DataColumn(label: Text('Req. Qty')),
                    ],
                    rows: products.map((p) {
                      qtyCtrls.putIfAbsent(p.id, () => TextEditingController(text: '1'));
                      final selected = selectedIds.contains(p.id);
                      return DataRow(
                        selected: selected,
                        cells: [
                          DataCell(Checkbox(
                            value: selected,
                            onChanged: (_) {
                              if (selected) {
                                selectedIds.remove(p.id);
                              } else {
                                selectedIds.add(p.id);
                              }
                              onChanged();
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
                              width: 110,
                              child: TextField(
                                controller: qtyCtrls[p.id],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                onChanged: (_) => onChanged(),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
