import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class TotalItems extends StatefulWidget {
  const TotalItems({Key? key}) : super(key: key);

  @override
  State<TotalItems> createState() => _TotalItemsState();
}

class _TotalItemsState extends State<TotalItems> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Items'),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: cs.surface, // empty page background
        child: Center(
          child: Text(
            'No content yet',
            style: TextStyle(
              color: cs.onSurface.withOpacity(.7),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
