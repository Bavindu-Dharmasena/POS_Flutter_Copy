import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ⬅ for keyboard shortcuts
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// Correct imports for the components
import '../../components/modern_stat_tile.dart';
import '../../components/modern_list_tile_card.dart';
import '../../components/back_tile.dart';

// Import the other screen pages
import 'stockkeeper_reports.dart';
import 'stockkeeper_cashier.dart';
// import 'stockkeeper_products.dart';
import 'stockkeeper_inventory.dart';

/// Keyboard intents

class BackIntent extends Intent { const BackIntent(); }
class JumpToTopIntent extends Intent { const JumpToTopIntent(); }
class JumpToBottomIntent extends Intent { const JumpToBottomIntent(); }

class StockKeeperDashboard extends StatefulWidget {
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
    "Product E"

  ];
  final List<String> topCategories = [
    "Beverages",
    "Snacks",
    "Dairy",
    "Bakery",
    "Fruits"

  ];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) {
          const begin = Offset(1, 0), end = Offset.zero;

          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(position: a.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  /// Theme-aware extras
  LinearGradient _chipGradient(ColorScheme cs) => LinearGradient(

        colors: [cs.primary, cs.tertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Gradient _bgSweep(ColorScheme cs) => SweepGradient(
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

  LinearGradient _panelSheen(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.surface,
          cs.surfaceVariant.withOpacity(.4),
          cs.background,
        ],
      );


  // ---------------------------
  // 🎨 VIBRANT, FIXED GRADIENTS
  // ---------------------------

  // Stats
  LinearGradient _gMonthlySales() => const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)], // red → orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient _gTotalSales() => const LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)], // teal → green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient _gNetProfit() => const LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)], // indigo → purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient _gDailySales() => const LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)], // pink → red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Lists
  LinearGradient _gListTopProducts() => const LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], // blue → cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient _gListTopCategories() => const LinearGradient(
    colors: [Color(0xFFFB8500), Color(0xFFFFB700)], // orange → yellow
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _chipGradient(cs),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(
                Feather.package,
                color: cs.onPrimary,
                size: 24,
              ),

            ),
            const SizedBox(width: 12),
            Text(
              'Stock Keeper',
              style: GoogleFonts.poppins(
                textStyle: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: .2,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,

        flexibleSpace: Container(decoration: BoxDecoration(gradient: _bgSweep(cs))),

      ),

      // 🔑 Keyboard: Focus + Shortcuts + Actions wrapping the scroll view
      body: Actions(
        actions: <Type, Action<Intent>>{
          // Use the default ScrollAction to handle ScrollIntent
          ScrollIntent: ScrollAction(),
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (_) {
              Navigator.maybePop(context);
              return null;
            },
          ),
          JumpToTopIntent: CallbackAction<JumpToTopIntent>(
            onInvoke: (_) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
              return null;
            },
          ),
          JumpToBottomIntent: CallbackAction<JumpToBottomIntent>(
            onInvoke: (_) {
              final max = _scrollController.positions.isNotEmpty
                  ? _scrollController.position.maxScrollExtent
                  : 0.0;
              _scrollController.animateTo(
                max,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            // Esc => Back
            SingleActivator(LogicalKeyboardKey.escape): BackIntent(),

            // Arrows => line scrolls

            SingleActivator(LogicalKeyboardKey.arrowDown):
                ScrollIntent(direction: AxisDirection.down),
            SingleActivator(LogicalKeyboardKey.arrowUp):
                ScrollIntent(direction: AxisDirection.up),

            // PageUp/PageDown => page scrolls
            SingleActivator(LogicalKeyboardKey.pageDown):
                ScrollIntent(direction: AxisDirection.down, type: ScrollIncrementType.page),
            SingleActivator(LogicalKeyboardKey.pageUp):
                ScrollIntent(direction: AxisDirection.up, type: ScrollIncrementType.page),

            // Home/End => jump to top/bottom
            SingleActivator(LogicalKeyboardKey.home): JumpToTopIntent(),
            SingleActivator(LogicalKeyboardKey.end):  JumpToBottomIntent(),

          },
          child: Focus(
            autofocus: true,
            child: PrimaryScrollController(
              controller: _scrollController,
              child: Container(
                decoration: BoxDecoration(gradient: _panelSheen(cs)),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Section Header
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Performance Stats',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
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

                          delegate: SliverChildListDelegate.fixed([
                            _buildAnimatedTile(
                              delay: 0,
                              child: ModernStatTile(
                                title: 'Monthly Sales',
                                value: 'Rs. 250K',
                                icon: Feather.trending_up,
                                gradient: _gMonthlySales(),

                                onActivate: () => _navigateTo(const StockKeeperReports()),
                              ),
                            ),
                            _buildAnimatedTile(
                              delay: 80,
                              child: ModernStatTile(
                                title: 'Total Sales',
                                value: 'Rs. 3.4M',
                                icon: Feather.credit_card,
                                gradient: _gTotalSales(),
                                onActivate: () => _navigateTo(const StockKeeperReports()),
                              ),
                            ),
                            _buildAnimatedTile(

                              delay: 160,
                              child: ModernStatTile(
                                title: 'Net Profit',
                                value: 'Rs. 750K',
                                icon: Feather.bar_chart,
                                gradient: _gNetProfit(),

                                onActivate: () => _navigateTo(const StockKeeperReports()),

                              ),
                            ),
                            _buildAnimatedTile(
                              delay: 240,
                              child: ModernStatTile(
                                title: 'Daily Sales',
                                value: 'Rs. 15.8K',
                                icon: Feather.dollar_sign,
                                gradient: _gDailySales(),

                                onActivate: () => _navigateTo(const StockKeeperCashier()),

                              ),
                            ),
                          ]),
                        ),
                      ),

                      // Lists Section
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Insights',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (isMobile) ...[
                                _buildAnimatedTile(
                                  delay: 320,
                                  child: ModernListTileCard(
                                    title: 'Top Products',
                                    icon: Feather.package,
                                    gradient: _gListTopProducts(),
                                    items: topProducts,

                                    onActivate: () => _navigateTo(const StockKeeperProducts() as Widget),

                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildAnimatedTile(
                                  delay: 400,
                                  child: ModernListTileCard(
                                    title: 'Top Categories',
                                    icon: Feather.layers,
                                    gradient: _gListTopCategories(),
                                    items: topCategories,

                                    onActivate: () => _navigateTo(const StockKeeperInventory()),

                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAnimatedTile(
                                        delay: 320,
                                        child: ModernListTileCard(
                                          title: 'Top Products',
                                          icon: Feather.package,
                                          gradient: _gListTopProducts(),
                                          items: topProducts,

                                          onActivate: () => _navigateTo(const StockKeeperProducts() as Widget),

                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildAnimatedTile(
                                        delay: 400,
                                        child: ModernListTileCard(
                                          title: 'Top Categories',
                                          icon: Feather.layers,
                                          gradient: _gListTopCategories(),
                                          items: topCategories,

                                          onActivate: () => _navigateTo(const StockKeeperInventory()),

                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Back Button
                              _buildAnimatedTile(
                                delay: 480,
                                child: BackTile(
                                  onActivate: () => Navigator.maybePop(context),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
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
    );
  }

  Widget _buildAnimatedTile({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 420 + delay),
      tween: Tween(begin: 0.9, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,

          child: Opacity(opacity: ((value - 0.9) / 0.1).clamp(0, 1), child: child),

        );
      },
      child: child,
    );
  }
}

class StockKeeperProducts {
  const StockKeeperProducts();
}
