import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ====== PAGES YOU NAVIGATE TO ======
import 'package:pos_system/features/stockkeeper/inventory/total_items.dart';
import 'package:pos_system/features/stockkeeper/inventory/low_stock_page.dart';
import 'package:pos_system/features/stockkeeper/inventory/restock.dart';


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
  // Dummy data so you can see the alert instantly. Replace with your live list.
  final List<Product> products = const [
    Product(
      id: '001',
      name: 'Cadbury Dairy Milk',
      category: 'Chocolates',
      currentStock: 6,
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
      currentStock: 10,
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
      currentStock: 0, // OUT OF STOCK
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
      currentStock: 8,
      minStock: 10,
      maxStock: 50,
      price: 850.00,
      barcode: '789123456',
      image: null,
      supplier: 'Fonterra Lanka',
    ),
  ];

  bool _mobileBannerShown = false;

  List<Product> get _outOfStock =>
      products.where((p) => p.isOutOfStock).toList();
  List<Product> get _lowStock =>
      products.where((p) => p.isLowStock).toList(); // still for tile

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowMobileOutOfStockBanner();
  }

  void _maybeShowMobileOutOfStockBanner() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final oosCount = _outOfStock.length;

    // Show a top red banner on mobile only, once per visit
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
                  // Navigate to LOW STOCK page as requested
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
      // Ensure banners are cleared on desktop
      ScaffoldMessenger.of(context).clearMaterialBanners();
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

    return Scaffold(
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
        decoration: BoxDecoration(gradient: themedBackgroundSheen(cs)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Desktop-only: top-right OUT-OF-STOCK red pill ----
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

                  // ---- Centered, responsive tiles (Total Items + Low Stock) ----
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
                            colors: [Color(0xFF7386FF), Color(0xFF7286FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color(0xFF8FA3FF),
                          icon: Feather.archive,
                          value: '$totalItems',
                          label: 'Total Items',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TotalItems(),
                            ),
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
                            MaterialPageRoute(
                              builder: (_) => const LowStockRequestPage(),
                            ),
                          ),
                        ),

                        _StatTile(
                          width: tileWidth,
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 38, 255, 132), Color.fromARGB(255, 0, 255, 102)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconBg: const Color.fromARGB(255, 160, 255, 153),
                          icon: Feather.alert_triangle,
                          value: '$lowStockCount',
                          label: 'Re-Stock',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RestockPage()
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
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

/// ---------- Compact OUT-OF-STOCK red pill (desktop, top-right) ----------
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
              // Navigate to LOW STOCK page as requested
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
            Icon(
              Icons.warning_amber_rounded,
              color: cs.onErrorContainer,
              size: 18,
            ),
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
