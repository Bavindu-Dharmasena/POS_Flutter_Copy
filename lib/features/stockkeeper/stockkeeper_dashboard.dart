import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// Navigate to these pages
import '../stockkeeper/stockkeeper_reports.dart';
import '../stockkeeper/stockkeeper_cashier.dart';
import '../stockkeeper/stockkeeper_products.dart';
import '../stockkeeper/stockkeeper_inventory.dart';

/* ---- Custom intents ---- */
class JumpToFirstIntent extends Intent { const JumpToFirstIntent(); }
class JumpToLastIntent extends Intent { const JumpToLastIntent(); }
class BackIntent extends Intent { const BackIntent(); }

class StockKeeperDashboard extends StatefulWidget {
  const StockKeeperDashboard({super.key});

  @override
  State<StockKeeperDashboard> createState() => _StockKeeperDashboardState();
}

class _StockKeeperDashboardState extends State<StockKeeperDashboard> {
  final List<String> topProducts = ["Product A","Product B","Product C","Product D","Product E"];
  final List<String> topCategories = ["Beverages","Snacks","Dairy","Bakery","Fruits"];

  // Drag & drop items: 4 stats + 2 lists + Back
  late List<_ItemSpec> _items;

  // Focus management mirrors the item order
  final List<FocusNode> _nodes = [];
  int _focusedIndex = 0;

  // Drag visual state
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();

    _items = [
      _ItemSpec(
        id: 'monthly_sales',
        builder: (focus, s) => ModernStatTile(
          focusNode: focus,
          title: 'Monthly Sales',
          value: 'Rs. 250,000',
          icon: Feather.trending_up,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          onActivate: () => _navigateTo(const StockKeeperReports()),
        ),
      ),
      _ItemSpec(
        id: 'total_sales',
        builder: (focus, s) => ModernStatTile(
          focusNode: focus,
          title: 'Total Sales',
          value: 'Rs. 3,400,000',
          icon: Feather.credit_card,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          onActivate: () => _navigateTo(const StockKeeperReports()),
        ),
      ),
      _ItemSpec(
        id: 'net_profit',
        builder: (focus, s) => ModernStatTile(
          focusNode: focus,
          title: 'Net Profit',
          value: 'Rs. 750,000',
          icon: Feather.bar_chart,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 8, 26, 56), Color.fromARGB(255, 1, 14, 37)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          onActivate: () => _navigateTo(const StockKeeperReports()),
        ),
      ),
      _ItemSpec(
        id: 'daily_sales',
        builder: (focus, s) => ModernStatTile(
          focusNode: focus,
          title: 'Daily Sales Amount',
          value: 'Rs. 15,800',
          icon: Feather.dollar_sign,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 17, 1, 55), Color.fromARGB(255, 9, 5, 73)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          onActivate: () => _navigateTo(const StockKeeperCashier()),
        ),
      ),
      _ItemSpec(
        id: 'top_products',
        builder: (focus, s) => ModernListTileCard(
          focusNode: focus,
          title: 'Top Products',
          icon: Feather.package,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEAB308)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          items: topProducts,
          onActivate: () => _navigateTo(const StockKeeperProducts()),
        ),
      ),
      _ItemSpec(
        id: 'top_categories',
        builder: (focus, s) => ModernListTileCard(
          focusNode: focus,
          title: 'Top Categories',
          icon: Feather.layers,
          sizeScale: s,
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          items: topCategories,
          onActivate: () => _navigateTo(const StockKeeperInventory()),
        ),
      ),
      _ItemSpec(
        id: 'back',
        builder: (focus, s) => _BackTile(
          focusNode: focus,
          sizeScale: s,
          onActivate: () => Navigator.pop(context),
        ),
      ),
    ];

    _ensureNodes(_items.length, requestFirstFocus: true);
  }

  /* ---------- Responsiveness helpers ---------- */
  int _calcColumns(double width) {
    if (width < 520) return 1;     // small phones
    if (width < 900) return 2;     // phones / small tablets
    if (width < 1300) return 3;    // tablets / small desktops
    return 4;                       // large desktops
  }

  double _calcAspectRatio(int cols) {
    switch (cols) {
      case 1: return 1.25;
      case 2: return 1.22;
      case 3: return 1.30;
      default: return 1.40;
    }
  }

  double _calcSizeScale(double tileWidth, double textScale) {
    // Scales font/paddings so tiles are smaller on mobile but still readable
    return (tileWidth / 260.0).clamp(0.78, 1.05) * textScale.clamp(1.0, 1.12);
  }

  void _ensureNodes(int count, {bool requestFirstFocus = false}) {
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'dash_${_nodes.length}'));
    }
    if (requestFirstFocus && _nodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusedIndex = _focusedIndex.clamp(0, _nodes.length - 1);
        if (!_nodes[_focusedIndex].hasFocus) _nodes[_focusedIndex].requestFocus();
      });
    }
  }

  void _focusAt(int i) {
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
      return col; // wrap to top same column
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final j = current - cols;
      if (j >= 0) return j;
      final col = current % cols;
      final lastRow = ((count - 1 - col) ~/ cols);
      return lastRow * cols + col; // wrap to last row same column
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

  void _reorder(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= _items.length || to >= _items.length) return;

    final FocusNode? focusedNode =
        (_nodes.isNotEmpty && _focusedIndex < _nodes.length) ? _nodes[_focusedIndex] : null;

    setState(() {
      final spec = _items.removeAt(from);
      _items.insert(to, spec);

      final node = _nodes.removeAt(from);
      _nodes.insert(to, node);

      if (focusedNode != null) {
        final idx = _nodes.indexOf(focusedNode);
        if (idx != -1) _focusedIndex = idx;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nodes.isNotEmpty && _focusedIndex < _nodes.length) {
        _nodes[_focusedIndex].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaleFactor;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
          ).createShader(bounds),
          child: const Text(
            'Stock Keeper Dashboard',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = _calcColumns(constraints.maxWidth);
              final ratio = _calcAspectRatio(cols);

              const gridHPadding = 8.0 * 2;
              const crossSpacing = 16.0;
              final tileWidth =
                  (constraints.maxWidth - gridHPadding - (cols - 1) * crossSpacing) / cols;
              final sizeScale = _calcSizeScale(tileWidth, textScale);

              return Focus(
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
                          LogicalKeyboardKey key;
                          switch (intent.direction) {
                            case TraversalDirection.left:  key = LogicalKeyboardKey.arrowLeft;  break;
                            case TraversalDirection.right: key = LogicalKeyboardKey.arrowRight; break;
                            case TraversalDirection.up:    key = LogicalKeyboardKey.arrowUp;    break;
                            case TraversalDirection.down:  key = LogicalKeyboardKey.arrowDown;  break;
                            default:                       key = LogicalKeyboardKey.arrowRight; break;
                          }
                          final next = _nextIndex(
                            current: _focusedIndex,
                            cols: cols,
                            count: _nodes.length,
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
                        onInvoke: (_) { _focusAt(_nodes.length - 1); return null; },
                      ),
                      BackIntent: CallbackAction<BackIntent>(
                        onInvoke: (_) { Navigator.maybePop(context); return null; },
                      ),
                    },
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: Scrollbar(
                        thumbVisibility: false,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: ratio,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return _DraggableDashTile(
                              key: ValueKey(_items[index].id),
                              index: index,
                              isDragging: _draggingIndex == index,
                              focusNode: _nodes[index],
                              sizeScale: sizeScale,
                              buildTile: () => _items[index].builder(_nodes[index], sizeScale),
                              buildFeedback: () => _items[index].builder(null, (sizeScale * 0.92).clamp(0.7, 1.0)),
                              onActivate: () {
                                final ctx = _nodes[index].context;
                                if (ctx != null) {
                                  Actions.invoke(ctx, const ActivateIntent());
                                }
                              },
                              onDragStarted: () => setState(() => _draggingIndex = index),
                              onDragEnded: () => setState(() => _draggingIndex = null),
                              onAccept: (from) => _reorder(from, index),
                            );
                          },
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
}

/* -------------------- Item spec -------------------- */
class _ItemSpec {
  final String id;
  final Widget Function(FocusNode? focusNode, double sizeScale) builder;
  _ItemSpec({required this.id, required this.builder});
}

/* -------------------- Draggable wrapper -------------------- */
class _DraggableDashTile extends StatelessWidget {
  final int index;
  final bool isDragging;
  final FocusNode? focusNode;
  final double sizeScale;
  final Widget Function() buildTile;
  final Widget Function() buildFeedback;
  final VoidCallback onActivate;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final ValueChanged<int> onAccept;

  const _DraggableDashTile({
    super.key,
    required this.index,
    required this.isDragging,
    required this.focusNode,
    required this.sizeScale,
    required this.buildTile,
    required this.buildFeedback,
    required this.onActivate,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAccept: (from) => from != null && from != index,
      onAccept: onAccept,
      builder: (context, candidateData, rejected) {
        final isReceiving = candidateData.isNotEmpty;

        return Draggable<int>(
          data: index,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnded(),
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 0.9,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
                child: buildFeedback(),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.30, child: buildTile()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: isReceiving
                  ? [BoxShadow(color: Colors.white.withOpacity(0.35), blurRadius: 18, spreadRadius: 1)]
                  : null,
            ),
            child: buildTile(),
          ),
        );
      },
    );
  }
}

/* -------------------- Tiles (with size scaling) -------------------- */

class ModernStatTile extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final FocusNode? focusNode;
  final VoidCallback? onActivate;
  final double sizeScale;

  const ModernStatTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.focusNode,
    this.onActivate,
    this.sizeScale = 1.0,
  });

  @override
  State<ModernStatTile> createState() => _ModernStatTileState();
}

class _ModernStatTileState extends State<ModernStatTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sizeScale;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (hasFocus) => setState(() => _focused = hasFocus),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onActivate?.call();
          return null;
        }),
      },
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_focused ? 1.03 : 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular((24 * s).clamp(18, 24)),
                  border: Border.all(
                    color: _focused ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.08),
                    width: _focused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.4),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                    if (_focused)
                      BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 20, spreadRadius: 1),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: (44 * s).clamp(34, 48), color: Colors.white),
                      SizedBox(height: (14 * s).clamp(10, 16)),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: (16 * s).clamp(14, 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: (6 * s).clamp(4, 8)),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: (14 * s).clamp(12, 16),
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

class ModernListTileCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final List<String> items;
  final FocusNode? focusNode;
  final VoidCallback? onActivate;
  final double sizeScale;

  const ModernListTileCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.items,
    this.focusNode,
    this.onActivate,
    this.sizeScale = 1.0,
  });

  @override
  State<ModernListTileCard> createState() => _ModernListTileCardState();
}

class _ModernListTileCardState extends State<ModernListTileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sizeScale;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (hasFocus) => setState(() => _focused = hasFocus),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onActivate?.call();
          return null;
        }),
      },
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_focused ? 1.03 : 1.0),
              child: Container(
                padding: EdgeInsets.all((14 * s).clamp(10, 16)),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular((24 * s).clamp(18, 24)),
                  border: Border.all(
                    color: _focused ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.08),
                    width: _focused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.4),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                    if (_focused)
                      BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 20, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(widget.icon, size: (34 * s).clamp(28, 36), color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: (16 * s).clamp(14, 18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (10 * s).clamp(8, 12)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.items
                              .map((item) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: (3.5 * s).clamp(2, 6)),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: (8 * s).clamp(6, 8),
                                          height: (8 * s).clamp(6, 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: (13 * s).clamp(11, 14),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

/* Back tile with keyboard support */
class _BackTile extends StatefulWidget {
  final FocusNode? focusNode;
  final VoidCallback onActivate;
  final double sizeScale;
  const _BackTile({required this.onActivate, this.focusNode, this.sizeScale = 1.0});

  @override
  State<_BackTile> createState() => _BackTileState();
}

class _BackTileState extends State<_BackTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sizeScale;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (hasFocus) => setState(() => _focused = hasFocus),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onActivate();
          return null;
        }),
      },
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedScale(
          scale: _focused ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: InkWell(
            onTap: widget.onActivate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAB308), Color(0xFFF97316)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular((24 * s).clamp(18, 24)),
                border: Border.all(
                  color: _focused ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.1),
                  width: _focused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEAB308).withOpacity(0.4),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                  if (_focused)
                    BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 20, spreadRadius: 1),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Feather.arrow_left, size: (46 * s).clamp(36, 48), color: Colors.white),
                    SizedBox(height: (10 * s).clamp(8, 12)),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: (16 * s).clamp(14, 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: (13 * s).clamp(11, 14),
                        color: Colors.white70,
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

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}
