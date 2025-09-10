import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:pos_system/data/models/stockkeeper/supplier_model.dart';
import 'package:pos_system/data/repositories/stockkeeper/supplier_repository.dart';


class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key, required this.supplierData});
  /// Pass {} for add, or a filled map for edit
  final Map supplierData;

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);

  // Colors (dark card style)
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26);
  static const Color kBorder = Color(0x1FFFFFFF);
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;
  static const Color kHint = Colors.white38;
  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kDanger = Color(0xFFEF4444);

  // Controllers
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  bool _active = true;
  List<String> _locations = [];
  String? _paymentTerms;

  final _paymentOptions = const ['Cash', 'Credit 7 Days', 'Credit 15 Days', 'Credit 30 Days', 'Credit 60 Days'];

  // Accent gradients
  static const _gradBluePurple = LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA855F7)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const _gradGreen = LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const _gradOrange = LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEAB308)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const _gradPink = LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const _gradSlate = LinearGradient(colors: [Color(0xFF475569), Color(0xFF334155)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  LinearGradient _selectedGradient = _gradBluePurple;

  @override
  void initState() {
    super.initState();
    final d = widget.supplierData;
    if (d.isNotEmpty) {
      _idCtrl.text = (d['id'] ?? '').toString();
      _nameCtrl.text = (d['name'] ?? '').toString();
      _contactCtrl.text = (d['contact'] ?? d['phone'] ?? '').toString();
      _emailCtrl.text = (d['email'] ?? '').toString();
      _brandCtrl.text = (d['brand'] ?? '').toString();
      _remarkCtrl.text = (d['remarks'] ?? d['notes'] ?? '').toString();

      final locs = (d['locations'] is List)
          ? List<String>.from(d['locations'])
          : (d['location'] != null ? <String>[d['location'].toString()] : <String>[]);
      _locations = locs;

      _paymentTerms = d['paymentTerms']?.toString();
      _active = d['active'] is bool ? d['active'] as bool : (d['status']?.toString().toUpperCase() == 'ACTIVE');
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _brandCtrl.dispose();
    _locationCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  String _hexFromGradient(LinearGradient g) {
    final c = g.colors.first;
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}'.toUpperCase();
  }

  String _mapPaymentTermsForDb(String? ui) {
    switch ((ui ?? '').toLowerCase()) {
      case 'cash': return 'CASH';
      case 'credit 7 days': return 'NET 7';
      case 'credit 15 days': return 'NET 15';
      case 'credit 30 days': return 'NET 30';
      case 'credit 60 days': return 'NET 60';
      default: return 'CASH';
    }
  }

  void _addLocation() {
    final t = _locationCtrl.text.trim();
    if (t.isNotEmpty) {
      setState(() {
        if (!_locations.contains(t)) _locations.add(t);
        _locationCtrl.clear();
      });
    }
  }

  void _removeLocation(int index) => setState(() => _locations.removeAt(index));

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToTop();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final isEdit = widget.supplierData.isNotEmpty;
    final id = int.tryParse(_idCtrl.text.trim());

    final supplier = Supplier(
      id: isEdit ? id : null,
      name: _nameCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: null,
      brand: _brandCtrl.text.trim(),
      colorCode: _hexFromGradient(_selectedGradient),
      location: _locations.isNotEmpty ? _locations.first : 'N/A',
      status: _active ? 'ACTIVE' : 'INACTIVE',
      preferred: false,
      paymentTerms: _mapPaymentTermsForDb(_paymentTerms),
      notes: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
      createdAt: isEdit ? (widget.supplierData['created_at'] as int? ?? now) : now,
      updatedAt: now,
    );

    final repo = SupplierRepository.instance;

    try {
      Supplier saved;
      if (isEdit && supplier.id != null) {
        await repo.update(supplier);
        saved = supplier;
      } else {
        saved = await repo.create(supplier);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: kSuccess,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kSuccess.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Feather.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${isEdit ? "Updated" : "Saved"}: ${saved.name}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      // log if needed
      // debugPrint('Save supplier failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _idCtrl.clear();
    _nameCtrl.clear();
    _contactCtrl.clear();
    _emailCtrl.clear();
    _brandCtrl.clear();
    _locationCtrl.clear();
    _remarkCtrl.clear();
    setState(() {
      _active = true;
      _locations.clear();
      _paymentTerms = null;
      _selectedGradient = _gradBluePurple;
    });
  }

  final _scrollCtrl = ScrollController();
  void _scrollToTop() => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplierData.isNotEmpty;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              backgroundColor: kBg,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Feather.arrow_left, color: kText, size: 20)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier', style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 20)),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(children: [
                      _sectionCard(
                        icon: Feather.info,
                        title: 'Basic Information',
                        accent: _gradBluePurple,
                        children: [
                          _rowWrap([
                            _tf(_idCtrl, 'Supplier ID', hint: isEdit ? 'Auto (readonly)' : 'Auto-generated', readOnly: isEdit),
                            _tf(_nameCtrl, 'Supplier Name', hint: 'Ex: ABC Traders', validator: _req),
                          ]),
                          const SizedBox(height: 12),
                          _rowWrap([
                            _tf(_contactCtrl, 'Contact Number', hint: '0771234567', validator: _reqPhone),
                            _tf(_emailCtrl, 'Email (Optional)', hint: 'supplier@email.com', validator: _optEmail),
                          ]),
                          const SizedBox(height: 12),
                          _tf(_brandCtrl, 'Brand / Company', hint: 'Brand or company name', validator: _req),
                          const SizedBox(height: 12),
                          _switchTile('Active Status', _active, (v) => setState(() => _active = v)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        icon: Feather.credit_card,
                        title: 'Payment & Terms',
                        accent: _gradGreen,
                        children: [
                          _dropdown<String>(
                            label: 'Payment Terms',
                            value: _paymentTerms,
                            items: _paymentOptions,
                            onChanged: (v) => setState(() => _paymentTerms = v),
                            validator: (v) => v == null ? 'Select payment terms' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        icon: Feather.map_pin,
                        title: 'Locations',
                        accent: _gradOrange,
                        children: [
                          Row(children: [
                            Expanded(child: _tf(_locationCtrl, 'Add Location', hint: 'Ex: Colombo, Kandy')),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _addLocation,
                                style: _btnStyle(background: kInfo),
                                child: const Icon(Feather.plus, color: Colors.white, size: 18),
                              ),
                            ),
                          ]),
                          if (_locations.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _locations.asMap().entries.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(gradient: _gradSlate, borderRadius: BorderRadius.circular(12)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Feather.map_pin, color: Colors.white70, size: 14),
                                      const SizedBox(width: 6),
                                      Text(e.value, style: const TextStyle(color: kText, fontSize: 13)),
                                      const SizedBox(width: 6),
                                      GestureDetector(onTap: () => _removeLocation(e.key), child: const Icon(Feather.x, color: kDanger, size: 16)),
                                    ]),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        icon: Feather.layers,
                        title: 'Appearance & Notes',
                        accent: _gradPink,
                        children: [
                          _gradientPicker(),
                          const SizedBox(height: 16),
                          _tf(_remarkCtrl, 'Remarks / Notes', hint: 'Optional notes', maxLines: 3),
                          const SizedBox(height: 16),
                          _preview(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _resetForm,
                              style: _btnStyle(background: const Color(0xFF334155)),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Feather.refresh_cw, color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text('Reset', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: _btnStyle(background: kSuccess),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Feather.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Save Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI helpers
  ButtonStyle _btnStyle({required Color background}) => ElevatedButton.styleFrom(
        backgroundColor: background,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ).merge(
        ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => Colors.white.withOpacity(states.contains(WidgetState.pressed) ? 0.08 : 0.04),
          ),
        ),
      );

  Widget _sectionCard({required IconData icon, required String title, required LinearGradient accent, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(gradient: accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: accent.colors.first.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Flexible(child: Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 20),
          ...children,
        ]),
      ),
    );
  }

  Widget _rowWrap(List<Widget> children) {
    if (children.length == 1) return children.first;
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 600) {
        final list = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          list.add(children[i]);
          if (i != children.length - 1) list.add(const SizedBox(height: 12));
        }
        return Column(children: list);
      }
      return Row(children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 12),
        ],
      ]);
    });
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: kHint),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kInfo, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kDanger, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kDanger, width: 2)),
      );

  Widget _tf(TextEditingController c, String label, {String? hint, String? Function(String?)? validator, int maxLines = 1, bool readOnly = false}) {
    return TextFormField(
      controller: c,
      readOnly: readOnly,
      maxLines: maxLines,
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _decoration(label, hint: hint),
      validator: validator,
      keyboardType: label.toLowerCase().contains('contact') ? TextInputType.phone : TextInputType.text,
      inputFormatters: label.toLowerCase().contains('contact') ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))] : null,
    );
  }

  Widget _dropdown<T>({required String label, required T? value, required List<T> items, required void Function(T?) onChanged, String? Function(T?)? validator}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString(), style: const TextStyle(color: kText), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: kSurface,
      decoration: _decoration(label),
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: kTextMuted, size: 20),
      isExpanded: true,
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Row(children: [
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.white70,
            activeTrackColor: value ? kSuccess : const Color(0xFF475569),
            inactiveTrackColor: const Color(0xFF475569),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,
          ),
        ),
      ]),
    );
  }

  Widget _gradientPicker() {
    final list = <LinearGradient>[_gradBluePurple, _gradGreen, _gradOrange, _gradPink, _gradSlate];
    final sel = _selectedGradient;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Color Theme', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Container(width: 22, height: 22, decoration: BoxDecoration(gradient: sel, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: sel.colors.first.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 2))])),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => _selectedGradient = _gradBluePurple),
          icon: const Icon(Feather.refresh_cw, color: kTextMuted, size: 14),
          label: const Text('Reset', style: TextStyle(color: kTextMuted, fontSize: 12)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: list.map((g) {
          final isSel = identical(g, _selectedGradient) || (g.colors.first == sel.colors.first && g.colors.last == sel.colors.last);
          return GestureDetector(
            onTap: () => setState(() => _selectedGradient = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: g,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? Colors.white : Colors.white.withOpacity(0.15), width: isSel ? 3 : 1),
                boxShadow: [BoxShadow(color: g.colors.first.withOpacity(isSel ? 0.6 : 0.35), blurRadius: isSel ? 14 : 8, offset: Offset(0, isSel ? 4 : 2))],
              ),
              child: isSel ? const Icon(Feather.check, color: Colors.white, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _preview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: const Border.fromBorderSide(BorderSide(color: kBorder))),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(gradient: _selectedGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _selectedGradient.colors.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Feather.truck, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nameCtrl.text.isEmpty ? 'Supplier Preview' : _nameCtrl.text, style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '${_brandCtrl.text.isEmpty ? "Brand" : _brandCtrl.text} • ${_contactCtrl.text.isEmpty ? "No Contact" : _contactCtrl.text}',
              style: const TextStyle(color: kTextMuted, fontSize: 13), overflow: TextOverflow.ellipsis,
            ),
            if (_locations.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 ${_locations.length} Location${_locations.length > 1 ? "s" : ""}', style: const TextStyle(color: kTextMuted, fontSize: 12)),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _active ? kSuccess : kDanger, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: (_active ? kSuccess : kDanger).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Text(_active ? 'Active' : 'Inactive', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // Validators
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _optEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+');
    if (!re.hasMatch(v.trim())) return 'Invalid email';
    return null;
  }

  String? _reqPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final t = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.length < 9 || t.length > 12) return 'Invalid phone';
    return null;
  }
}
