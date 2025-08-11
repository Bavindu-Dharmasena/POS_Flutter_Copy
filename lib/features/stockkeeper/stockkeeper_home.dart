import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/features/cashier/cashier_view_page.dart';

import '../stockkeeper/stockkeeper_dashboard.dart';
import '../stockkeeper/stockkeeper_products.dart';
import '../stockkeeper/stockkeeper_inventory.dart';
import '../stockkeeper/stockkeeper_reports.dart';
import '../stockkeeper/stockkeeper_cashier.dart';
import '../stockkeeper/stockkeeper_more.dart';

/// Custom intents for extra keyboard actions
class JumpToFirstIntent extends Intent { const JumpToFirstIntent(); }
class JumpToLastIntent extends Intent { const JumpToLastIntent(); }
class BackIntent extends Intent { const BackIntent(); }

class StockKeeperHome extends StatefulWidget {
  const StockKeeperHome({super.key});

  @override
  State<StockKeeperHome> createState() => _StockKeeperHomeState();
}

class _StockKeeperHomeState extends State<StockKeeperHome> {
  // Tiles the user can reorder
  late List<_TileSpec> _tiles;

  // Focus management (mirrors tile order)
  final List<FocusNode> _tileNodes = [];
  int _focusedIndex = 0;

  // While dragging, store the source index to style the item
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _tiles = [
      _TileSpec(
        id: 'dashboard',
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
        id: 'products',
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
        id: 'inventory',
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
        id: 'reports',
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
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Billing & Payments',
        icon: Icons.receipt_long_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        pageBuilder: () => const CashierViewPage(),
      ),
      _TileSpec(
        id: 'settings',
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
        id: 'back',
        title: 'Back',
        subtitle: 'Go Back',
        icon: Icons.arrow_back_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFF97316)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.of(context).maybePop(),
      ),
    ];
    _ensureNodes(_tiles.length, requestFirstFocus: true);
  }

  // Ensure we have exactly [count] focus nodes; optionally focus first
  void _ensureNodes(int count, {bool requestFirstFocus = false}) {
    while (_tileNodes.length > count) {
      _tileNodes.removeLast().dispose();
    }
    while (_tileNodes.length < count) {
      _tileNodes.add(FocusNode(debugLabel: 'tile_${_tileNodes.length}'));
    }
    if (requestFirstFocus && _tileNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusedIndex = _focusedIndex.clamp(0, _tileNodes.length - 1);
        if (!_tileNodes[_focusedIndex].hasFocus) {
          _tileNodes[_focusedIndex].requestFocus();
        }
      });
    }
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

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(position: a.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Fixed reorder method with proper bounds checking
  void _reorder(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= _tiles.length || to >= _tiles.length) {
      return;
    }

    final FocusNode? focusedNode = (_tileNodes.isNotEmpty && _focusedIndex < _tileNodes.length) 
        ? _tileNodes[_focusedIndex] : null;

    setState(() {
      // Reorder tiles
      final item = _tiles.removeAt(from);
      _tiles.insert(to, item);

      // Reorder focus nodes
      final node = _tileNodes.removeAt(from);
      _tileNodes.insert(to, node);

      // Update focused index
      if (focusedNode != null) {
        final idx = _tileNodes.indexOf(focusedNode);
        if (idx != -1) {
          _focusedIndex = idx;
        }
      }
    });

    // Request focus after the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tileNodes.isNotEmpty && _focusedIndex < _tileNodes.length) {
        _tileNodes[_focusedIndex].requestFocus();
      }
    });
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

            // Main content with ReorderableGridView
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final crossAxisCount = isWide ? 4 : 2;

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
                              }
                              final next = _nextIndex(
                                current: _focusedIndex,
                                cols: crossAxisCount,
                                count: _tiles.length,
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
                            onInvoke: (_) { _focusAt(_tiles.length - 1); return null; },
                          ),
                          BackIntent: CallbackAction<BackIntent>(
                            onInvoke: (_) { Navigator.maybePop(context); return null; },
                          ),
                        },
                        child: FocusTraversalGroup(
                          policy: ReadingOrderTraversalPolicy(),
                          child: CustomScrollView(
                            slivers: [
                              SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index >= _tiles.length) return null;
                                    return _DraggableGridTile(
                                      key: ValueKey(_tiles[index].id),
                                      index: index,
                                      isDragging: _draggingIndex == index,
                                      focusNode: _tileNodes.length > index ? _tileNodes[index] : null,
                                      tile: _tiles[index],
                                      onActivate: () {
                                        final t = _tiles[index];
                                        if (t.onTap != null) t.onTap!();
                                        else if (t.pageBuilder != null) _navigateTo(context, t.pageBuilder!());
                                      },
                                      onDragStarted: () => setState(() => _draggingIndex = index),
                                      onDragEnded: () => setState(() => _draggingIndex = null),
                                      onAccept: (from) => _reorder(from, index),
                                    );
                                  },
                                  childCount: _tiles.length,
                                ),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: isWide ? 24 : 20,
                                  mainAxisSpacing: isWide ? 24 : 20,
                                  childAspectRatio: isWide ? 1.2 : 1.0,
                                ),
                              ),
                              // Add coming soon box for wide screens
                              if (isWide)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: SizedBox(
                                      height: 200,
                                      child: _comingSoonBox(),
                                    ),
                                  ),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_outlined, color: Colors.white54, size: 24),
            SizedBox(height: 12),
            Text('Coming Soon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54)),
            SizedBox(height: 4),
            Text('New Features', style: TextStyle(fontSize: 13, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

/* -------------------- Data model -------------------- */
class _TileSpec {
  final String id; // stable key for reordering
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Widget Function()? pageBuilder;
  final VoidCallback? onTap;

  _TileSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.pageBuilder,
    this.onTap,
  });
}

/* -------------------- Enhanced DragTarget + Draggable wrapper -------------------- */
class _DraggableGridTile extends StatefulWidget {
  final int index;
  final bool isDragging;
  final _TileSpec tile;
  final FocusNode? focusNode;
  final VoidCallback onActivate;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final ValueChanged<int> onAccept;

  const _DraggableGridTile({
    super.key,
    required this.index,
    required this.isDragging,
    required this.tile,
    required this.onActivate,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAccept,
    this.focusNode,
  });

  @override
  State<_DraggableGridTile> createState() => _DraggableGridTileState();
}

class _DraggableGridTileState extends State<_DraggableGridTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Enhanced DragTarget with better visual feedback
    return DragTarget<int>(
      onWillAccept: (from) => from != null && from != widget.index,
      onAccept: (from) {
        setState(() => _isHovering = false);
        widget.onAccept(from);
      },
      onMove: (details) => setState(() => _isHovering = true),
      onLeave: (data) => setState(() => _isHovering = false),
      builder: (context, candidateData, rejected) {
        final isReceiving = candidateData.isNotEmpty || _isHovering;
        
        // Enhanced Draggable with better feedback
        return Draggable<int>(
          data: widget.index,
          onDragStarted: widget.onDragStarted,
          onDragEnd: (details) {
            widget.onDragEnded();
            setState(() => _isHovering = false);
          },
          // Improved feedback widget
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 0.8, // Slightly smaller feedback
              child: Container(
                width: 150, // Fixed width for feedback
                height: 150, // Fixed height for feedback
                child: _TileBody(
                  tile: widget.tile,
                  focusNode: null,
                  elevate: true,
                  receiving: false,
                  isDragging: true,
                ),
              ),
            ),
          ),
          // More transparent when dragging
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _TileBody(
              tile: widget.tile,
              focusNode: widget.focusNode,
              elevate: false,
              receiving: false,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: isReceiving ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: _TileBody(
              tile: widget.tile,
              focusNode: widget.focusNode,
              elevate: !widget.isDragging,
              receiving: isReceiving,
              onActivate: widget.onActivate,
            ),
          ),
        );
      },
    );
  }
}

/* -------------------- Enhanced visual tile -------------------- */
class _TileBody extends StatefulWidget {
  final _TileSpec tile;
  final FocusNode? focusNode;
  final bool elevate;
  final bool receiving;
  final bool isDragging;
  final VoidCallback? onActivate;

  const _TileBody({
    required this.tile,
    this.focusNode,
    this.elevate = true,
    this.receiving = false,
    this.isDragging = false,
    this.onActivate,
  });

  @override
  State<_TileBody> createState() => _TileBodyState();
}

class _TileBodyState extends State<_TileBody> with SingleTickerProviderStateMixin {
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
    final tile = widget.tile;

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
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) { 
            _controller.reverse(); 
            widget.onActivate?.call(); 
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double scaleBump = _focused ? 1.03 : 1.0;
              return Transform.scale(
                scale: _scaleAnimation.value * scaleBump,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: tile.gradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (widget.elevate)
                          BoxShadow(
                            color: tile.gradient.colors.first.withOpacity(0.4),
                            offset: const Offset(0, 8),
                            blurRadius: 16,
                            spreadRadius: _controller.value * 2,
                          ),
                        if (_focused || widget.receiving)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25), 
                            blurRadius: 20, 
                            spreadRadius: 1
                          ),
                      ],
                      border: Border.all(
                        color: (_focused || widget.receiving)
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.1),
                        width: (_focused || widget.receiving) ? 2 : 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.0)],
                          begin: Alignment.topLeft, 
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Enhanced drag hint with better visibility
                          if (!widget.isDragging) // Hide drag hint when dragging
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Opacity(
                                opacity: 0.8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.drag_indicator, 
                                    size: 18, 
                                    color: Colors.white70
                                  ),
                                ),
                              ),
                            ),
                          // Content
                          Center(
                            child: Semantics(
                              button: true,
                              label: tile.title,
                              hint: 'Long-press to drag. Press Enter to open ${tile.title}',
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
                                    child: Icon(tile.icon, size: 32, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tile.title,
                                    style: const TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.white
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tile.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13, 
                                      color: Colors.white70, 
                                      fontWeight: FontWeight.w500
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  @override
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  }
}