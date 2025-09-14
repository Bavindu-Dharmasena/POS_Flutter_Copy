import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final FocusNode? focusNode;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onMore,
    this.focusNode,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  bool _isHovered = false;
  
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.02,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));


  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode?.hasFocus ?? false) {
      if (mounted) setState(() => _focused = true);
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 140),
        alignment: 0.1,
      );
    } else {
      if (mounted) setState(() => _focused = false);
    }
  }

  BoxDecoration _modernGlassBox() {
    final product = widget.product;
    final isOutOfStock = product.currentStock == 0;
    final isLowStock = product.isLowStock;
    
    // Determine accent color based on stock status
    Color accentColor = Colors.blue[400]!;
    if (isOutOfStock) {
      accentColor = Colors.red[400]!;
    } else if (isLowStock) accentColor = Colors.orange[400]!;
    else accentColor = Colors.green[400]!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(_isHovered || _focused ? 0.15 : 0.08),
          Colors.white.withOpacity(_isHovered || _focused ? 0.08 : 0.03),
        ],
      ),
      border: Border.all(
        color: _focused
            ? accentColor.withOpacity(0.6)
            : (_isHovered ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
        width: _focused ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_isHovered || _focused ? 0.3 : 0.2),
          blurRadius: _isHovered || _focused ? 25 : 15,
          offset: Offset(0, _isHovered || _focused ? 12 : 8),
          spreadRadius: _isHovered || _focused ? 2 : 0,
        ),
        if (_focused || _isHovered)
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _ctrl.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _ctrl.reverse();
        },
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: _modernGlassBox(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth < 420
                          ? _mobile(widget.product)
                          : _desktop(widget.product);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(Product p) => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        _modernThumb(p),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                p.category,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(child: _modernStockBadge(p)),
                  const SizedBox(width: 12),
                  _priceTag(p),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _modernMoreButton(Feather.more_vertical),
      ],
    ),
  );

  Widget _desktop(Product p) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _modernThumb(p),
            const Spacer(),
            _modernMoreButton(Feather.more_horizontal),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          p.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          p.category,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _modernStockBadge(p),
        const SizedBox(height: 12),
        _priceTag(p),
      ],
    ),
  );

  Widget _modernThumb(Product p) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      gradient: p.image != null 
          ? null 
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[400]!.withOpacity(0.8),
                Colors.purple[400]!.withOpacity(0.8),
              ],
            ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: (p.image != null ? Colors.black : Colors.blue[400]!).withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: p.image != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(p.image!, fit: BoxFit.cover),
          )
        : Icon(
            Feather.package,
            color: Colors.white,
            size: 24,
          ),
  );

  Widget _modernStockBadge(Product p) {
    Color badgeColor;
    Color bgColor;
    String text;
    IconData icon;
    
    if (p.currentStock == 0) {
      badgeColor = Colors.red[400]!;
      bgColor = Colors.red[400]!.withOpacity(0.15);
      text = 'Out of Stock';
      icon = Icons.remove_circle_outline;
    } else if (p.isLowStock) {
      badgeColor = Colors.orange[400]!;
      bgColor = Colors.orange[400]!.withOpacity(0.15);
      text = 'Low Stock (${p.currentStock})';
      icon = Icons.warning_rounded;
    } else {
      badgeColor = Colors.green[400]!;
      bgColor = Colors.green[400]!.withOpacity(0.15);
      text = 'In Stock (${p.currentStock})';
      icon = Icons.check_circle_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: badgeColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceTag(Product p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue[400]!, Colors.purple[400]!],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[400]!.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.currency_rupee,
          color: Colors.white,
          size: 14,
        ),
        const SizedBox(width: 2),
        Text(
          p.price.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _modernMoreButton(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onMore,
        borderRadius: BorderRadius.circular(12),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 18,
        ),
      ),
    ),
  );
}