import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/features/stockkeeper/add_item_page.dart';

// Your widgets
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

/// ===== Vibrant fixed gradients for action tiles (stay colorful in both modes) =====
LinearGradient gEditButton() => const LinearGradient(
  colors: [Color(0xFF60A5FA), Color(0xFFA855F7)], // blue → violet
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient gAdjustButton() => const LinearGradient(
  colors: [Color(0xFF34D399), Color(0xFF10B981)], // mint → green
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
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

  Product({
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
  String? get imageUrl => null;
  String? get sku => null;
}

/// ===== Small hover glow wrapper (theme-aware) =====
class HoverGlow extends StatefulWidget {
  final Widget child;
  const HoverGlow({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverGlow> createState() => _HoverGlowState();
}

class _HoverGlowState extends State<HoverGlow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// ===== Themed action buttons =====
class EditProductButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EditProductButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(150, 50),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
      ).merge(const ButtonStyle(
        // gradient background via MaterialStateProperty and Ink
        padding: MaterialStatePropertyAll(EdgeInsets.zero),
      )),
      onPressed: onPressed,
      icon: const Icon(Icons.edit, size: 22),
      label: Ink(
        decoration: BoxDecoration(
          gradient: gEditButton(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Text(
            "Edit Product",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class AdjustStockButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AdjustStockButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(150, 50),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
      ).merge(const ButtonStyle(
        padding: MaterialStatePropertyAll(EdgeInsets.zero),
      )),
      onPressed: onPressed,
      icon: const Icon(Icons.trending_up, size: 22),
      label: Ink(
        decoration: BoxDecoration(
          gradient: gAdjustButton(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Text(
            "Adjust Stock",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// ===== Custom intents for page-level keyboard handling =====
class BackIntent extends Intent { const BackIntent(); }
class MoveLeftIntent extends Intent { const MoveLeftIntent(); }
class MoveRightIntent extends Intent { const MoveRightIntent(); }
class MoveUpIntent extends Intent { const MoveUpIntent(); }
class MoveDownIntent extends Intent { const MoveDownIntent(); }
class FocusSearchIntent extends Intent { const FocusSearchIntent(); }
class JumpFirstIntent extends Intent { const JumpFirstIntent(); }
class JumpLastIntent extends Intent { const JumpLastIntent(); }

class StockKeeperInventory extends StatefulWidget {
  const StockKeeperInventory({Key? key}) : super(key: key);

  @override
  State<StockKeeperInventory> createState() => _StockKeeperInventoryState();
}

class _StockKeeperInventoryState extends State<StockKeeperInventory> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedStockStatus = 'All';

  final FocusNode _searchNode = FocusNode(debugLabel: 'inventory_search');
  final List<FocusNode> _cardNodes = <FocusNode>[];
  int _focusedIndex = 0;
  int _cols = 2;

  int _lastNodeCount = -1; // guard focus sync to prevent repeated scheduling

  // Sample data
  final List<Product> products = [
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      price: 250.00,
      barcode: '123456789',
      image: 'assets/images/cadbury.webp',
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
      image: 'assets/images/maliban.webp',
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
      image: 'assets/images/coca_cola.webp',
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
      image: 'assets/images/anchor.webp',
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
      image: 'assets/images/sunquick.webp',
      supplier: 'Lanka Beverages',
    ),
  ];

  List<String> get categories {
    final cats = products.map((p) => p.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<Product> get filteredProducts {
    return products.where((product) {
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.barcode.contains(searchQuery) ||
          product.id.toLowerCase().contains(q);
      final matchesCategory =
          selectedCategory == 'All' || product.category == selectedCategory;
      final matchesStockStatus =
          selectedStockStatus == 'All' ||
          (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
          (selectedStockStatus == 'In Stock' &&
              !product.isLowStock &&
              product.currentStock > 0) ||
          (selectedStockStatus == 'Out of Stock' && product.currentStock == 0);
      return matchesSearch && matchesCategory && matchesStockStatus;
    }).toList();
  }

  void _ensureCardNodes(int count) {
    while (_cardNodes.length > count) {
      _cardNodes.removeLast().dispose();
    }
    while (_cardNodes.length < count) {
      _cardNodes.add(FocusNode(debugLabel: 'card_${_cardNodes.length}'));
    }
    if (_cardNodes.isNotEmpty) {
      _focusedIndex = _focusedIndex.clamp(0, _cardNodes.length - 1);
      if (!_cardNodes[_focusedIndex].hasFocus) {
        _cardNodes[_focusedIndex].requestFocus();
      }
    } else {
      _focusedIndex = 0;
    }
  }

  void _focusCard(int i) {
    if (_cardNodes.isEmpty) return;
    final idx = (i % _cardNodes.length + _cardNodes.length) % _cardNodes.length;
    _focusedIndex = idx;
    _cardNodes[idx].requestFocus();
    setState(() {});
  }

  int _nextIndex(int current, LogicalKeyboardKey key) {
    final count = _cardNodes.length;
    if (count == 0) return 0;
    if (key == LogicalKeyboardKey.arrowRight) return (current + 1) % count;
    if (key == LogicalKeyboardKey.arrowLeft) return (current - 1 + count) % count;
    if (key == LogicalKeyboardKey.arrowDown) {
      final j = current + _cols;
      if (j < count) return j;
      final col = current % _cols;
      return col;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final j = current - _cols;
      if (j >= 0) return j;
      return current;
    }
    return current;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchNode.dispose();
    for (final n in _cardNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // keep focus nodes in sync ONLY when count changes (prevents repeated scheduling)
    final countNow = filteredProducts.length;
    if (_lastNodeCount != countNow) {
      _lastNodeCount = countNow;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureCardNodes(countNow);
      });
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.slash): FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): MoveLeftIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): MoveRightIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): MoveUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): MoveDownIntent(),
        SingleActivator(LogicalKeyboardKey.home): JumpFirstIntent(),
        SingleActivator(LogicalKeyboardKey.end): JumpLastIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (_) { Navigator.maybePop(context); return null; },
          ),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (_) { _searchNode.requestFocus(); return null; },
          ),
          JumpFirstIntent: CallbackAction<JumpFirstIntent>(
            onInvoke: (_) { if (_cardNodes.isNotEmpty) _focusCard(0); return null; },
          ),
          JumpLastIntent: CallbackAction<JumpLastIntent>(
            onInvoke: (_) { if (_cardNodes.isNotEmpty) _focusCard(_cardNodes.length - 1); return null; },
          ),
          MoveDownIntent: CallbackAction<MoveDownIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (focused == _searchNode && _cardNodes.isNotEmpty) {
                _focusCard(0);
              } else if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
                final i = _cardNodes.indexOf(focused!);
                final next = _nextIndex(i, LogicalKeyboardKey.arrowDown);
                if (next != i) _focusCard(next);
              }
              return null;
            },
          ),
          MoveUpIntent: CallbackAction<MoveUpIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
                final i = _cardNodes.indexOf(focused!);
                if (i - _cols < 0) {
                  _searchNode.requestFocus();
                } else {
                  _focusCard(i - _cols);
                }
              }
              return null;
            },
          ),
          MoveLeftIntent: CallbackAction<MoveLeftIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
                _focusCard(_nextIndex(_cardNodes.indexOf(focused!), LogicalKeyboardKey.arrowLeft));
              }
              return null;
            },
          ),
          MoveRightIntent: CallbackAction<MoveRightIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
                _focusCard(_nextIndex(_cardNodes.indexOf(focused!), LogicalKeyboardKey.arrowRight));
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: cs.surface, // theme-aware
          appBar: AppBar(
            title: ShaderMask(
              shaderCallback: (bounds) => themedHeaderGradient(cs).createShader(bounds),
              child: const Text(
                'Inventory Management',
                style: TextStyle(
                  color: Colors.white, // keep white to show gradient via ShaderMask
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: cs.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: cs.onSurface),
            actions: [
              IconButton(
                icon: Icon(Feather.search, color: cs.onSurface),
                onPressed: () => _searchNode.requestFocus(),
              ),
              IconButton(
                icon: Icon(Feather.download, color: cs.onSurface),
                onPressed: () => _showExportDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(gradient: themedBackgroundSheen(cs)),
              child: Stack(
                children: [
                  // soft decorative blobs using theme colors
                  Positioned(top: 60, left: 40, child: _blob(cs.primary)),
                  Positioned(right: 80, bottom: 120, child: _blob(cs.tertiary, size: 140)),
                  Positioned(right: 150, top: 220, child: _blob(cs.secondary, size: 90)),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Let this widget size itself — if it’s tall, the grid below still gets space
                          DashboardSummaryGrid(
                            products: products,
                            isTablet: screenWidth > 800,
                            isMobile: screenWidth < 600,
                          ),
                          // Filters (wraps itself internally)
                          SearchAndFilterSection(
                            searchNode: _searchNode,
                            selectedCategory: selectedCategory,
                            selectedStockStatus: selectedStockStatus,
                            categories: categories,
                            onSearchChanged: (value) => setState(() => searchQuery = value),
                            onCategoryChanged: (v) => setState(() {
                              selectedCategory = v!;
                              _ensureCardNodes(filteredProducts.length);
                            }),
                            onStockStatusChanged: (v) => setState(() {
                              selectedStockStatus = v!;
                              _ensureCardNodes(filteredProducts.length);
                            }),
                            isMobile: screenWidth < 600,
                          ),
                          // Grid expands to remaining height
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // ==== RESPONSIVE GRID FIX (no overflow on narrow widths) ====
                                // Choose a target min tile width and derive columns
                                const double minTileWidth = 360; // safe width for your ProductCard
                                int computedCols =
                                    (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
                                // Remember for keyboard navigation
                                _cols = computedCols;

                                // Aspect ratio: slightly wider on phones
                                final bool isNarrow = constraints.maxWidth < 500;
                                final double aspect =
                                    isNarrow ? 3.2 : (computedCols >= 3 ? 1.25 : 1.35);

                                return _buildProductGrid(
                                  cols: computedCols,
                                  aspect: aspect,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _primaryFAB(
            cs: cs,
            label: screenWidth < 600 ? 'Add' : 'Add Product',
            icon: Feather.plus,
            onPressed: () => _showAddProductDialog(context),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color base, {double size = 110}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: base.withOpacity(0.12),
          borderRadius: BorderRadius.circular(size / 2),
        ),
      ),
    );
  }

  Widget _primaryFAB({
    required ColorScheme cs,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 6),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildProductGrid({required int cols, required double aspect}) {
    final cs = Theme.of(context).colorScheme;

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Feather.search, size: 64, color: cs.onSurface.withOpacity(.45)),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                color: cs.onSurface.withOpacity(.85),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final fn = _cardNodes.length > index ? _cardNodes[index] : FocusNode();
            return ProductCard(
              key: ValueKey(filteredProducts[index].id),
              focusNode: fn,
              product: filteredProducts[index],
              onTap: () => _showProductDetails(filteredProducts[index]),
              onMore: () => _showProductActions(filteredProducts[index]),
            );
          },
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(product: product),
    );
  }

  void _showProductActions(Product product) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product name
            Center(
              child: Text(
                product.name,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gradient action buttons
            Row(
              children: [
                Expanded(
                  child: EditProductButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditProductDialog(product);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdjustStockButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAdjustStockDialog(product);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional plain buttons
            _actionButton(
              icon: Feather.eye,
              label: 'View Details',
              onTap: () {
                Navigator.pop(context);
                _showProductDetails(product);
              },
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: Feather.copy,
              label: 'Duplicate Product',
              onTap: () {
                Navigator.pop(context);
                _duplicateProduct(product);
              },
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: Feather.trash_2,
              label: 'Delete Product',
              color: cs.error,
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface.withOpacity(.80);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(.5), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Feather.chevron_right, color: cs.onSurface.withOpacity(.5), size: 16),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    debugPrint('Edit product: ${product.name}');
  }

  void _showAdjustStockDialog(Product product) {
    debugPrint('Adjust stock for: ${product.name}');
  }

  void _duplicateProduct(Product product) {
    debugPrint('Duplicate product: ${product.name}');
  }

  void _deleteProduct(Product product) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Product', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: TextStyle(color: cs.onSurface.withOpacity(.80)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              debugPrint('Delete confirmed for: ${product.name}');
            },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AddItemPage(),
        transitionsBuilder: (_, a, __, child) {
          return SlideTransition(
            position: a.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Export Inventory', style: TextStyle(color: cs.onSurface)),
        content: Text('Choose export format.', style: TextStyle(color: cs.onSurface.withOpacity(.80))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Feather.file_text, size: 18),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}
