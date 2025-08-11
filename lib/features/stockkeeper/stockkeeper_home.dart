import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stockkeeper/stockkeeper_dashboard.dart';
import '../stockkeeper/stockkeeper_products.dart';
import '../stockkeeper/stockkeeper_inventory.dart';
import '../stockkeeper/stockkeeper_reports.dart';
import '../stockkeeper/stockkeeper_cashier.dart';
import '../stockkeeper/stockkeeper_more.dart';

/// Custom intents for extra keyboard actions
class JumpToFirstIntent extends Intent {
  const JumpToFirstIntent();
}
class JumpToLastIntent extends Intent {
  const JumpToLastIntent();
}
class BackIntent extends Intent {
  const BackIntent();
}

class StockKeeperHome extends StatefulWidget {
  const StockKeeperHome({super.key});

  @override
  State<StockKeeperHome> createState() => _StockKeeperHomeState();
}

class _StockKeeperHomeState extends State<StockKeeperHome> {
  // Focus management
  final List<FocusNode> _tileNodes = [];
  int _focusedIndex = 0;

  // Ensure we have exactly [count] focus nodes
  void _ensureNodes(int count) {
    if (_tileNodes.length == count) return;
    while (_tileNodes.length > count) {
      _tileNodes.removeLast().dispose();
    }
    while (_tileNodes.length < count) {
      _tileNodes.add(FocusNode(debugLabel: 'tile_${_tileNodes.length}'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tileNodes.isNotEmpty) {
        _focusedIndex = _focusedIndex.clamp(0, _tileNodes.length - 1);
        if (!_tileNodes[_focusedIndex].hasFocus) {
          _tileNodes[_focusedIndex].requestFocus();
        }
      }
    });
  }

  void _focusAt(int i) {
    if (_tileNodes.isEmpty) return;
    _focusedIndex = (i % _tileNodes.length + _tileNodes.length) % _tileNodes.length;
    _tileNodes[_focusedIndex].requestFocus();
    setState(() {});
  }

  int _nextIndex({
    required int current,
    required int cols,
    required int count,
    required LogicalKeyboardKey key,
  }) {
    if (count == 0) return 0;

    if (key == LogicalKeyboardKey.arrowRight) {
      return (current + 1) % count;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return (current - 1 + count) % count;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      final j = current + cols;
      if (j < count) return j;
      final col = current % cols;
      return col; // wrap to top, same column
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final j = current - cols;
      if (j >= 0) return j;
      final col = current % cols;
      final lastRow = ((count - 1 - col) ~/ cols);
      return lastRow * cols + col; // wrap to last row, same column
    }
    return (current + 1) % count;
  }

  @override
  void dispose() {
    for (final n in _tileNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
          ).createShader(bounds),
          child: const Text(
            'Stock Keeper Home',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(0xFF0B1623),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
          ),
        ),
        child: Stack(
          children: [
            // Floating decorative elements
            Positioned(
              top: 50, left: 50,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Positioned(
              bottom: 100, right: 80,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Positioned(
              top: 200, right: 150,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = MediaQuery.of(context).size.height -
                      kToolbarHeight - MediaQuery.of(context).padding.top - 48;

                  final interactiveTiles = <_TileSpec>[
                    _TileSpec(
                      title: 'Dashboard',
                      subtitle: 'Overview & Analytics',
                      icon: Icons.dashboard_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperDashboard(),
                    ),
                    _TileSpec(
                      title: 'Products',
                      subtitle: 'Manage Items',
                      icon: Icons.category_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperProducts(),
                    ),
                    _TileSpec(
                      title: 'Inventory',
                      subtitle: 'Stock Management',
                      icon: Icons.inventory_2_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF0891B2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperInventory(),
                    ),
                    _TileSpec(
                      title: 'Reports',
                      subtitle: 'Charts & Analytics',
                      icon: Icons.bar_chart_outlined,
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 188, 32, 151), Color.fromARGB(255, 154, 121, 156)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperReports(),
                    ),
                    _TileSpec(
                      title: 'Cashier',
                      subtitle: 'Billing & Payments',
                      icon: Icons.receipt_long_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperCashier(),
                    ),
                    _TileSpec(
                      title: 'Settings',
                      subtitle: 'More Options',
                      icon: Icons.settings_outlined,
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 21, 4, 13), Color.fromARGB(255, 111, 107, 107)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      pageBuilder: () => const StockKeeperMore(),
                    ),
                    _TileSpec(
                      title: 'Back',
                      subtitle: 'Go Back',
                      icon: Icons.arrow_back_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAB308), Color(0xFFF97316)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ];

                  _ensureNodes(interactiveTiles.length);

                  final isWide = constraints.maxWidth > 800;
                  final crossAxisCount = isWide ? 4 : 2;

                  // Keyboard wrappers around the grid, including Home/End/Esc
                  return Focus(
                    autofocus: true,
                    child: Shortcuts(
                      shortcuts: const <ShortcutActivator, Intent>{
                        // Arrow navigation (handled via custom action below)
                        SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
                        SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
                        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
                        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
                        // New: Home/End jump, Esc back
                        SingleActivator(LogicalKeyboardKey.home): JumpToFirstIntent(),
                        SingleActivator(LogicalKeyboardKey.end): JumpToLastIntent(),
                        SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          // Override directional traversal with our wrap-around logic
                          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                            onInvoke: (intent) {
                              final key = switch (intent.direction) {
                                TraversalDirection.left => LogicalKeyboardKey.arrowLeft,
                                TraversalDirection.right => LogicalKeyboardKey.arrowRight,
                                TraversalDirection.up => LogicalKeyboardKey.arrowUp,
                                TraversalDirection.down => LogicalKeyboardKey.arrowDown,
                                _ => LogicalKeyboardKey.arrowRight,
                              };
                              final next = _nextIndex(
                                current: _focusedIndex,
                                cols: crossAxisCount,
                                count: interactiveTiles.length,
                                key: key,
                              );
                              _focusAt(next);
                              return null;
                            },
                          ),
                          // New: jump to first/last
                          JumpToFirstIntent: CallbackAction<JumpToFirstIntent>(
                            onInvoke: (_) {
                              _focusAt(0);
                              return null;
                            },
                          ),
                          JumpToLastIntent: CallbackAction<JumpToLastIntent>(
                            onInvoke: (_) {
                              _focusAt(interactiveTiles.length - 1);
                              return null;
                            },
                          ),
                          // New: back navigation
                          BackIntent: CallbackAction<BackIntent>(
                            onInvoke: (_) {
                              Navigator.maybePop(context);
                              return null;
                            },
                          ),
                        },
                        child: FocusTraversalGroup(
                          policy: ReadingOrderTraversalPolicy(),
                          child: isWide
                              ? SizedBox(
                                  height: availableHeight,
                                  child: GridView.count(
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 24,
                                    childAspectRatio: 1.2,
                                    children: [
                                      for (int i = 0; i < interactiveTiles.length; i++)
                                        ModernDashboardTile(
                                          title: interactiveTiles[i].title,
                                          subtitle: interactiveTiles[i].subtitle,
                                          icon: interactiveTiles[i].icon,
                                          gradient: interactiveTiles[i].gradient,
                                          onTap: () {
                                            final onTap = interactiveTiles[i].onTap;
                                            if (onTap != null) {
                                              onTap();
                                            } else {
                                              _navigateTo(context, interactiveTiles[i].pageBuilder!());
                                            }
                                          },
                                          focusNode: _tileNodes[i],
                                        ),
                                      _comingSoonBox(), // non-focusable
                                    ],
                                  ),
                                )
                              : GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1,
                                  children: [
                                    for (int i = 0; i < interactiveTiles.length; i++)
                                      ModernDashboardTile(
                                        title: interactiveTiles[i].title,
                                        subtitle: interactiveTiles[i].subtitle,
                                        icon: interactiveTiles[i].icon,
                                        gradient: interactiveTiles[i].gradient,
                                        onTap: () {
                                          final onTap = interactiveTiles[i].onTap;
                                          if (onTap != null) {
                                            onTap();
                                          } else {
                                            _navigateTo(context, interactiveTiles[i].pageBuilder!());
                                          }
                                        },
                                        focusNode: _tileNodes[i],
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comingSoonBox() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF475569).withOpacity(0.5), const Color(0xFF334155).withOpacity(0.5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 8), blurRadius: 16)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.add_outlined, color: Colors.white54, size: 24),
            ),
            const SizedBox(height: 12),
            const Text('Coming Soon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54)),
            Text('New Features', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _TileSpec {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Widget Function()? pageBuilder;
  final VoidCallback? onTap;

  _TileSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.pageBuilder,
    this.onTap,
  });
}

class ModernDashboardTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const ModernDashboardTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.focusNode,
  });

  @override
  State<ModernDashboardTile> createState() => _ModernDashboardTileState();
}

class _ModernDashboardTileState extends State<ModernDashboardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector
    (
      focusNode: widget.focusNode,
      onShowFocusHighlight: (hasFocus) => setState(() => _focused = hasFocus),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onTap();
          return null;
        }),
      },
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * (_focused ? 1.03 : 1.0),
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withOpacity(0.4),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                          spreadRadius: _controller.value * 2,
                        ),
                        if (_focused)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                      ],
                      border: Border.all(
                        color: _focused ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.1),
                        width: _focused ? 2 : 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.0)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: widget.title,
                          hint: 'Press Enter to open ${widget.title}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: _focused
                                      ? Border.all(color: Colors.white.withOpacity(0.7), width: 1)
                                      : null,
                                ),
                                child: Icon(widget.icon, size: 32, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
