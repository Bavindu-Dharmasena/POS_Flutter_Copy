import 'package:flutter/material.dart';

class EditProductButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditProductButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent, // button color
        foregroundColor: Colors.white, // text/icon color
        minimumSize: const Size(150, 50), // button size
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rounded corners
        ),
        elevation: 6, // shadow
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.edit, size: 22),
      label: const Text(
        "Edit Product",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
