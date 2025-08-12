import 'package:flutter/material.dart';

class StockKeeperSetting extends StatelessWidget {
  const StockKeeperSetting({Key? key}) : super(key: key);  // Constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Keeper setting'),
        backgroundColor: const Color(0xFF0B1623),
      ),
      body: const Center(
        child: Text(
          'Welcome to Stock Keeper setting!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
