import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';

class SupplierProductsPage extends StatelessWidget {
  final Map<String, dynamic> supplier;
  const SupplierProductsPage({super.key, required this.supplier});

  // Example store. Keep keys as strings: "${supplier['id']}"
  final Map<String, List<Map<String, dynamic>>> supplierProducts = const {
    // '1': [{'name':'Item A','unit':'pc','stock':10,'salesPrice':'$12.00'}],
  };

  @override
  Widget build(BuildContext context) {
    // Neutral accent (do not read supplier color)
    final Color accent = Palette.kInfo;

    String _str(dynamic v) => v == null ? '' : v.toString().trim();
    final String sid       = _str(supplier['id']);
    final String sName     = _str(supplier['name']);
    final String sContact  = _str(supplier['contact'] ?? supplier['contactPerson']);
    final String sPhone    = _str(supplier['phone']);
    final String sEmail    = _str(supplier['email']);
    final String sLocation = _str(supplier['location']);
    final String sAddress  = _str(supplier['address']);

    final List<Map<String, dynamic>> products = supplierProducts[sid] ?? const [];

    return Scaffold(
      backgroundColor: Palette.kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
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
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                centerTitle: false,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sName.isEmpty ? 'Supplier' : sName,
                      style: const TextStyle(color: Palette.kText, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('${products.length} Products',
                        style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.withOpacity(0.1), Palette.kBg],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Palette.kSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Palette.kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(15)),
                            child: (_str(supplier['image']).isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(_str(supplier['image']), fit: BoxFit.cover),
                                  )
                                : const Icon(Feather.briefcase, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sContact.isNotEmpty)
                                  Text(sContact, style: const TextStyle(color: Palette.kText, fontSize: 16, fontWeight: FontWeight.w600)),
                                if (sLocation.isNotEmpty)
                                  Text(sLocation, style: const TextStyle(color: Palette.kTextMuted, fontSize: 14)),
                                if (sPhone.isNotEmpty)
                                  Text(sPhone, style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
                                if (sEmail.isNotEmpty)
                                  Text(sEmail, style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
                                if (sAddress.isNotEmpty)
                                  Text(sAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Products', style: TextStyle(color: Palette.kText, fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Text('${products.length} items',
                            style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // list
                    if (products.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Palette.kSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Palette.kBorder),
                        ),
                        child: const Column(
                          children: [
                            Icon(Feather.package, color: Palette.kTextMuted, size: 48),
                            SizedBox(height: 16),
                            Text('No products found',
                                style: TextStyle(color: Palette.kTextMuted, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          final String pName  = _str(p['name']);
                          final String pUnit  = _str(p['unit']);
                          final String pStock = _str(p['stock']);
                          final String pPrice = _str(p['salesPrice']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Palette.kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Palette.kBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Feather.package, color: accent, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pName.isEmpty ? 'Unnamed product' : pName,
                                          style: const TextStyle(color: Palette.kText, fontSize: 16, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (pUnit.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Palette.kInfo.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                                child: Text('per $pUnit',
                                                  style: const TextStyle(color: Palette.kInfo, fontSize: 10, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            if (pUnit.isNotEmpty) const SizedBox(width: 8),
                                            if (pStock.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Palette.kSuccess.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                                child: Text('Stock: $pStock',
                                                  style: const TextStyle(color: Palette.kSuccess, fontSize: 10, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    pPrice.isEmpty ? '-' : pPrice,
                                    style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
