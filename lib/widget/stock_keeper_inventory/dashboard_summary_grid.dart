import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

class DashboardSummaryGrid extends StatelessWidget {
  final List<Product> products;
  final bool isTablet;
  final bool isMobile;

  const DashboardSummaryGrid({
    super.key,
    required this.products,
    required this.isTablet,
    required this.isMobile,
  });

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
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine the number of columns based on screen size
          final crossAxisCount = isTablet ? 4 : (isMobile ? 2 : 4);

          // Calculate card height based on available width

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 12 : 20,
            mainAxisSpacing: isMobile ? 12 : 20,
            childAspectRatio: isMobile ? 1.3 : 1.4,
            children: [
              _webOptimizedSummaryCard(
                title: 'Total Items',
                value: totalItems.toString(),
                icon: Icons.inventory_2_rounded,
                baseColor: const Color(0xFF667EEA),
                isMobile: isMobile,
              ),
              _webOptimizedSummaryCard(
                title: 'Low Stock',
                value: lowStockItems.toString(),
                icon: Icons.warning_amber_rounded,
                baseColor: const Color(0xFFFF9A00),
                isMobile: isMobile,
              ),
              _webOptimizedSummaryCard(
                title: 'Out of Stock',
                value: outOfStockItems.toString(),
                icon: Icons.block_rounded,
                baseColor: const Color(0xFFFF3D71),
                isMobile: isMobile,
              ),
              _webOptimizedSummaryCard(
                title: 'Total Value',
                value: 'Rs. ${totalValue.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                baseColor: const Color(0xFF11998E),
                isMobile: isMobile,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _webOptimizedSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color baseColor,
    bool isMobile = false,
  }) {
    // Use simpler styling for web to avoid rendering artifacts
    if (kIsWeb) {
      return _webSafeCard(
        title: title,
        value: value,
        icon: icon,
        baseColor: baseColor,
        isMobile: isMobile,
      );
    }
    
    // Use full effects for mobile/desktop
    return _fullEffectCard(
      title: title,
      value: value,
      icon: icon,
      baseColor: baseColor,
      isMobile: isMobile,
    );
  }

  Widget _webSafeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color baseColor,
    bool isMobile = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // Use solid color instead of gradient for web
          color: baseColor,
          borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
          // Simplified shadow for web
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 18 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simplified icon container
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 22 : 26,
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 14),
              
              // Value text
              Expanded(
                flex: 2,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              
              // Title text
              Expanded(
                flex: 1,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fullEffectCard({
    required String title,
    required String value,
    required IconData icon,
    required Color baseColor,
    bool isMobile = false,
  }) {
    return ModernHoverCard(
      accentColor: baseColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              baseColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: baseColor.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 18 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 22 : 26,
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 14),
              
              Expanded(
                flex: 2,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              
              Expanded(
                flex: 1,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simplified hover card for better web performance
class ModernHoverCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;

  const ModernHoverCard({
    super.key,
    required this.child,
    required this.accentColor,
  });

  @override
  State<ModernHoverCard> createState() => _ModernHoverCardState();
}

class _ModernHoverCardState extends State<ModernHoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simplified hover effects for web
    if (kIsWeb) {
      return MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      );
    }

    // Full effects for mobile
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isHovered ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ] : [],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}