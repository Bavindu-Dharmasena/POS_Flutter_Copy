import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/products/add_item_page.dart';
import 'package:pos_system/widget/stock_keeper_inventory/dashboard_summary_grid.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_actions_sheet.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_card.dart';
import 'package:pos_system/widget/stock_keeper_inventory/product_details_dialog.dart';
import 'package:pos_system/widget/stock_keeper_inventory/search_and_filter_section.dart';

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
}

/// ===== Shared styles =====
const kBgBase = Color(0xFF0B1623);
const kPanelBg = Color(0xFF1a2332);
const kRadius = 24.0;

BoxDecoration glassBox({
  double radius = kRadius,
  double borderOpacity = .10,
  double fillOpacity = .08,
  List<Color>? overlayGradient,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: Colors.white.withOpacity(borderOpacity),
      width: 1,
    ),
    color: Colors.white.withOpacity(fillOpacity),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          overlayGradient ??
          [Colors.white.withOpacity(.10), Colors.white.withOpacity(.02)],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.35),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

LinearGradient brandGradient(List<Color> colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: colors,
);

/// ===== Small hover glow wrapper =====
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(.22),
                    blurRadius: 24,
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

/// ===== Custom intents for page-level keyboard handling =====
class BackIntent extends Intent {
  const BackIntent();
}

class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

class MoveUpIntent extends Intent {
  const MoveUpIntent();
}

class MoveDownIntent extends Intent {
  const MoveDownIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class JumpFirstIntent extends Intent {
  const JumpFirstIntent();
}

class JumpLastIntent extends Intent {
  const JumpLastIntent();
}

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

  // Sample data - in a real app, this would come from a database or API
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
    } else {
      _focusedIndex = 0;
    }
    if (_cardNodes.isNotEmpty && !_cardNodes[_focusedIndex].hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cardNodes[_focusedIndex].requestFocus();
      });
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
    if (key == LogicalKeyboardKey.arrowLeft)
      return (current - 1 + count) % count;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 800;
    final isMobile = screenWidth < 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCardNodes(filteredProducts.length);
    });

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const BackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.slash):
            const FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const MoveLeftIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const MoveRightIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const MoveDownIntent(),
        const SingleActivator(LogicalKeyboardKey.home): const JumpFirstIntent(),
        const SingleActivator(LogicalKeyboardKey.end): const JumpLastIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (_) {
              Navigator.maybePop(context);
              return null;
            },
          ),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (_) {
              _searchNode.requestFocus();
              return null;
            },
          ),
          JumpFirstIntent: CallbackAction<JumpFirstIntent>(
            onInvoke: (_) {
              if (_cardNodes.isNotEmpty) _focusCard(0);
              return null;
            },
          ),
          JumpLastIntent: CallbackAction<JumpLastIntent>(
            onInvoke: (_) {
              if (_cardNodes.isNotEmpty) _focusCard(_cardNodes.length - 1);
              return null;
            },
          ),
          MoveDownIntent: CallbackAction<MoveDownIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (focused == _searchNode && _cardNodes.isNotEmpty) {
                _focusCard(0);
              } else if (_cardNodes.isNotEmpty &&
                  _cardNodes.contains(focused)) {
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
                _focusCard(
                  _nextIndex(
                    _cardNodes.indexOf(focused!),
                    LogicalKeyboardKey.arrowLeft,
                  ),
                );
              }
              return null;
            },
          ),
          MoveRightIntent: CallbackAction<MoveRightIntent>(
            onInvoke: (_) {
              final focused = FocusManager.instance.primaryFocus;
              if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
                _focusCard(
                  _nextIndex(
                    _cardNodes.indexOf(focused!),
                    LogicalKeyboardKey.arrowRight,
                  ),
                );
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: kBgBase,
          appBar: AppBar(
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
              ).createShader(bounds),
              child: const Text(
                'Inventory Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: kBgBase,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Feather.search, color: Colors.white),
                onPressed: () => _searchNode.requestFocus(),
              ),
              IconButton(
                icon: const Icon(Feather.download, color: Colors.white),
                onPressed: () => _showExportDialog(context),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 60,
                  left: 40,
                  child: _blob(const Color(0xFF3B82F6)),
                ),
                Positioned(
                  right: 80,
                  bottom: 120,
                  child: _blob(const Color(0xFF8B5CF6), size: 140),
                ),
                Positioned(
                  right: 150,
                  top: 220,
                  child: _blob(const Color(0xFFEC4899), size: 90),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        DashboardSummaryGrid(
                          products: products,
                          isTablet: isTablet,
                          isMobile: isMobile,
                        ),
                        SearchAndFilterSection(
                          searchNode: _searchNode,
                          selectedCategory: selectedCategory,
                          selectedStockStatus: selectedStockStatus,
                          categories: categories,
                          onSearchChanged: (value) =>
                              setState(() => searchQuery = value),
                          onCategoryChanged: (v) => setState(() {
                            selectedCategory = v!;
                            _ensureCardNodes(filteredProducts.length);
                          }),
                          onStockStatusChanged: (v) => setState(() {
                            selectedStockStatus = v!;
                            _ensureCardNodes(filteredProducts.length);
                          }),
                          isMobile: isMobile,
                        ),
                        Expanded(child: _buildProductGrid(isTablet, isMobile)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _primaryFAB(
            label: isMobile ? 'Add' : 'Add Product',
            icon: Feather.plus,
            onPressed: () => _showAddProductDialog(context),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color c, {double size = 110}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  Widget _primaryFAB({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 6),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildProductGrid(bool isTablet, bool isMobile) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Feather.search, size: 64, color: Colors.white.withOpacity(.5)),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                color: Colors.white.withOpacity(.8),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    _cols = isTablet ? 3 : (isMobile ? 1 : 2);
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: isMobile ? 3.5 : 1.18,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final fn = _cardNodes.length > index
                ? _cardNodes[index]
                : FocusNode();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanelBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProductActionsSheet(product: product),
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
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPanelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Export Inventory',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Choose export format.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
