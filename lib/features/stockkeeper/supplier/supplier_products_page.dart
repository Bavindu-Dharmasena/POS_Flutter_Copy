import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';

class SupplierProductsPage extends StatelessWidget {
  final Map<String, dynamic> supplier;
  const SupplierProductsPage({super.key, required this.supplier});

  final Map<String, List<Map<String, dynamic>>> supplierProducts = const {
    '1': [
      {'name': 'Rice - Basmati', 'unit': 'kg', 'salesPrice': 'Rs. 450.00', 'stock': 150},
      {'name': 'Sugar - White', 'unit': 'kg', 'salesPrice': 'Rs. 180.00', 'stock': 200},
      {'name': 'Oil - Coconut', 'unit': 'liter', 'salesPrice': 'Rs. 850.00', 'stock': 80},
      {'name': 'Flour - All Purpose', 'unit': 'kg', 'salesPrice': 'Rs. 120.00', 'stock': 300},
    ],
    '2': [
      {'name': 'Tea - Black', 'unit': 'kg', 'salesPrice': 'Rs. 1200.00', 'stock': 50},
      {'name': 'Coffee - Instant', 'unit': 'jar', 'salesPrice': 'Rs. 650.00', 'stock': 25},
      {'name': 'Biscuits - Marie', 'unit': 'pack', 'salesPrice': 'Rs. 85.00', 'stock': 120},
    ],
    '3': [
      {'name': 'Soap - Bath', 'unit': 'piece', 'salesPrice': 'Rs. 45.00', 'stock': 500},
      {'name': 'Shampoo - Herbal', 'unit': 'bottle', 'salesPrice': 'Rs. 380.00', 'stock': 60},
      {'name': 'Toothpaste - Mint', 'unit': 'tube', 'salesPrice': 'Rs. 150.00', 'stock': 200},
    ],
    '4': [
      {'name': 'Milk Powder', 'unit': 'pack', 'salesPrice': 'Rs. 890.00', 'stock': 40},
      {'name': 'Butter - Salted', 'unit': 'pack', 'salesPrice': 'Rs. 320.00', 'stock': 30},
    ],
    '5': [
      {'name': 'Onions - Red', 'unit': 'kg', 'salesPrice': 'Rs. 280.00', 'stock': 100},
      {'name': 'Potatoes', 'unit': 'kg', 'salesPrice': 'Rs. 120.00', 'stock': 250},
      {'name': 'Tomatoes', 'unit': 'kg', 'salesPrice': 'Rs. 180.00', 'stock': 80},
      {'name': 'Carrots', 'unit': 'kg', 'salesPrice': 'Rs. 200.00', 'stock': 60},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final Color supplierColor = supplier['color'] as Color;
    final products = supplierProducts[supplier['id']] ?? [];

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
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier['name'], style: const TextStyle(color: Palette.kText, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${products.length} Products', style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [supplierColor.withOpacity(0.1), Palette.kBg],
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
                        color: Palette.kSurface, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Palette.kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(color: supplierColor, borderRadius: BorderRadius.circular(15)),
                            child: supplier['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(supplier['image'], fit: BoxFit.cover),
                                  )
                                : const Icon(Feather.briefcase, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(supplier['contactPerson'], style: const TextStyle(color: Palette.kText, fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(supplier['location'], style: const TextStyle(color: Palette.kTextMuted, fontSize: 14)),
                                Text(supplier['phone'], style: const TextStyle(color: Palette.kTextMuted, fontSize: 12)),
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
                            color: supplierColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: supplierColor.withOpacity(0.3)),
                          ),
                          child: Text('${products.length} items',
                            style: TextStyle(color: supplierColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // list
                    if (products.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Palette.kSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Palette.kBorder)),
                        child: Column(
                          children: const [
                            Icon(Feather.package, color: Palette.kTextMuted, size: 48),
                            SizedBox(height: 16),
                            Text('No products found', style: TextStyle(color: Palette.kTextMuted, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Palette.kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Palette.kBorder)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: supplierColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Feather.package, color: supplierColor, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'], style: const TextStyle(color: Palette.kText, fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: Palette.kInfo.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                              child: Text('per ${p['unit']}', style: const TextStyle(color: Palette.kInfo, fontSize: 10, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: Palette.kSuccess.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                              child: Text('Stock: ${p['stock']}', style: const TextStyle(color: Palette.kSuccess, fontSize: 10, fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(p['salesPrice'], style: TextStyle(color: supplierColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
