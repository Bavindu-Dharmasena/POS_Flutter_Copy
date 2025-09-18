// lib/features/stockkeeper/supplier_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pos_system/data/models/stockkeeper/supplier_model.dart' as model;
import 'package:pos_system/data/models/stockkeeper/supplier_db_maps.dart'; // for toUiMap()
import 'package:pos_system/data/repositories/stockkeeper/supplier_repository.dart';
import 'package:pos_system/theme/palette.dart';

// Pages
import 'package:pos_system/features/stockkeeper/supplier/add_supplier_page.dart';
import 'package:pos_system/features/stockkeeper/supplier/supplier_products_page.dart';

// alias the supplier card import
import 'package:pos_system/widget/suppliers/supplier_card.dart' as cards;

// Secure Storage Service
import 'package:pos_system/core/services/secure_storage_service.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _repo = SupplierRepository.instance;
  final _searchCtrl = TextEditingController();
  int? userId;  // Store the logged-in user's ID

  Future<List<model.Supplier>>? _future;

  @override
  void initState() {
    super.initState();
    _loadUserId();  // Load the userId when the page is initialized
    _future = _repo.getAll(); // initial load
  }

  // Function to load the userId from secure storage
  Future<void> _loadUserId() async {
    final storedUserId = await SecureStorageService.instance.getUserId();
    setState(() {
      userId = storedUserId != null ? int.tryParse(storedUserId) : null;
    });
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

  Future<void> _reloadKeepingSearch() async {
    final q = _searchCtrl.text.trim();
    setState(() {
      _future = _repo.getAll(q: q.isEmpty ? null : q);
    });
  }

  Future<void> _openAddSupplier() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddSupplierPage(supplierData: {}), // add mode
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    if (result != null) await _reloadKeepingSearch();
  }

  Future<void> _openEditSupplier(model.Supplier s) async {
    // Build a map with the keys AddSupplierPage reads in initState
    final editData = {
      'id': s.id,
      'name': s.name,
      'contact': s.contact,
      'phone': s.contact,
      'email': s.email,
      'brand': s.brand,
      'location': s.location,
      'locations': [s.location],
      'paymentTerms': s.paymentTerms,
      'status': s.status,
      'notes': s.notes,
      'created_at': s.createdAt,
    };

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddSupplierPage(supplierData: editData),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    if (result != null) await _reloadKeepingSearch();
  }

  Future<void> _openProducts(model.Supplier s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierProductsPage(supplier: s.toUiMap()),
      ),
    );
    // optional: no refresh needed here
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await SecureStorageService.instance.clear(); // Clear secure storage
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // Replace with your login route name
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
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
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: Colors.white,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSupplier,        // ✅ wired
        backgroundColor: Palette.kInfo,
        icon: const Icon(Feather.plus, color: Colors.white),
        label: const Text('Add Supplier', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // User ID display
          if (userId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'User ID: $userId',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          
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
                      supplier: s.toUiMap(), // safe map for card
                      isTablet: isTablet,
                      onTap: () => _openProducts(s),     // ✅ view products
                      onEdit: () => _openEditSupplier(s), // ✅ edit
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