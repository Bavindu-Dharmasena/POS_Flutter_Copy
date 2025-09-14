import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/theme/palette.dart';

Future<void> showSupplierEditDialog({
  required BuildContext context,
  required Map<String, dynamic> supplier,
  required void Function(Map<String, dynamic> updated) onSave,
}) async {
  // controllers (safe defaults)
  final nameController = TextEditingController(text: _str(supplier['name']));
  final contactPersonController =
      TextEditingController(text: _nonEmpty(_str(supplier['contactPerson']), _str(supplier['contact'])));
  final phoneController = TextEditingController(text: _nonEmpty(_str(supplier['phone']), _str(supplier['contact'])));
  final emailController = TextEditingController(text: _str(supplier['email']));
  final locationController = TextEditingController(text: _str(supplier['location']));
  final addressController = TextEditingController(text: _str(supplier['address']));

  String currentStatus = _str(supplier['status']).isEmpty ? 'Active' : _str(supplier['status']);

  // NO color cast; fixed accent
  const Color accent = Color(0xFF3B82F6); // or Palette.kInfo

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent e) {
          if (e is RawKeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dialogWidth = constraints.maxWidth > 600 ? constraints.maxWidth * 0.9 : constraints.maxWidth - 32;
              final dialogHeight = constraints.maxHeight > 700 ? constraints.maxHeight * 0.8 : constraints.maxHeight - 80;

              return Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  color: Palette.kSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Palette.kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0,10))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))],
                                  ),
                                  child: (_str(supplier['image']).isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(_str(supplier['image']), fit: BoxFit.cover),
                                        )
                                      : const Icon(Feather.briefcase, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Edit Supplier', style: TextStyle(color: Palette.kText, fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(_str(supplier['name']), style: const TextStyle(color: Palette.kTextMuted, fontSize: 14), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Feather.x, color: Palette.kTextMuted, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _field('Company Name', nameController, Feather.briefcase),
                              const SizedBox(height: 16),
                              _field('Contact Person', contactPersonController, Feather.user),
                              const SizedBox(height: 16),
                              _field('Phone', phoneController, Feather.phone),
                              const SizedBox(height: 16),
                              _field('Email', emailController, Feather.mail),
                              const SizedBox(height: 16),
                              _field('Location', locationController, Feather.map_pin),
                              const SizedBox(height: 16),
                              _field('Address', addressController, Feather.map),
                              const SizedBox(height: 16),

                              // Status toggle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Status', style: TextStyle(color: Palette.kTextMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Palette.kBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setState(() => currentStatus = 'Active'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: currentStatus == 'Active' ? Palette.kSuccess : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: currentStatus == 'Active'
                                                    ? [BoxShadow(color: Palette.kSuccess.withOpacity(0.35), blurRadius: 8, offset: const Offset(0,2))]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Feather.check_circle, color: currentStatus == 'Active' ? Colors.white : Palette.kTextMuted, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Active',
                                                    style: TextStyle(
                                                      color: currentStatus == 'Active' ? Colors.white : Palette.kTextMuted,
                                                      fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setState(() => currentStatus = 'Inactive'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: currentStatus == 'Inactive' ? Palette.kDanger : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: currentStatus == 'Inactive'
                                                    ? [BoxShadow(color: Palette.kDanger.withOpacity(0.35), blurRadius: 8, offset: const Offset(0,2))]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Feather.pause_circle, color: currentStatus == 'Inactive' ? Colors.white : Palette.kTextMuted, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Inactive',
                                                    style: TextStyle(
                                                      color: currentStatus == 'Inactive' ? Colors.white : Palette.kTextMuted,
                                                      fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  final updated = Map<String, dynamic>.from(supplier);
                                  updated['name'] = nameController.text.trim();
                                  updated['contactPerson'] = contactPersonController.text.trim();
                                  updated['phone'] = phoneController.text.trim();
                                  updated['email'] = emailController.text.trim();
                                  updated['location'] = locationController.text.trim();
                                  updated['address'] = addressController.text.trim();
                                  updated['status'] = currentStatus;

                                  onSave(updated);
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.transparent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                      margin: const EdgeInsets.all(16),
                                      duration: const Duration(seconds: 3),
                                      dismissDirection: DismissDirection.horizontal,
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Palette.kSuccess,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Palette.kSuccess.withOpacity(0.35), blurRadius: 12, offset: const Offset(0,4))],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Feather.check_circle, color: Colors.white, size: 20),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                '${nameController.text} updated successfully!',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Feather.save, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              );
            },
          ),
        ),
      ),
    ),
  );
}

Widget _field(String label, TextEditingController c, IconData icon) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Palette.kTextMuted, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.kBorder),
        ),
        child: TextFormField(
          controller: c,
          style: const TextStyle(color: Palette.kText, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Palette.kTextMuted, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Palette.kInfo, width: 2),
            ),
          ),
        ),
      ),
    ],
  );
}

String _str(dynamic v) => (v == null) ? '' : v.toString().trim();
String _nonEmpty(String a, String b) => a.isNotEmpty ? a : b;
