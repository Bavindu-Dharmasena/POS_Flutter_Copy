import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class SearchAndFilterSection extends StatefulWidget {
  final FocusNode searchNode;
  final String selectedCategory;
  final String selectedStockStatus;
  final List<String> categories;
  final void Function(String) onSearchChanged;
  final void Function(String?) onCategoryChanged;
  final void Function(String?) onStockStatusChanged;
  final bool isMobile;

  const SearchAndFilterSection({
    super.key,
    required this.searchNode,
    required this.selectedCategory,
    required this.selectedStockStatus,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onStockStatusChanged,
    required this.isMobile,
  });

  @override
  State<SearchAndFilterSection> createState() => _SearchAndFilterSectionState();
}

class _SearchAndFilterSectionState extends State<SearchAndFilterSection>
    with SingleTickerProviderStateMixin {
  bool _isSearchFocused = false;
  late AnimationController _animationController;
  late Animation<double> _searchScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _searchScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    widget.searchNode.addListener(() {
      setState(() {
        _isSearchFocused = widget.searchNode.hasFocus;
      });
      if (_isSearchFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildFiltersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchScaleAnimation.value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(_isSearchFocused ? 0.15 : 0.08),
                  Colors.white.withOpacity(_isSearchFocused ? 0.08 : 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchFocused
                    ? Colors.blue[400]!.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
                width: _isSearchFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isSearchFocused
                      ? Colors.blue[400]!.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isSearchFocused ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              focusNode: widget.searchNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search products, barcode, or ID...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.purple[400]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Feather.search,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                suffixIcon: _isSearchFocused
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () {
                          widget.searchNode.unfocus();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        widget.isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        _modernFilterDropdown(
          value: widget.selectedCategory,
          items: widget.categories,
          onChanged: widget.onCategoryChanged,
          icon: Icons.category_outlined,
          label: 'Category',
        ),
        const SizedBox(height: 12),
        _modernFilterDropdown(
          value: widget.selectedStockStatus,
          items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
          onChanged: widget.onStockStatusChanged,
          icon: Icons.inventory_outlined,
          label: 'Stock Status',
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        Expanded(
          child: _modernFilterDropdown(
            value: widget.selectedCategory,
            items: widget.categories,
            onChanged: widget.onCategoryChanged,
            icon: Icons.category_outlined,
            label: 'Category',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _modernFilterDropdown(
            value: widget.selectedStockStatus,
            items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
            onChanged: widget.onStockStatusChanged,
            icon: Icons.inventory_outlined,
            label: 'Stock Status',
          ),
        ),
      ],
    );
  }

  Widget _modernFilterDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
    required String label,
  }) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'In Stock':
          return Colors.green[400]!;
        case 'Low Stock':
          return Colors.orange[400]!;
        case 'Out of Stock':
          return Colors.red[400]!;
        default:
          return Colors.blue[400]!;
      }
    }

    final isStockFilter = items.contains('In Stock');
    final statusColor = isStockFilter ? getStatusColor(value) : Colors.blue[400]!;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != 'All' && value != widget.categories.first
              ? statusColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: value != 'All' && value != widget.categories.first
            ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
            items: items.map((item) {
              final itemColor = isStockFilter ? getStatusColor(item) : Colors.white;
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    if (isStockFilter && item != 'All') ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: itemColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            selectedItemBuilder: (context) {
              return items.map((item) {
                return Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: value != 'All' && value != widget.categories.first
                              ? statusColor
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}