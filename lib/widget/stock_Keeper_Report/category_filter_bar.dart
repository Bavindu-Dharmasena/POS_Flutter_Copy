import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = selectedCategory == category;
            return GestureDetector(
              onTap: () => onCategorySelected(category),
              child: Container(
                margin: EdgeInsets.only(right: isMobile ? 8 : 12),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getCategoryIcon(category),
                      color: isSelected ? Colors.blue[700] : Colors.grey[600],
                      size: isMobile ? 16 : 18,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isMobile ? 50 : 60);
}