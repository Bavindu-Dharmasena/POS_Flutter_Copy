import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({super.key});

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  final TextEditingController _search = TextEditingController();
  int _focusedIndex = 0;
  int _cols = 2; // updated in LayoutBuilder
  bool _compact = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Tile> get _allTiles => <_Tile>[
        _Tile('User Management', 'Change own / reset staff passwords', Icons.key, '/manager/user-management', const Color.fromARGB(255, 117, 193, 91)),
        _Tile('Sales Reports', 'Sales Summaries & revenue split', Icons.summarize, '/manager/reports/sales-summaries', Colors.blue),
        _Tile('Trending Items', 'Popular products by qty/revenue', Icons.trending_up, '/manager/reports/trending-items', Colors.green),
        _Tile('Profit Margins', 'Cash vs Card profit split', Icons.pie_chart, '/manager/reports/profit-margins', Colors.orange),
        _Tile('Creditors', 'Outstanding, history & settlements', Icons.people_alt, '/manager/reports/creditors', Colors.teal),
        _Tile('Audit Logs', 'Logins, stock edits, refunds, rules', Icons.fact_check, '/manager/audit-logs', Colors.indigo),
        _Tile('Price Rules', 'Create / schedule promos', Icons.price_change, '/manager/price-rules', Colors.pink),
        _Tile('Stock Keeper', 'Inventory, restock & POs', Icons.inventory_2, '/stockkeeper', Colors.amber),
        _Tile('Cashier', 'Invoices, payments, refunds', Icons.receipt_long, '/cashier', Colors.cyan),
        _Tile('Add Creditor', 'Create creditor record', Icons.person_add_alt_1, '/manager/create-creditor', Colors.red),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();

    final tiles = _allTiles
        .where((t) =>
            query.isEmpty ||
            t.title.toLowerCase().contains(query) ||
            t.subtitle.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Owner / Manager',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _compact ? 'Comfortable size' : 'Compact size',
            onPressed: () => setState(() => _compact = !_compact),
            icon: Icon(_compact ? Icons.grid_view_rounded : Icons.dashboard_customize_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, c) {
              // responsive columns
              final cols = c.maxWidth > 1200
                  ? 4
                  : c.maxWidth > 900
                      ? 3
                      : 2; // keep 2 on mobile
              _cols = cols;

              final isMobile = c.maxWidth < 600;
              final aspect = _compact
                  ? (isMobile ? 1.05 : 1.15)
                  : (isMobile ? 0.85 : 1.10);

              return Column(
                children: [
                  // Search + info row
                  Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: _search,
                          hint: 'Search features…',
                          onChanged: (_) => setState(() {}),
                          onClear: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        avatar: const Icon(Icons.apps, size: 18),
                        label: Text('${tiles.length}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Keyboard help
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tips: Use arrow keys to navigate • Enter to open • / to focus search',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Grid with keyboard navigation
                  Expanded(
                    child: Shortcuts(
                      shortcuts: <LogicalKeySet, Intent>{
                        // navigation
                        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _MoveIntent(Offset(1, 0)),
                        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _MoveIntent(Offset(-1, 0)),
                        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _MoveIntent(Offset(0, 1)),
                        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _MoveIntent(Offset(0, -1)),
                        // open
                        LogicalKeySet(LogicalKeyboardKey.enter): const _OpenIntent(),
                        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const _OpenIntent(),
                        // focus search quickly
                        LogicalKeySet(LogicalKeyboardKey.slash): const _FocusSearchIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          _MoveIntent: CallbackAction<_MoveIntent>(onInvoke: (intent) {
                            setState(() {
                              final row = _focusedIndex ~/ _cols;
                              final col = _focusedIndex % _cols;
                              int newRow = row + intent.delta.dy.toInt();
                              int newCol = col + intent.delta.dx.toInt();
                              if (newRow < 0) newRow = 0;
                              if (newCol < 0) newCol = 0;
                              final maxRow = (tiles.length - 1) ~/ _cols;
                              if (newRow > maxRow) newRow = maxRow;

                              // clamp by row length
                              final rowLen = (newRow == maxRow) ? ((tiles.length - 1) % _cols) + 1 : _cols;
                              if (newCol >= rowLen) newCol = rowLen - 1;

                              _focusedIndex = (newRow * _cols) + newCol;
                            });
                            return null;
                          }),
                          _OpenIntent: CallbackAction<_OpenIntent>(onInvoke: (intent) {
                            if (tiles.isEmpty) return null;
                            final t = tiles[_focusedIndex.clamp(0, tiles.length - 1)];
                            Navigator.pushNamed(context, t.route);
                            return null;
                          }),
                          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) {
                            FocusScope.of(context).requestFocus(_searchFocusNode);
                            return null;
                          }),
                        },
                        child: Focus(
                          autofocus: true,
                          child: GridView.builder(
                            itemCount: tiles.length,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: aspect,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, i) {
                              final t = tiles[i];
                              final focused = i == _focusedIndex;
                              return _ManagerCard(
                                title: t.title,
                                subtitle: t.subtitle,
                                icon: t.icon,
                                color: t.color,
                                focused: focused,
                                onTap: () => Navigator.pushNamed(context, t.route),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  final FocusNode _searchFocusNode = FocusNode();
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  const _SearchField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: FocusNode(),
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: controller.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  final Offset delta;
  const _MoveIntent(this.delta);
}

class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _Tile {
  final String title, subtitle, route;
  final IconData icon;
  final Color color;
  _Tile(this.title, this.subtitle, this.icon, this.route, this.color);
}

class _ManagerCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool focused;
  final VoidCallback onTap;

  const _ManagerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.focused,
  });

  @override
  State<_ManagerCard> createState() => _ManagerCardState();
}

class _ManagerCardState extends State<_ManagerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 140), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pressDown() {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _pressUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Semantics(
      label: widget.title,
      hint: 'Open ${widget.title}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _pressDown(),
        onTapUp: (_) {
          _pressUp();
          widget.onTap();
        },
        onTapCancel: _pressUp,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [widget.color.withOpacity(0.85), widget.color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.28),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 6),
                    ),
                  ],
                  border: widget.focused
                      ? Border.all(color: Colors.white, width: 2) // visible focus ring
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: widget.onTap,
                    splashColor: Colors.white.withOpacity(0.30),
                    highlightColor: Colors.white.withOpacity(0.10),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: widget.title,
                            child: Container(
                              padding: EdgeInsets.all(isMobile ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(widget.icon, size: isMobile ? 28 : 36, color: Colors.white),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isMobile ? 2 : 4),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
