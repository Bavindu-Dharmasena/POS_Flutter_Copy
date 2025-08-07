import 'package:flutter/material.dart';

class AddSupplierPage extends StatelessWidget {
  const AddSupplierPage({Key? key}) : super(key: key);  // Constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Supplier'),
        backgroundColor: const Color(0xFF0B1623),
      ),
      body: const Center(
        child: Text(
          'Welcome to Add Supplier Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
