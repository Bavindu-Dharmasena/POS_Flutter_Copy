import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';
import 'package:pos_system/widget/suppliers/supplier_detail_item.dart';

class SupplierCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onTap; // open products (card tap)
  final VoidCallback onEdit; // open edit dialog
  final bool isTablet;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onTap,
    required this.onEdit,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final Color supplierColor = supplier['color'] as Color;
    final bool hasImage = supplier['image'] != null;
    final bool isActive = supplier['status'] == 'Active';

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Palette.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: isTablet ? 72 : 64,
                          height: isTablet ? 72 : 64,
                          decoration: BoxDecoration(
                            color: supplierColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: supplierColor.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    supplier['image'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Feather.briefcase,
                                  color: Colors.white,
                                  size: isTablet ? 32 : 28,
                                ),
                        ),
                        if (!isActive)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Palette.kDanger,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.kDanger.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Feather.pause,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  supplier['name'],
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.kText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Palette.kSuccess
                                      : Palette.kDanger,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isActive
                                                  ? Palette.kSuccess
                                                  : Palette.kDanger)
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  supplier['status'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supplier['contactPerson'],
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Palette.kTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 20 : 16),

                // Details (responsive)
                if (isTablet)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.phone,
                              label: 'Phone',
                              value: supplier['phone'],
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.mail,
                              label: 'Email',
                              value: supplier['email'],
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map_pin,
                              label: 'Location',
                              value: supplier['location'],
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map,
                              label: 'Address',
                              value: supplier['address'],
                              color: Colors.black,
                              isAddress: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      SupplierDetailItem(
                        icon: Feather.phone,
                        label: 'Phone',
                        value: supplier['phone'],
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      SupplierDetailItem(
                        icon: Feather.mail,
                        label: 'Email',
                        value: supplier['email'],
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map_pin,
                              label: 'Location',
                              value: supplier['location'],
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map,
                              label: 'Address',
                              value: supplier['address'],
                              color: Colors.black,
                              isAddress: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                SizedBox(height: isTablet ? 20 : 16),

                // Action Row: ONLY Edit (you asked to remove View button)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isTablet ? 48 : 44,
                        child: ElevatedButton(
                          onPressed: onEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: supplierColor,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Feather.edit_3,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 15 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
