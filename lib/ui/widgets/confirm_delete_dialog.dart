import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String name;
  const ConfirmDeleteDialog({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete item'),
      content: Text('Are you sure you want to delete “$name”?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
