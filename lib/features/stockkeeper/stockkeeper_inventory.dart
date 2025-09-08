import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ====== PAGES YOU NAVIGATE TO ======
import 'package:pos_system/features/stockkeeper/inventory/total_items.dart';
import 'package:pos_system/features/stockkeeper/inventory/low_stock_page.dart';
import 'package:pos_system/features/stockkeeper/inventory/restock.dart';

// ===== REPOSITORY (SQLite) =====
import 'package:pos_system/data/repositories/stockkeeper/item_repository.dart';

// ===== Small helpers: gradients derived from theme =====
LinearGradient themedHeaderGradient(ColorScheme cs) => LinearGradient(
  colors: [cs.primary, cs.tertiary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient themedBackgroundSheen(ColorScheme cs) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [cs.surface, cs.surfaceVariant.withOpacity(.35), cs.background],
);

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

/// ---------- Stats screen (ONLY tiles + OUT-OF-STOCK red alert) ----------
class InventoryStatsOnly extends StatefulWidget {
  const InventoryStatsOnly({super.key});

  @override
  State<InventoryStatsOnly> createState() => _InventoryStatsOnlyState();
}

class _InventoryStatsOnlyState extends State<InventoryStatsOnly> {
  final FocusNode _focusNode = FocusNode();
  int _selectedCardIndex = 0; // Track which card is currently selected

  // Live data loaded from SQLite (was a const dummy list before)
  List<Product> products = const [];

  bool _mobileBannerShown = false;

  List<Product> get _outOfStock =>
      products.where((p) => p.isOutOfStock).toList();
  List<Product> get _lowStock =>
      products.where((p) => p.isLowStock).toList(); // still for tile

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadProducts(); // ← pull from SQLite
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowMobileOutOfStockBanner();
  }

  Future<void> _loadProducts() async {
    try {
      final rows = await ItemRepository.instance.fetchItemsForInventory();

      final loaded = rows.map((r) {
        final current = (r['current_stock'] as num?)?.toInt() ?? 0;
        final min    = (r['min_stock'] as num?)?.toInt() ?? 0;
        final price  = (r['unit_sell_price'] as num?)?.toDouble() ?? 0.0;

        // Derive a max stock to preserve your current UI (adjust if you add a real column)
        final max = (min > 0) ? min * 5 : (current + 50);

        return Product(
          id: '${r['id']}',
          name: (r['name'] as String?) ?? '',
          category: (r['category_name'] as String?) ?? '',
          currentStock: current,
          minStock: min,
          maxStock: max,
          price: price,
          barcode: (r['barcode'] as String?) ?? '',
          image: null,
          supplier: (r['supplier_name'] as String?) ?? '',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        products = loaded;
      });

      // show mobile banner after real data arrives
      _maybeShowMobileOutOfStockBanner();
    } catch (e) {
      debugPrint('Failed to load items: $e');
    }
  }

  void _maybeShowMobileOutOfStockBanner() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final oosCount = _outOfStock.length;

    if (!isDesktop && oosCount > 0 && !_mobileBannerShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          MaterialBanner(
            elevation: 2,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            content: Text(
              'Out of stock: $oosCount item(s) need immediate attention.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  setState(() => _mobileBannerShown = true);
                },
                child: const Text('DISMISS'),
              ),
              FilledButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  setState(() => _mobileBannerShown = true);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LowStockRequestPage(),
                    ),
                  );
                },
                child: const Text('VIEW'),
              ),
            ],
          ),
        );
        _mobileBannerShown = true;
      });
    } else if (isDesktop) {
      ScaffoldMessenger.of(context).clearMaterialBanners();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          break;
        case LogicalKeyboardKey.arrowLeft:
          setState(() {
            _selectedCardIndex = (_selectedCardIndex - 1).clamp(0, 2);
          });
          break;
        case LogicalKeyboardKey.arrowRight:
          setState(() {
            _selectedCardIndex = (_selectedCardIndex + 1).clamp(0, 2);
          });
          break;
        case LogicalKeyboardKey.arrowUp:
          setState(() {
            _selectedCardIndex = (_selectedCardIndex - 2).clamp(0, 2);
          });
          break;
        case LogicalKeyboardKey.arrowDown:
          setState(() {
            _selectedCardIndex = (_selectedCardIndex + 2).clamp(0, 2);
          });
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          _openSelectedCard();
          break;
      }
    }
  }

  void _openSelectedCard() {
    switch (_selectedCardIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TotalItems()),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LowStockRequestPage()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RestockPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final totalItems = products.length;
    final lowStockCount = _lowStock.length; // tile
    final outOfStockCount = _outOfStock.length; // red warning

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (r) => themedHeaderGradient(cs).createShader(r),
            child: const Text(
              'Inventory Management',
              style: TextStyle(
                color: Colors.white,
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
          decoration: BoxDecoration(gradient: themedBackgroundSheen(cs)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDesktop)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (outOfStockCount > 0)
                            _OutOfStockPill(
                              count: outOfStockCount,
                              items: _outOfStock.map((e) => e.name).toList(),
                            ),
                        ],
                      ),
                    if (isDesktop) const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double minTileWidth = 300;
                        final int cols = (constraints.maxWidth / minTileWidth)
                            .floor()
                            .clamp(1, 4);
                        const double gap = 20;
                        final double tileWidth =
                            (constraints.maxWidth - (cols - 1) * gap) / cols;

                        final tiles = [
                          _StatTile(
                            width: tileWidth,
                            gradient: const LinearGradient(
                              colors: [Color.fromARGB(255, 65, 82, 196), Color(0xFF7286FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            iconBg: const Color(0xFF8FA3FF),
                            icon: Feather.archive,
                            value: '$totalItems',
                            label: 'Total Items',
                            isSelected: _selectedCardIndex == 0,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TotalItems(),
                              ),
                            ),
                          ),
                          _StatTile(
                            width: tileWidth,
                            gradient: const LinearGradient(
                              colors: [Color.fromARGB(255, 220, 134, 6), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            iconBg: const Color(0xFFFFD699),
                            icon: Feather.alert_triangle,
                            value: '$lowStockCount',
                            label: 'Low Stock',
                            isSelected: _selectedCardIndex == 1,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LowStockRequestPage(),
                              ),
                            ),
                          ),
                          _StatTile(
                            width: tileWidth,
                            gradient: const LinearGradient(
                              colors: [Color.fromARGB(255, 12, 174, 82), Color.fromARGB(255, 0, 255, 102)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            iconBg: const Color.fromARGB(255, 160, 255, 153),
                            icon: Feather.alert_triangle,
                            value: '$lowStockCount',
                            label: 'Re-Stock',
                            isSelected: _selectedCardIndex == 2,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RestockPage(),
                              ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.gradient,
    required this.iconBg,
    required this.icon,
    required this.value,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final double width;
  final LinearGradient gradient;
  final Color iconBg;
  final IconData icon;
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
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
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.02 : 1.0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 52 : 48,
                          height: isSelected ? 52 : 48,
                          decoration: BoxDecoration(
                            color: iconBg.withOpacity(isSelected ? .45 : .35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white.withOpacity(.9),
                            size: isSelected ? 26 : 24,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSelected ? 30 : 28,
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
                            fontSize: isSelected ? 15.5 : 14.5,
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
        ),
      ),
    );
  }
}

class _OutOfStockPill extends StatelessWidget {
  const _OutOfStockPill({required this.count, required this.items});

  final int count;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Out of Stock'),
            content: items.isEmpty
                ? const Text('No items.')
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map(
                            (n) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('• $n'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LowStockRequestPage(),
                    ),
                  );
                },
                child: const Text('Review & Restock'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          border: Border.all(color: cs.error.withOpacity(.5)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer, size: 18),
            const SizedBox(width: 6),
            Text(
              'Out of Stock: $count',
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
