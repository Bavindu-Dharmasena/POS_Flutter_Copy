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
    Key? key,
    required this.product,
    required this.onTap,
    required this.onMore,
    this.focusNode,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.03,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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

  // Add the glassBox function locally
  BoxDecoration _glassBox({
    double radius = 16,
    double borderOpacity = .10,
    double fillOpacity = .08,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1,
      ),
      color: Colors.white.withOpacity(fillOpacity),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(.10), Colors.white.withOpacity(.02)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.35),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final borderColor = product.currentStock == 0
        ? Colors.red
        : (product.isLowStock ? Colors.orange : Colors.white);

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
        onEnter: (_) => _ctrl.forward(),
        onExit: (_) => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value * (_focused ? 1.02 : 1.0),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: _glassBox(radius: 16).copyWith(
                  border: Border.all(
                    color: _focused
                        ? Colors.white.withOpacity(0.95)
                        : borderColor.withOpacity(0.3),
                    width: _focused ? 2.6 : 1.5,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth < 420
                        ? _mobile(product)
                        : _desktop(product);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(Product p) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        _thumb(p),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                p.category,
                style: TextStyle(
                  color: Colors.white.withOpacity(.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _stockBadge(p),
                  const Spacer(),
                  Text(
                    'Rs. ${p.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onMore,
          icon: const Icon(Feather.more_vertical, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _desktop(Product p) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _thumb(p),
            const Spacer(),
            IconButton(
              onPressed: widget.onMore,
              icon: const Icon(Feather.more_horizontal, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(p.category, style: TextStyle(color: Colors.white.withOpacity(.7))),
        const Spacer(),
        _stockBadge(p),
        const SizedBox(height: 8),
        Text(
          'Rs. ${p.price.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );

  Widget _thumb(Product p) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: p.image != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(p.image!, fit: BoxFit.cover),
          )
        : const Icon(Feather.package),
  );

  Widget _stockBadge(Product p) {
    Color badgeColor;
    String text;
    if (p.currentStock == 0) {
      badgeColor = Colors.red;
      text = 'Out of Stock';
    } else if (p.isLowStock) {
      badgeColor = Colors.orange;
      text = 'Low Stock (${p.currentStock})';
    } else {
      badgeColor = Colors.green;
      text = 'In Stock (${p.currentStock})';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
