import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';


class SearchAndFilterSection extends StatelessWidget {
  final FocusNode searchNode;
  final String selectedCategory;
  final String selectedStockStatus;
  final List<String> categories;
  final void Function(String) onSearchChanged;
  final void Function(String?) onCategoryChanged;
  final void Function(String?) onStockStatusChanged;
  final bool isMobile;

  const SearchAndFilterSection({
    Key? key,
    required this.searchNode,
    required this.selectedCategory,
    required this.selectedStockStatus,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onStockStatusChanged,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
      child: Container(
        decoration: glassBox(),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: TextField(
                focusNode: searchNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products, barcode, or ID...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.6)),
                  prefixIcon: Icon(Feather.search, color: Colors.white.withOpacity(.7)),
                  border: InputBorder.none,
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    value: selectedCategory,
                    items: categories,
                    onChanged: onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _filterDropdown(
                    value: selectedStockStatus,
                    items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
                    onChanged: onStockStatusChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kPanelBg,
          style: const TextStyle(color: Colors.white),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }
}
