import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/features/stockkeeper/products/add_item_page.dart';

/// ===== Shared styles (match StockKeeperHome) =====
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
    border: Border.all(color: Colors.white.withOpacity(borderOpacity), width: 1),
    color: Colors.white.withOpacity(fillOpacity),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: overlayGradient ??
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

/// ---- Custom intents for page-level keyboard handling ----
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

  // Focus management
  final FocusNode _searchNode = FocusNode(debugLabel: 'inventory_search');
  final List<FocusNode> _cardNodes = <FocusNode>[];
  int _focusedIndex = 0; // index in grid
  int _cols = 2; // updated at layout time

  // Sample data - in real app, this would come from database
  List<Product> products = [
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
      final matchesSearch = q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.barcode.contains(searchQuery) ||
          product.id.toLowerCase().contains(q);

      final matchesCategory =
          selectedCategory == 'All' || product.category == selectedCategory;

      final matchesStockStatus = selectedStockStatus == 'All' ||
          (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
          (selectedStockStatus == 'In Stock' &&
              !product.isLowStock &&
              product.currentStock > 0) ||
          (selectedStockStatus == 'Out of Stock' &&
              product.currentStock == 0);

      return matchesSearch && matchesCategory && matchesStockStatus;
    }).toList();
  }

  /// Ensure we have exactly [count] card focus nodes
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
    // keep focus valid if we were on a removed item
    if (_cardNodes.isNotEmpty && !_cardNodes[_focusedIndex].hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cardNodes[_focusedIndex].requestFocus();
      });
    }
  }

  /// Move focus to a given card index
  void _focusCard(int i) {
    if (_cardNodes.isEmpty) return;
    final idx = (i % _cardNodes.length + _cardNodes.length) % _cardNodes.length;
    _focusedIndex = idx;
    _cardNodes[idx].requestFocus();
    setState(() {});
  }

  /// Compute next index for arrow navigation
  int _nextIndex(int current, LogicalKeyboardKey key) {
    final count = _cardNodes.length;
    if (count == 0) return 0;
    if (key == LogicalKeyboardKey.arrowRight) return (current + 1) % count;
    if (key == LogicalKeyboardKey.arrowLeft) return (current - 1 + count) % count;
    if (key == LogicalKeyboardKey.arrowDown) {
      final j = current + _cols;
      if (j < count) return j;
      // wrap same column to first row
      final col = current % _cols;
      return col;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final j = current - _cols;
      if (j >= 0) return j;
      // going above first row is handled by caller (jump to search)
      return current;
    }
    return current;
  }

  @override
  void initState() {
    super.initState();
    // Start with search focused
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

    // Keep card focus nodes in sync with filtered list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCardNodes(filteredProducts.length);
    });

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Global: Esc to go back
        const SingleActivator(LogicalKeyboardKey.escape): const BackIntent(),
        // Focus search
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): const FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.slash): const FocusSearchIntent(),
        // Arrows (page-level handling)
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const MoveLeftIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const MoveRightIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveDownIntent(),
        // Jump
        const SingleActivator(LogicalKeyboardKey.home): const JumpFirstIntent(),
        const SingleActivator(LogicalKeyboardKey.end): const JumpLastIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(onInvoke: (_) {
            Navigator.maybePop(context);
            return null;
          }),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(onInvoke: (_) {
            _searchNode.requestFocus();
            return null;
          }),
          JumpFirstIntent: CallbackAction<JumpFirstIntent>(onInvoke: (_) {
            if (_cardNodes.isNotEmpty) _focusCard(0);
            return null;
          }),
          JumpLastIntent: CallbackAction<JumpLastIntent>(onInvoke: (_) {
            if (_cardNodes.isNotEmpty) _focusCard(_cardNodes.length - 1);
            return null;
          }),
          MoveDownIntent: CallbackAction<MoveDownIntent>(onInvoke: (_) {
            final focused = FocusManager.instance.primaryFocus;
            final onSearch = focused == _searchNode;
            if (onSearch && _cardNodes.isNotEmpty) {
              _focusCard(0); // jump into grid
            } else if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
              final i = _cardNodes.indexOf(focused!);
              final next = _nextIndex(i, LogicalKeyboardKey.arrowDown);
              if (next == i) return null;
              _focusCard(next);
            }
            return null;
          }),
          MoveUpIntent: CallbackAction<MoveUpIntent>(onInvoke: (_) {
            final focused = FocusManager.instance.primaryFocus;
            if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
              final i = _cardNodes.indexOf(focused!);
              final j = i - _cols;
              if (j < 0) {
                _searchNode.requestFocus(); // top row -> back to search
              } else {
                _focusCard(j);
              }
            }
            return null;
          }),
          MoveLeftIntent: CallbackAction<MoveLeftIntent>(onInvoke: (_) {
            final focused = FocusManager.instance.primaryFocus;
            if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
              final i = _cardNodes.indexOf(focused!);
              _focusCard(_nextIndex(i, LogicalKeyboardKey.arrowLeft));
            }
            return null;
          }),
          MoveRightIntent: CallbackAction<MoveRightIntent>(onInvoke: (_) {
            final focused = FocusManager.instance.primaryFocus;
            if (_cardNodes.isNotEmpty && _cardNodes.contains(focused)) {
              final i = _cardNodes.indexOf(focused!);
              _focusCard(_nextIndex(i, LogicalKeyboardKey.arrowRight));
            }
            return null;
          }),
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: kBgBase,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Feather.search, color: Colors.white),
                tooltip: 'Search',
                onPressed: () => _searchNode.requestFocus(),
              ),
              IconButton(
                icon: const Icon(Feather.download, color: Colors.white),
                tooltip: 'Export',
                onPressed: () {
                  _showExportDialog(context);
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
              ),
            ),
            child: Stack(
              children: [
                // subtle floating blobs
                Positioned(top: 60, left: 40, child: _blob(const Color(0xFF3B82F6))),
                Positioned(right: 80, bottom: 120, child: _blob(const Color(0xFF8B5CF6), size: 140)),
                Positioned(right: 150, top: 220, child: _blob(const Color(0xFFEC4899), size: 90)),

                // content
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildDashboardSummary(isTablet, isMobile),
                        _buildSearchAndFilter(isTablet, isMobile),
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

  /// ====== UI pieces ======

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
        elevation: 8,
      ),
    );
  }

  Widget _buildDashboardSummary(bool isTablet, bool isMobile) {
    final totalItems = products.length;
    final lowStockItems = products.where((p) => p.isLowStock).length;
    final outOfStockItems = products.where((p) => p.currentStock == 0).length;
    final totalValue =
        products.fold(0.0, (sum, p) => sum + (p.price * p.currentStock));

    return Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      child: LayoutBuilder(
        builder: (context, _) {
          final crossAxisCount = isTablet ? 4 : (isMobile ? 2 : 3);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 10 : 16,
            mainAxisSpacing: isMobile ? 10 : 16,
            childAspectRatio: isMobile ? 1.8 : 2.3,
            children: [
              _summaryCard(
                title: 'Total Items',
                value: totalItems.toString(),
                icon: Icons.inventory_2_outlined,
                gradient: brandGradient([const Color(0xFF3B82F6), const Color(0xFF06B6D4)]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Low Stock',
                value: lowStockItems.toString(),
                icon: Icons.warning_amber_rounded,
                gradient: brandGradient([const Color(0xFFF59E0B), const Color(0xFFEF4444)]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Out of Stock',
                value: outOfStockItems.toString(),
                icon: Icons.block_outlined,
                gradient: brandGradient([const Color(0xFFEF4444), const Color(0xFFDC2626)]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Total Value',
                value: 'Rs. ${totalValue.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                gradient: brandGradient([const Color(0xFF10B981), const Color(0xFF059669)]),
                isMobile: isMobile,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    bool isMobile = false,
  }) {
    return _HoverGlow(
      borderGlow: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isMobile ? 16 : kRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(.12), width: 1),
        ),
        child: Container(
          decoration: glassBox(
            radius: isMobile ? 16 : kRadius,
            borderOpacity: .10,
            fillOpacity: .0,
            overlayGradient: [Colors.white.withOpacity(.12), Colors.white.withOpacity(.00)],
          ),
          padding: EdgeInsets.all(isMobile ? 10 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isMobile ? 22 : 26),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isTablet, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
      child: Container(
        decoration: glassBox(),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            // Search
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: TextField(
                focusNode: _searchNode,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: 'Search products, barcode, or ID...   (Esc: back, ↓: to grid)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.6)),
                  prefixIcon: Icon(Feather.search, color: Colors.white.withOpacity(.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            const SizedBox(height: 12),
            // Filters
            Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    hint: 'Category',
                    value: selectedCategory,
                    items: categories,
                    onChanged: (v) => setState(() {
                      selectedCategory = v!;
                      _ensureCardNodes(filteredProducts.length);
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _filterDropdown(
                    hint: 'Stock Status',
                    value: selectedStockStatus,
                    items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
                    onChanged: (v) => setState(() {
                      selectedStockStatus = v!;
                      _ensureCardNodes(filteredProducts.length);
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String hint,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withOpacity(.7))),
          dropdownColor: kPanelBg,
          style: const TextStyle(color: Colors.white),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
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
            Text('No products found',
                style: TextStyle(
                    color: Colors.white.withOpacity(.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Try adjusting your search or filters',
                style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 14)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _cols = isTablet ? 3 : (isMobile ? 1 : 2); // keep cols for nav math
          return FocusTraversalGroup(
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
                final fn = _cardNodes.length > index ? _cardNodes[index] : FocusNode();
                return _ProductCard(
                  key: ValueKey(filteredProducts[index].id),
                  focusNode: fn,
                  product: filteredProducts[index],
                  onTap: () => _showProductDetails(filteredProducts[index]),
                  onMore: () => _showProductActions(filteredProducts[index]),
                );
              },
            ),
          );
        },
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
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(position: a.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPanelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Export Inventory', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Choose export format for your inventory data.',
          style: TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          _pillButton('Export CSV', Feather.file_text, onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Exporting CSV...')));
          }),
          _pillButton('Export PDF', Feather.file, onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Exporting PDF...')));
          }),
        ],
      ),
    );
  }

  Widget _pillButton(String label, IconData icon, {required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

/// ===== Product card with hover/scale + glow focus & keyboard activate =====
class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final FocusNode? focusNode;

  const _ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onMore,
    this.focusNode,
  }) : super(key: key);

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  late final Animation<double> _scale =
      Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  VoidCallback? _focusListener;

  @override
  void initState() {
    super.initState();
    _attachFocusListener();
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusListener(oldWidget.focusNode);
      _attachFocusListener();
    }
  }

  void _attachFocusListener() {
    if (widget.focusNode == null) return;
    _focusListener = () {
      final hasFocus = widget.focusNode!.hasFocus;
      if (mounted) setState(() => _focused = hasFocus);
      if (hasFocus) {
        // bring into view when focused via keyboard
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 140),
          alignment: 0.1,
          curve: Curves.easeOut,
        );
      }
    };
    widget.focusNode!.addListener(_focusListener!);
  }

  void _detachFocusListener(FocusNode? node) {
    if (node != null && _focusListener != null) {
      node.removeListener(_focusListener!);
    }
  }

  @override
  void dispose() {
    _detachFocusListener(widget.focusNode);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final borderColor = product.currentStock == 0
        ? Colors.red
        : (product.isLowStock ? Colors.orange : Colors.white);

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      // Non-const: prevents duplicate-keys const-map issues
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onTap();
          return null;
        }),
      },
      child: MouseRegion(
        onEnter: (_) => _ctrl.forward(),
        onExit: (_) => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value * (_focused ? 1.02 : 1.0),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(16),
                decoration: glassBox(
                  radius: 16,
                  borderOpacity: .08,
                  fillOpacity: .05,
                ).copyWith(
                  border: Border.all(
                    color: _focused ? Colors.white.withOpacity(0.95) : borderColor.withOpacity(
                      product.currentStock == 0 ? 0.55 : product.isLowStock ? 0.45 : 0.18),
                    width: _focused ? 2.6 : 1.5,
                  ),
                  boxShadow: [
                    if (_focused)
                      BoxShadow(
                        color: Colors.white.withOpacity(.30),
                        blurRadius: 22,
                        spreadRadius: 1.2,
                      ),
                    BoxShadow(
                      color: Colors.black.withOpacity(.18),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 420;
                    return isMobile
                        ? _mobile(product, widget.onMore)
                        : _desktop(product, widget.onMore);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(Product product, VoidCallback onMore) {
    return Row(
      children: [
        _thumb(product),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(product.category,
                  style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _stockBadge(product),
                  const Spacer(),
                  Text('Rs. ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        IconButton(onPressed: onMore, icon: const Icon(Feather.more_vertical, color: Colors.white))
      ],
    );
  }

  Widget _desktop(Product product, VoidCallback onMore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _thumb(product),
          const Spacer(),
          IconButton(
              onPressed: onMore,
              icon: const Icon(Feather.more_horizontal, color: Colors.white, size: 18)),
        ]),
        const SizedBox(height: 12),
        Text(product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(product.category, style: TextStyle(color: Colors.white.withOpacity(.7))),
        const Spacer(),
        _stockBadge(product),
        const SizedBox(height: 8),
        Text('Rs. ${product.price.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _thumb(Product product) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: product.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                product.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Feather.package, color: Colors.white.withOpacity(.5), size: 20),
              ),
            )
          : Icon(Feather.package, color: Colors.white.withOpacity(.5), size: 20),
    );
  }

  Widget _stockBadge(Product product) {
    Color badgeColor;
    String text;
    IconData icon;

    if (product.currentStock == 0) {
      badgeColor = Colors.red;
      text = 'Out of Stock';
      icon = Feather.x_circle;
    } else if (product.isLowStock) {
      badgeColor = Colors.orange;
      text = 'Low Stock (${product.currentStock})';
      icon = Feather.alert_triangle;
    } else {
      badgeColor = Colors.green;
      text = 'In Stock (${product.currentStock})';
      icon = Feather.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
}

/// ===== Details dialog (styled) =====
class ProductDetailsDialog extends StatelessWidget {
  final Product product;

  const ProductDetailsDialog({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kPanelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: glassBox(radius: kRadius, borderOpacity: .12, fillOpacity: .02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(.12)),
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Feather.package, color: Colors.white.withOpacity(.5)),
                        ),
                      )
                    : Icon(Feather.package, color: Colors.white.withOpacity(.5)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(product.category,
                        style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Feather.x, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 20),
            _detail('Product ID', product.id),
            _detail('Barcode', product.barcode),
            _detail('Supplier', product.supplier),
            _detail('Price', 'Rs. ${product.price.toStringAsFixed(2)}'),
            _detail('Current Stock', '${product.currentStock} units'),
            _detail('Min Stock Level', '${product.minStock} units'),
            _detail('Max Stock Level', '${product.maxStock} units'),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open edit dialog
                  },
                  icon: const Icon(Feather.edit_2),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open stock adjustment dialog
                  },
                  icon: const Icon(Feather.trending_up),
                  label: const Text('Adjust Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 14)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

/// ===== Bottom sheet actions (compact) =====
class ProductActionsSheet extends StatelessWidget {
  final Product product;

  const ProductActionsSheet({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _actionTile(icon: Feather.eye, title: 'View Details', onTap: () {
            Navigator.pop(context);
          }),
          _actionTile(icon: Feather.edit_2, title: 'Edit Product', onTap: () {
            Navigator.pop(context);
          }),
          _actionTile(icon: Feather.trending_up, title: 'Adjust Stock', onTap: () {
            Navigator.pop(context);
          }),
          _actionTile(icon: Feather.copy, title: 'Duplicate', onTap: () {
            Navigator.pop(context);
          }),
          _actionTile(
              icon: Feather.trash_2,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
              }),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
        ]),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: actionColor, size: 20),
      title: Text(title, style: TextStyle(color: actionColor, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      dense: true,
    );
  }
}

/// ===== Small hover glow wrapper =====
class _HoverGlow extends StatefulWidget {
  final Widget child;
  final bool borderGlow;
  const _HoverGlow({required this.child, this.borderGlow = false});

  @override
  State<_HoverGlow> createState() => _HoverGlowState();
}

class _HoverGlowState extends State<_HoverGlow> {
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
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
