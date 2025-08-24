import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/theme/palette.dart'; // keep for your accent colors (e.g., kInfo)
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

  // ===== dynamic base + tile palette (follows app theme) =====
  _BasePalette get _p {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _BasePalette(
        bg: Color(0xFF0B1623),      // dark page background (your style)
        text: Colors.white,
        tileBg: Color(0xFF121A26),  // dark tile/card background from your design
        tileBorder: Color(0x1FFFFFFF), // subtle white border
        muted: Colors.white70,
      );
    }
    return const _BasePalette(
      bg: Color(0xFFF4F6FA),        // soft light background
      text: Color(0xFF0F172A),      // near-slate-900
      tileBg: Colors.white,         // light card background
      tileBorder: Color(0x14000000),// subtle dark border
      muted: Color(0xFF64748B),     // slate-500-ish
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final p = _p;

    // A local Theme override so tiles/cards inherit the right colors without
    // touching your accent Palette.* colors.
    final themed = Theme.of(context).copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.tileBg,
      cardTheme: Theme.of(context).cardTheme.copyWith(
        color: p.tileBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.tileBorder),
        ),
      ),
      dividerColor: p.tileBorder,
      iconTheme: Theme.of(context).iconTheme.copyWith(color: p.text),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: p.text,
            displayColor: p.text,
          ),
    );

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (e) {
        if (e is RawKeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
        }
      },
      child: Theme(
        data: themed,
        child: Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  pinned: true,
                  backgroundColor: p.bg,
                  automaticallyImplyLeading: false,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Feather.arrow_left, color: p.text, size: 20),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                    centerTitle: false,
                    title: Text(
                      'Suppliers',
                      style: TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final s = suppliers[i];

                          // Wrap each tile with ListTileTheme + IconTheme so text/icons
                          // inside your SupplierCard also pick the correct colors.
                          return ListTileTheme(
                            textColor: p.text,
                            iconColor: p.text,
                            child: IconTheme(
                              data: IconThemeData(color: p.text),
                              child: SupplierCard(
                                supplier: s,
                                isTablet: isTablet,
                                onTap: () => _openProducts(s),
                                onEdit: () => _editSupplier(s),
                              ),
                            ),
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
              color: Palette.kInfo, // your accent color (unchanged)
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
              label: Text(
                'Add Supplier',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 17 : 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// simple holder for theme-driven base + tile colors
class _BasePalette {
  final Color bg;
  final Color text;
  final Color tileBg;
  final Color tileBorder;
  final Color muted;
  const _BasePalette({
    required this.bg,
    required this.text,
    required this.tileBg,
    required this.tileBorder,
    required this.muted,
  });
}
