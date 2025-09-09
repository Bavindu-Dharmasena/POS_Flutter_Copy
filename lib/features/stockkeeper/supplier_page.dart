import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/data/models/stockkeeper/supplier_model.dart' as model;
import 'package:pos_system/data/models/stockkeeper/supplier_db_maps.dart'; // for toUiMap()
import 'package:pos_system/data/repositories/stockkeeper/supplier_repository.dart';
import 'package:pos_system/theme/palette.dart';

// alias the supplier card import
import 'package:pos_system/widget/suppliers/supplier_card.dart' as cards;

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _repo = SupplierRepository.instance;
  final _searchCtrl = TextEditingController();

  Future<List<model.Supplier>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getAll(); // load all suppliers initially
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    setState(() {
      final query = q.trim();
      _future = _repo.getAll(q: query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: Palette.kBg,
      appBar: AppBar(
        backgroundColor: Palette.kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Suppliers', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {/* TODO: open add */},
        backgroundColor: Palette.kInfo,
        icon: const Icon(Feather.plus, color: Colors.white),
        label: const Text('Add Supplier', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _runSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, contact, brand, location…',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Feather.search, color: Colors.white70),
                filled: true,
                fillColor: Palette.kSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Palette.kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Palette.kInfo),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: FutureBuilder<List<model.Supplier>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load suppliers:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final data = snap.data ?? const <model.Supplier>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No suppliers yet', style: TextStyle(color: Colors.white70)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = data[i];
                    return cards.SupplierCard(
                      supplier: s.toUiMap(), // safe, colorless map
                      isTablet: isTablet,
                      onTap: () {/* TODO: open products */},
                      onEdit: () {/* TODO: open edit */},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
