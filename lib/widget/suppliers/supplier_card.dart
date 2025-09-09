import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';
import 'package:pos_system/widget/suppliers/supplier_detail_item.dart';

class SupplierCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onTap;   // open products (card tap)
  final VoidCallback onEdit;  // open edit dialog
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
    // fixed neutral accent (we do NOT read pplier color)
    const Color accent = Color(0xFF2D2F36);

    final String statusRaw = _s(supplier['status']);
    final bool isActive = _isActive(statusRaw);
    final String statusLabel = statusRaw.isEmpty ? (isActive ? 'ACTIVE' : 'INACTIVE') : statusRaw;

    final bool hasImage = _s(supplier['image']).isNotEmpty;

    final String name     = _s(supplier['name']);
    final String brand    = _s(supplier['brand']);
    final String phone    = _s(supplier['phone'] ?? supplier['contact']);
    final String email    = _s(supplier['email']);
    final String location = _s(supplier['location']);
    final String address  = _s(supplier['address']);

    final String subtitle = [
      if (brand.isNotEmpty) brand,
      if (phone.isNotEmpty) phone,
    ].join(' • ');

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
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: isTablet ? 72 : 64,
                          height: isTablet ? 72 : 64,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(_s(supplier['image']), fit: BoxFit.cover),
                                )
                              : const Icon(Feather.briefcase, color: Colors.white),
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
                              child: const Icon(Feather.pause, color: Colors.white, size: 12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty ? 'Unnamed supplier' : name,
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Palette.kSuccess : Palette.kDanger,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isActive ? Palette.kSuccess : Palette.kDanger).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  statusLabel,
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
                            subtitle.isEmpty ? '—' : subtitle,
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

                // Details
                if (isTablet)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.phone,
                              label: 'Phone',
                              value: phone.isEmpty ? '—' : phone,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.mail,
                              label: 'Email',
                              value: email.isEmpty ? '—' : email,
                              color: Colors.white70,
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
                              value: location.isEmpty ? '—' : location,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map,
                              label: 'Address',
                              value: address.isEmpty ? '—' : address,
                              color: Colors.white70,
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
                        value: phone.isEmpty ? '—' : phone,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      SupplierDetailItem(
                        icon: Feather.mail,
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map_pin,
                              label: 'Location',
                              value: location.isEmpty ? '—' : location,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SupplierDetailItem(
                              icon: Feather.map,
                              label: 'Address',
                              value: address.isEmpty ? '—' : address,
                              color: Colors.white70,
                              isAddress: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                SizedBox(height: isTablet ? 20 : 16),

                // Edit button
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isTablet ? 48 : 44,
                        child: ElevatedButton(
                          onPressed: onEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Feather.edit_3, color: Colors.white, size: 18),
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

String _s(dynamic v) => (v == null) ? '' : v.toString().trim();

bool _isActive(String status) {
  if (status.isEmpty) return true;
  final s = status.trim().toUpperCase();
  if (s == 'ACTIVE') return true;
  if (s == 'INACTIVE' || s == 'PENDING' || s == 'DISABLED') return false;
  if (s == 'TRUE' || s == '1' || s == 'YES') return true;
  if (s == 'FALSE' || s == '0' || s == 'NO') return false;
  return true;
}
