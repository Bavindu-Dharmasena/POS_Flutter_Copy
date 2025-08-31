// lib/utils/navigation_utils.dart
import 'package:flutter/material.dart';

class NavigationUtils {
  NavigationUtils._();

  static Future<bool> confirmLeave(BuildContext context, bool isDirty) async {
    if (!isDirty) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Discard changes?'),
          ],
        ),
        content: const Text('You have unsaved changes. Do you really want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}