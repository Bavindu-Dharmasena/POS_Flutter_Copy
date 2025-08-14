import 'package:flutter/material.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

class DashboardSummaryGrid extends StatelessWidget {
  final List<Product> products;
  final bool isTablet;
  final bool isMobile;

  const DashboardSummaryGrid({
    Key? key,
    required this.products,
    required this.isTablet,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate summary values based on the list of products
    final totalItems = products.length;
    final lowStockItems = products.where((p) => p.isLowStock).length;
    final outOfStockItems = products.where((p) => p.currentStock == 0).length;
    final totalValue = products.fold(
      0.0,
      (sum, p) => sum + (p.price * p.currentStock),
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine the number of columns based on screen size
          final crossAxisCount = isTablet ? 4 : (isMobile ? 2 : 4);

          // Calculate card height based on available width
          final cardWidth =
              (constraints.maxWidth - (crossAxisCount - 1) * 16 - 40) /
              crossAxisCount;
          final cardHeight = isMobile ? 120.0 : 140.0;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 10 : 16,
            mainAxisSpacing: isMobile ? 10 : 16,
            childAspectRatio: cardWidth / cardHeight, // Dynamic aspect ratio
            children: [
              _summaryCard(
                title: 'Total Items',
                value: totalItems.toString(),
                icon: Icons.inventory_2_outlined,
                gradient: brandGradient([
                  const Color(0xFF3B82F6),
                  const Color(0xFF06B6D4),
                ]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Low Stock',
                value: lowStockItems.toString(),
                icon: Icons.warning_amber_rounded,
                gradient: brandGradient([
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                ]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Out of Stock',
                value: outOfStockItems.toString(),
                icon: Icons.block_outlined,
                gradient: brandGradient([
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626),
                ]),
                isMobile: isMobile,
              ),
              _summaryCard(
                title: 'Total Value',
                value: 'Rs. ${totalValue.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                gradient: brandGradient([
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ]),
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
    return HoverGlow(
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
            overlayGradient: [
              Colors.white.withOpacity(.12),
              Colors.white.withOpacity(.00),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isMobile ? 24 : 28),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
