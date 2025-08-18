// ignore_for_file: prefer_single_quotes  // Using single quotes as required, SonarQube false trigger
import "package:flutter/material.dart";
import "package:flutter_vector_icons/flutter_vector_icons.dart";
import "package:google_fonts/google_fonts.dart";

// Correct imports for the components
import "../../components/back_tile.dart";
import "../../components/modern_list_tile_card.dart";
import "../../components/modern_stat_tile.dart";

// Import the other screen pages
import "stockkeeper_cashier.dart";
import "stockkeeper_inventory.dart";
import "stockkeeper_products.dart";
import "stockkeeper_reports.dart";

/// The dashboard screen for stock keepers, showing inventory stats and
/// controls.
class StockKeeperDashboard extends StatefulWidget {
  /// Creates a [StockKeeperDashboard] widget.
  const StockKeeperDashboard({super.key});

  @override
  State<StockKeeperDashboard> createState() => _StockKeeperDashboardState();
}

class _StockKeeperDashboardState extends State<StockKeeperDashboard>
    with TickerProviderStateMixin {
  final List<String> topProducts = [
    "Product A",
    "Product B",
    "Product C",
    "Product D",
    "Product E",
  ];
  final List<String> topCategories = [
    "Beverages",
    "Snacks",
    "Dairy",
    "Bakery",
    "Fruits",
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) {
          const begin = Offset(1, 0), end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.elasticOut));
          return SlideTransition(position: a.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Feather.package, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Stock Keeper",
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E1A), Color(0xFF1E1B4B), Color(0xFF0A0E1A)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF0A0E1A)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Section Header
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          "Performance Stats",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : (screenWidth < 1000 ? 2 : 4),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.1 : 1.2,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildAnimatedTile(
                      delay: 0,
                      child: ModernStatTile(
                        title: "Monthly Sales",
                        value: "Rs. 250K",
                        icon: Feather.trending_up,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onActivate: () =>
                            _navigateTo(const StockKeeperReports()),
                      ),
                    ),
                    _buildAnimatedTile(
                      delay: 100,
                      child: ModernStatTile(
                        title: "Total Sales",
                        value: "Rs. 3.4M",
                        icon: Feather.credit_card,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onActivate: () =>
                            _navigateTo(const StockKeeperReports()),
                      ),
                    ),
                    _buildAnimatedTile(
                      delay: 200,
                      child: ModernStatTile(
                        title: "Net Profit",
                        value: "Rs. 750K",
                        icon: Feather.bar_chart,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onActivate: () =>
                            _navigateTo(const StockKeeperReports()),
                      ),
                    ),
                    _buildAnimatedTile(
                      delay: 300,
                      child: ModernStatTile(
                        title: "Daily Sales",
                        value: "Rs. 15.8K",
                        icon: Feather.dollar_sign,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onActivate: () =>
                            _navigateTo(const StockKeeperCashier()),
                      ),
                    ),
                  ]),
                ),
              ),

              // Lists Section
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        "Quick Insights",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lists in a responsive layout
                      if (isMobile) ...[
                        _buildAnimatedTile(
                          delay: 400,
                          child: ModernListTileCard(
                            title: "Top Products",
                            icon: Feather.package,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            items: topProducts,
                            onActivate: () =>
                                _navigateTo(const StockKeeperProducts()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnimatedTile(
                          delay: 500,
                          child: ModernListTileCard(
                            title: "Top Categories",
                            icon: Feather.layers,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB8500), Color(0xFFFFB700)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            items: topCategories,
                            onActivate: () =>
                                _navigateTo(const StockKeeperInventory()),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnimatedTile(
                                delay: 400,
                                child: ModernListTileCard(
                                  title: "Top Products",
                                  icon: Feather.package,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4FACFE),
                                      Color(0xFF00F2FE),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  items: topProducts,
                                  onActivate: () =>
                                      _navigateTo(const StockKeeperProducts()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAnimatedTile(
                                delay: 500,
                                child: ModernListTileCard(
                                  title: "Top Categories",
                                  icon: Feather.layers,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFB8500),
                                      Color(0xFFFFB700),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  items: topCategories,
                                  onActivate: () =>
                                      _navigateTo(const StockKeeperInventory()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Back Button
                      _buildAnimatedTile(
                        delay: 600,
                        child: BackTile(
                          onActivate: () => Navigator.pop(context),
                        ),
                      ),

                      // Bottom spacing
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTile({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // Clamp opacity to valid range to avoid assertion failures.
        final visible = value.clamp(0.0, 1.0);
        // Keep a subtle bounce on scale even if value overshoots.
        final scale = 0.9 + 0.2 * value;

        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: visible, child: child),
        );
      },
      child: child,
    );
  }
}
