import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// Navigate to these pages
import '../stockkeeper/products/add_item_page.dart';
import '../stockkeeper/products/supplier_page.dart';

/* ---- Custom intents ---- */
class JumpToFirstIntent extends Intent { const JumpToFirstIntent(); }
class JumpToLastIntent extends Intent { const JumpToLastIntent(); }
class BackIntent extends Intent { const BackIntent(); }

class StockKeeperProducts extends StatefulWidget {
  const StockKeeperProducts({Key? key}) : super(key: key);

  @override
  State<StockKeeperProducts> createState() => _StockKeeperProductsState();
}

class _StockKeeperProductsState extends State<StockKeeperProducts> {
  final List<FocusNode> _nodes = [];
  int _focusedIndex = 0;

  @override
  void dispose() {
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  /* ---------- Responsiveness helpers ---------- */
  int _calcColumns(double width) {
    if (width < 400) return 1;   // ultra-small phones
    if (width < 900) return 2;   // phones / small tablets
    if (width < 1300) return 3;  // tablets / small desktops
    return 4;                    // large desktops
  }

  // Higher ratio => shorter cards (smaller vertically).
  double _calcAspectRatio(int cols) {
    switch (cols) {
      case 1: return 1.45;
      case 2: return 1.30;
      case 3: return 1.25;
      default: return 1.22;
    }
  }

  void _ensureNodes(int count) {
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'prod_${_nodes.length}'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nodes.isNotEmpty) {
        _focusedIndex = _focusedIndex.clamp(0, _nodes.length - 1);
        if (!_nodes[_focusedIndex].hasFocus) {
          _nodes[_focusedIndex].requestFocus();
        }
      }
    });
  }

  void _focusAt(int i) {
    if (_nodes.isEmpty) return;
    _focusedIndex = (i % _nodes.length + _nodes.length) % _nodes.length;
    _nodes[_focusedIndex].requestFocus();
    setState(() {});
  }

  int _nextIndex({
    required int current,
    required int cols,
    required int count,
    required LogicalKeyboardKey key,
  }) {
    if (key == LogicalKeyboardKey.arrowRight) return (current + 1) % count;
    if (key == LogicalKeyboardKey.arrowLeft)  return (current - 1 + count) % count;
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
    return current;
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) {
          const begin = Offset(1, 0), end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(position: a.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaleFactor.clamp(1.0, 1.10);

    // The 3 tiles you're using now
    final tiles = <_TileSpec>[
      _TileSpec(
        title: 'Add Item',
        subtitle: 'Create New Item',
        icon: Feather.plus_circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        onTap: () => _navigateTo(const AddItemPage()),
      ),
      _TileSpec(
        title: 'Suppliers',
        subtitle: 'Manage Vendors',
        icon: Feather.truck,
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEAB308)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        onTap: () => _navigateTo(const SupplierPage()),
      ),
      _TileSpec(
        title: 'Back',
        subtitle: 'Go Back',
        icon: Feather.arrow_left,
        gradient: const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFF97316)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.pop(context),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
          ).createShader(bounds),
          child: const Text(
            'Stock Keeper Products',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cols = _calcColumns(constraints.maxWidth);
            final ratio = _calcAspectRatio(cols);

            // Keep the whole grid compact and centered horizontally
            const crossSpacing = 16.0;
            const gridHPadding = 8.0 * 2; // GridView horizontal padding
            const desiredTileWidth = 200.0; // target smaller tile width
            final maxGridWidth = cols * desiredTileWidth + (cols - 1) * crossSpacing + gridHPadding;
            final gridWidth = constraints.maxWidth < maxGridWidth ? constraints.maxWidth : maxGridWidth;

            // Compute actual tile width we’ll get, then scale contents smaller
            final tileWidth = (gridWidth - gridHPadding - (cols - 1) * crossSpacing) / cols;
            final sizeScale = (tileWidth / 260.0).clamp(0.70, 0.95) * textScale;

            _ensureNodes(tiles.length);

            final grid = SizedBox(
              width: gridWidth, // centers horizontally via surrounding Center
              child: Focus(
                autofocus: true,
                child: Shortcuts(
                  shortcuts: const <ShortcutActivator, Intent>{
                    SingleActivator(LogicalKeyboardKey.arrowLeft):  DirectionalFocusIntent(TraversalDirection.left),
                    SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
                    SingleActivator(LogicalKeyboardKey.arrowUp):    DirectionalFocusIntent(TraversalDirection.up),
                    SingleActivator(LogicalKeyboardKey.arrowDown):  DirectionalFocusIntent(TraversalDirection.down),
                    SingleActivator(LogicalKeyboardKey.home):       JumpToFirstIntent(),
                    SingleActivator(LogicalKeyboardKey.end):        JumpToLastIntent(),
                    SingleActivator(LogicalKeyboardKey.escape):     BackIntent(),
                  },
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                        onInvoke: (intent) {
                          final key = switch (intent.direction) {
                            TraversalDirection.left  => LogicalKeyboardKey.arrowLeft,
                            TraversalDirection.right => LogicalKeyboardKey.arrowRight,
                            TraversalDirection.up    => LogicalKeyboardKey.arrowUp,
                            TraversalDirection.down  => LogicalKeyboardKey.arrowDown,
                            // ignore: unreachable_switch_case
                            _ => LogicalKeyboardKey.arrowRight,
                          };
                          final next = _nextIndex(
                            current: _focusedIndex,
                            cols: cols,
                            count: tiles.length,
                            key: key,
                          );
                          _focusAt(next);
                          return null;
                        },
                      ),
                      JumpToFirstIntent: CallbackAction<JumpToFirstIntent>(
                        onInvoke: (_) { _focusAt(0); return null; },
                      ),
                      JumpToLastIntent: CallbackAction<JumpToLastIntent>(
                        onInvoke: (_) { _focusAt(tiles.length - 1); return null; },
                      ),
                      BackIntent: CallbackAction<BackIntent>(
                        onInvoke: (_) { Navigator.maybePop(context); return null; },
                      ),
                    },
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        // Let outer scroll view handle scrolling / vertical centering
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: crossSpacing,
                          mainAxisSpacing: 16,
                          childAspectRatio: ratio,
                        ),
                        itemCount: tiles.length,
                        itemBuilder: (context, index) {
                          final t = tiles[index];
                          return ModernProductTile(
                            focusNode: _nodes[index],
                            title: t.title,
                            subtitle: t.subtitle,
                            icon: t.icon,
                            gradient: t.gradient,
                            onTap: t.onTap,
                            sizeScale: sizeScale,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );

            // Center vertically when short; scroll when tall
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: Padding(padding: const EdgeInsets.all(16), child: grid)),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* -------------------- Model -------------------- */
class _TileSpec {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  _TileSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

/* -------------------- Tile widget with saved styling -------------------- */
class ModernProductTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final double sizeScale; // scales paddings/icon/fonts to tile width

  const ModernProductTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.focusNode,
    this.sizeScale = 1.0,
  });

  @override
  State<ModernProductTile> createState() => _ModernProductTileState();
}

class _ModernProductTileState extends State<ModernProductTile>
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
    final s = widget.sizeScale;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (hasFocus) => setState(() => _focused = hasFocus),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            HapticFeedback.lightImpact();
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            HapticFeedback.lightImpact();
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
                      borderRadius: BorderRadius.circular((20 * s).clamp(14, 20)),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withOpacity(0.30),
                          offset: const Offset(0, 6),
                          blurRadius: 12,
                          spreadRadius: _controller.value * 1.5,
                        ),
                        if (_focused)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.20),
                            blurRadius: 16,
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
                        borderRadius: BorderRadius.circular((20 * s).clamp(14, 20)),
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.0)],
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
                                padding: EdgeInsets.all((9 * s).clamp(7, 11)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular((16 * s).clamp(12, 18)),
                                  border: _focused
                                      ? Border.all(color: Colors.white.withOpacity(0.7), width: 1)
                                      : null,
                                ),
                                child: Icon(widget.icon, size: (26 * s).clamp(20, 30), color: Colors.white),
                              ),
                              SizedBox(height: (10 * s).clamp(8, 14)),
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: (15 * s).clamp(13, 17),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: (3 * s).clamp(2, 6)),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: (11.5 * s).clamp(10.5, 12.5),
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
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
  void dispose() { _controller.dispose(); super.dispose(); }
}
