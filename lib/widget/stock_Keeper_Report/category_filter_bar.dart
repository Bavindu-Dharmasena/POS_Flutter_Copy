import 'package:flutter/material.dart';

class CategoryFilterBar extends StatefulWidget implements PreferredSizeWidget {
  final String selectedCategory;
  final List<String> categories;
  final IconData Function(String) getCategoryIcon;
  final ValueChanged<String> onCategorySelected;
  final bool isMobile;

  const CategoryFilterBar({
    Key? key,
    required this.selectedCategory,
    required this.categories,
    required this.getCategoryIcon,
    required this.onCategorySelected,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();

  @override
  Size get preferredSize => Size.fromHeight(isMobile ? 72 : 80);
}

class _CategoryFilterBarState extends State<CategoryFilterBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutExpo,
    );
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 20),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 12,
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF0F0F0),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 16 : 24,
                    vertical: widget.isMobile ? 12 : 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 12),
                      _buildCategoryChips(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: widget.isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Categories',
          style: TextStyle(
            fontSize: widget.isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Text(
          '${widget.categories.length} available',
          style: TextStyle(
            fontSize: widget.isMobile ? 11 : 12,
            color: isDark ? Colors.white54 : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: widget.categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return _buildAnimatedChip(category, index, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildAnimatedChip(String category, int index, bool isDark) {
    final isSelected = widget.selectedCategory == category;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Container(
            margin: EdgeInsets.only(
              right: widget.isMobile ? 8 : 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onCategorySelected(category),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 16 : 20,
                    vertical: widget.isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isDark
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          widget.getCategoryIcon(category),
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                          size: widget.isMobile ? 16 : 18,
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 8 : 10),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white
                                  : const Color(0xFF374151),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: widget.isMobile ? 13 : 14,
                          letterSpacing: -0.2,
                        ),
                        child: Text(category),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: widget.isMobile ? 6 : 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}