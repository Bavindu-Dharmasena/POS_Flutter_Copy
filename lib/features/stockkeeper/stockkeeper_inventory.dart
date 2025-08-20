import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// ---------- Demo product model (same shape you already use) ----------
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
}

/// ---------- Stats-only screen ----------
class InventoryStatsOnly extends StatelessWidget {
  const InventoryStatsOnly({super.key});

  // Example items – replace with your live data
  List<Product> get products => const [
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
      ];

  String _money(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute stats
    final totalItems = products.length;
    final lowStock = products.where((p) => p.isLowStock).length;
    final outOfStock = products.where((p) => p.currentStock == 0).length;
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              // Centered, responsive tiles
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Choose a target min tile width; compute columns 1..4
                  const double minTileWidth = 300;
                  final int cols =
                      (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
                  final double gap = 20;
                  final double tileWidth = (constraints.maxWidth -
                          (cols - 1) * gap)
                      / cols;

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
                      value: '$lowStock',
                      label: 'Low Stock',
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
                      value: '$outOfStock',
                      label: 'Out of Stock',
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
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Single tile ----------
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.gradient,
    required this.iconBg,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double width;
  final LinearGradient gradient;
  final Color iconBg;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onCard = Colors.white;
    return SizedBox(
      width: width,
      child: Container(
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
                  child: Icon(icon, color: onCard.withOpacity(.9)),
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
                    color: onCard.withOpacity(.9),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
