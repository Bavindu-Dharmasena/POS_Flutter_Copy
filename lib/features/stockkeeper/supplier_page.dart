import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/data/models/stockkeeper/supplier.dart';
import 'package:pos_system/data/repositories/stockkeeper/supplier_repository.dart';
import 'package:pos_system/theme/palette.dart';
import 'package:pos_system/features/stockkeeper/supplier/add_supplier_page.dart';
import 'package:pos_system/features/stockkeeper/supplier/supplier_products_page.dart';
import 'package:pos_system/widget/suppliers/supplier_card.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with TickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);

  final _scrollCtrl = ScrollController();
  final _repo = SupplierRepository.instance;

  bool _loading = true;
  String _search = '';
  String? _error;
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ac.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.all(query: _search.trim().isEmpty ? null : _search);
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load suppliers';
      });
    }
  }

  Future<void> _addSupplier() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSupplierPage(supplierData: {})));
    if (!mounted) return;
    _load();
  }

  Future<void> _editSupplier(Supplier s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSupplierPage(supplierData: {
          'id': s.id?.toString(),
          'name': s.name,
          'contact': s.contact,
          'email': s.email,
          'brand': s.brand,
          'locations': [s.location],
          'paymentTerms': s.paymentTerms,
          'active': s.status.toUpperCase() == 'ACTIVE',
          'remarks': s.notes,
          'created_at': s.createdAt,
          'gradientName': null,
        }),
      ),
    );
    if (!mounted) return;
    _load();
  }

  void _openProducts(Supplier s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierProductsPage(supplier: s.toUiCard())));
  }

  _BasePalette get _p {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const _BasePalette(bg: Color(0xFF0B1623), text: Colors.white, tileBg: Color(0xFF121A26), tileBorder: Color(0x1FFFFFFF), muted: Colors.white70)
        : const _BasePalette(bg: Color(0xFFF4F6FA), text: Color(0xFF0F172A), tileBg: Colors.white, tileBorder: Color(0x14000000), muted: Color(0xFF64748B));
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

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
      textTheme: Theme.of(context).textTheme.apply(bodyColor: p.text, displayColor: p.text),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: p.bg,
                  automaticallyImplyLeading: false,
                  leading: canPop
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(Feather.arrow_left, color: p.text, size: 20),
                          ),
                        )
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: canPop ? 72 : 16, bottom: 16),
                    centerTitle: false,
                    title: Text('Suppliers', style: TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(64),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        onChanged: (v) {
                          _search = v;
                          _load();
                        },
                        style: TextStyle(color: p.text),
                        decoration: InputDecoration(
                          hintText: 'Search by name, contact, brand, location…',
                          prefixIcon: const Icon(Feather.search),
                          filled: true,
                          fillColor: p.tileBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: p.tileBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: p.tileBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: _loading
                          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: CircularProgressIndicator()))
                          : (_error != null
                              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48.0), child: Text(_error!, style: TextStyle(color: p.muted))))
                              : (_suppliers.isEmpty
                                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48.0), child: Text('No suppliers yet. Tap “Add Supplier”.', style: TextStyle(color: p.muted))))
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _suppliers.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (_, i) {
                                        final s = _suppliers[i];
                                        return ListTileTheme(
                                          textColor: p.text,
                                          iconColor: p.text,
                                          child: SupplierCard(
                                            supplier: s.toUiCard(),
                                            isTablet: isTablet,
                                            onTap: () => _openProducts(s),
                                            onEdit: () => _editSupplier(s),
                                          ),
                                        );
                                      },
                                    ))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            color: Palette.kInfo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Palette.kInfo.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: FloatingActionButton.extended(
            onPressed: _addSupplier,
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

class _BasePalette {
  final Color bg;
  final Color text;
  final Color tileBg;
  final Color tileBorder;
  final Color muted;
  const _BasePalette({required this.bg, required this.text, required this.tileBg, required this.tileBorder, required this.muted});
}
