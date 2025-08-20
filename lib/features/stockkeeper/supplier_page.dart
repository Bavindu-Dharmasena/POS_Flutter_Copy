import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';
import 'package:pos_system/features/stockkeeper/supplier/supplier_products_page.dart';
import 'package:pos_system/widget/suppliers/supplier_card.dart';
import 'package:pos_system/widget/suppliers/supplier_edit_dialog.dart';
import 'package:pos_system/features/stockkeeper/supplier/add_supplier_page.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with TickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;

  final List<Map<String, dynamic>> suppliers = [
    {
      'id': '1','name': 'ABC Traders','location': 'Colombo','image': 'assets/images/maliban.webp',
      'phone': '+94 11 234 5678','email': 'contact@abctraders.lk','address': '123 Main Street, Colombo 01',
      'contactPerson': 'John Silva','status': 'Active','color': const Color(0xFF3B82F6),
    },
    {
      'id': '2','name': 'XYZ Distributors','location': 'Kandy',
      'phone': '+94 81 987 6543','email': 'info@xyzdist.lk','address': '456 Hill Road, Kandy',
      'contactPerson': 'Maria Fernando','status': 'Active','color': const Color(0xFF10B981),
    },
    {
      'id': '3','name': 'Quick Supplies','location': 'Galle','image': 'assets/images/cadbury.webp',
      'phone': '+94 91 123 4567','email': 'orders@quicksupplies.lk','address': '789 Beach Road, Galle',
      'contactPerson': 'David Perera','status': 'Active','color': const Color(0xFFF97316),
    },
    {
      'id': '4','name': 'SuperMart Pvt Ltd','location': 'Jaffna',
      'phone': '+94 21 555 0123','email': 'business@supermart.lk','address': '321 North Street, Jaffna',
      'contactPerson': 'Raj Kumar','status': 'Inactive','color': const Color(0xFFEC4899),
    },
    {
      'id': '5','name': 'Wholesale Hub','location': 'Negombo',
      'phone': '+94 31 777 8899','email': 'hub@wholesale.lk','address': '654 Market Street, Negombo',
      'contactPerson': 'Sarah De Silva','status': 'Active','color': const Color(0xFF6366F1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _openProducts(Map<String, dynamic> s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierProductsPage(supplier: s)));
  }

  void _editSupplier(Map<String, dynamic> s) {
    showSupplierEditDialog(
      context: context,
      supplier: s,
      onSave: (updated) {
        setState(() {
          final idx = suppliers.indexWhere((e) => e['id'] == updated['id']);
          if (idx != -1) suppliers[idx] = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (e) {
        if (e is RawKeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Palette.kBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                backgroundColor: Palette.kBg,
                automaticallyImplyLeading: false,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Palette.kBg, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Feather.arrow_left, color: Palette.kText, size: 20),
                  ),
                ),
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 72, bottom: 16),
                  centerTitle: false,
                  title: Text('Suppliers', style: TextStyle(color: Palette.kText, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suppliers.length,
                      itemBuilder: (_, i) {
                        final s = suppliers[i];
                        return SupplierCard(
                          supplier: s,
                          isTablet: isTablet,
                          onTap: () => _openProducts(s), // tap whole card -> products
                          onEdit: () => _editSupplier(s), // only Edit button present
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            color: Palette.kInfo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Palette.kInfo.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,4))],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AddSupplierPage(supplierData: {}),
              ));
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Feather.plus, color: Colors.white, size: 20),
            label: Text('Add Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 17 : 16)),
          ),
        ),
      ),
    );
  }
}
