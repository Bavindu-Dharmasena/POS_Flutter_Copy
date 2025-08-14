import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

class ProductActionsSheet extends StatelessWidget {
  final Product product;

  const ProductActionsSheet({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _actionTile(
              icon: Feather.eye,
              title: 'View Details',
              onTap: () {
                Navigator.pop(context);
                // Optionally: show details dialog
              },
            ),
            _actionTile(
              icon: Feather.edit_2,
              title: 'Edit Product',
              onTap: () {
                Navigator.pop(context);
                // Optionally: show edit dialog
              },
            ),
            _actionTile(
              icon: Feather.trending_up,
              title: 'Adjust Stock',
              onTap: () {
                Navigator.pop(context);
                // Optionally: show adjust stock dialog
              },
            ),
            _actionTile(
              icon: Feather.copy,
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                // Optionally: duplicate product
              },
            ),
            _actionTile(
              icon: Feather.trash_2,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                // Optionally: confirm and delete
              },
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: actionColor, size: 20),
      title: Text(title, style: TextStyle(color: actionColor, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      dense: true,
    );
  }

  // NOTE: The action sheet's full content would be copied here.
}
