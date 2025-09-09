import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../common/barcode_scanner_page.dart';
import '../../data/repositories/stockkeeper/item_repository.dart';
import '../../data/models/stockkeeper/item_model.dart';
import '../../data/models/stockkeeper/category_model.dart';
import '../../data/models/stockkeeper/supplier_model.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> with TickerProviderStateMixin {
  // ========= THEME =========
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26);
  static const Color kBorder = Color(0x1FFFFFFF);
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;
  static const Color kHint = Colors.white38;

  static const Color kInfo = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarn = Color(0xFFF59E0B);
  static const Color kDanger = Color(0xFFEF4444);

  // ========= STATE =========
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _reorderCtrl = TextEditingController(text: '0');
  final TextEditingController _remarkCtrl = TextEditingController();
  final TextEditingController _gradientCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // IDs per schema
  int? _selectedCategoryId;
  int? _selectedSupplierId;

  // Lookups from SQLite
  bool _loadingLookups = true;
  String? _lookupError;
  List<CategoryModel> _categories = [];
  List<SupplierModel> _suppliers = [];

  // Optional flat color (sent as colorCode)
  final List<Color> _colorPalette = const [
    Color(0xFF3B82F6),
    Color(0xFFF97316),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFF475569),
  ];
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    _loadLookups();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _reorderCtrl.dispose();
    _remarkCtrl.dispose();
    _gradientCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ========= SQLite lookups =========
  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });
    try {
      final repo = ItemRepository.instance;
      final cats = await repo.fetchCategories();
      final sups = await repo.fetchSuppliers();
      setState(() {
        _categories = cats;
        _suppliers = sups;
        _loadingLookups = false;
      });
    } catch (e) {
      setState(() {
        _lookupError = 'Failed to load lookups: $e';
        _loadingLookups = false;
      });
    }
  }

  // ========= HELPERS =========
  void _scrollToFirstError() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  String _colorToHex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Color? _categoryDefaultColor(int? categoryId) {
    if (categoryId == null) return null;
    final m = _categories.firstWhere(
      (e) => e.id == categoryId,
      orElse: () => const CategoryModel(category: '', colorCode: '#475569'),
    );
    final code = m.colorCode.replaceFirst('#', '');
    if (code.length == 6) {
      return Color(int.parse('FF$code', radix: 16));
    }
    return null;
  }

  // ========= VALIDATORS =========
  String? _reqText(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _reqInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Must be >= 0';
    return null;
  }

  // ========= SUBMIT (SQLite) =========
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }
    if (_loadingLookups) {
      _showSnack(icon: Feather.alert_triangle, color: kWarn, text: 'Lookups are still loading…');
      return;
    }
    if (_categories.isEmpty) {
      _showSnack(icon: Feather.alert_triangle, color: kDanger, text: 'No categories found in DB');
      return;
    }
    if (_selectedCategoryId == null || _selectedSupplierId == null) {
      _showSnack(icon: Feather.alert_triangle, color: kDanger, text: 'Select category & supplier');
      return;
    }

    final repo = ItemRepository.instance;

    // Unique barcode guard
    final barcode = _barcodeCtrl.text.trim();
    final exists = await repo.barcodeExists(barcode);
    if (exists) {
      _showSnack(
        icon: Feather.alert_triangle,
        color: kDanger,
        text: 'Barcode already exists',
      );
      return;
    }

    final Color fallback = _selectedColor ?? _categoryDefaultColor(_selectedCategoryId) ?? const Color(0xFF000000);
    final String colorHex = _colorToHex(fallback);

    final item = ItemModel(
      name: _nameCtrl.text.trim(),
      barcode: barcode,
      categoryId: _selectedCategoryId!,
      supplierId: _selectedSupplierId!,
      reorderLevel: int.tryParse(_reorderCtrl.text.trim()) ?? 0,
      gradient: _gradientCtrl.text.trim().isEmpty ? null : _gradientCtrl.text.trim(),
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
      colorCode: colorHex,
    );

    try {
      final id = await repo.insertItem(item);
      _showSnack(
        icon: Feather.check_circle,
        color: kSuccess,
        text: 'Item saved (ID: $id)',
      );
      _resetForm();
    } on Exception catch (e) {
      // Handle UNIQUE constraint or FK failures nicely
      final msg = e.toString().contains('UNIQUE constraint')
          ? 'Barcode already exists'
          : e.toString();
      _showSnack(icon: Feather.alert_triangle, color: kDanger, text: msg);
    } catch (e) {
      _showSnack(icon: Feather.alert_triangle, color: kDanger, text: 'Save failed: $e');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _barcodeCtrl.clear();
    _reorderCtrl.text = '0';
    _remarkCtrl.clear();
    _gradientCtrl.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedSupplierId = null;
      _selectedColor = null;
    });
  }

  void _showSnack({required IconData icon, required Color color, required String text}) {
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
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========= UI =========
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus || currentFocus.focusedChild == null) {
              _submitForm();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: kBg,
                automaticallyImplyLeading: false,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: kBg)],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Feather.arrow_left, color: Colors.white, size: 20),
                  ),
                ),
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    'Add Product',
                    style: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 72, bottom: 16),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Basic Info
                          _dashboardCard(
                            icon: Feather.info,
                            title: 'Basic Info',
                            color: kInfo,
                            children: [
                              _buildRow([
                                _dashboardTextField(
                                  controller: _nameCtrl,
                                  label: 'Product Name',
                                  hint: 'Ex: Coca Cola 1L',
                                  validator: _reqText,
                                ),
                                _dashboardBarcodeField(),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Relations
                          _dashboardCard(
                            icon: Feather.package,
                            title: 'Relations',
                            color: kWarn,
                            children: [
                              _categoriesSection(),
                              const SizedBox(height: 12),
                              _suppliersSection(),
                              const SizedBox(height: 12),
                              _dashboardNumberField(
                                controller: _reorderCtrl,
                                label: 'Reorder Level',
                                hint: '10',
                                validator: _reqInt,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Appearance & Meta
                          _dashboardCard(
                            icon: Feather.layers,
                            title: 'Appearance & Meta',
                            color: Color(0xFFEC4899),
                            children: [
                              _flatColorPicker(),
                              const SizedBox(height: 12),
                              _dashboardTextField(
                                controller: _gradientCtrl,
                                label: 'Gradient (optional)',
                                hint: 'e.g. linear(#3B82F6,#06B6D4)',
                              ),
                              const SizedBox(height: 12),
                              _dashboardTextField(
                                controller: _remarkCtrl,
                                label: 'Notes',
                                hint: 'Optional remarks',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _dashboardPreview(),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _resetForm,
                                    style: _btnStyle(background: const Color(0xFF334155)),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Feather.refresh_cw, color: Colors.white70, size: 18),
                                        SizedBox(width: 8),
                                        Text('Reset',
                                            style: TextStyle(
                                                color: Colors.white70, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
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
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Feather.check_circle, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Save Product',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Reusable bits =====

  ButtonStyle _btnStyle({required Color background}) {
    return ElevatedButton.styleFrom(
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
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Flexible(
              child: Text('', style: TextStyle(color: Colors.transparent)),
            ),
          ]),
          Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    if (children.length == 1) return children.first;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          children: children
              .expand((child) => [child, const SizedBox(height: 12)])
              .take(children.length * 2 - 1)
              .toList(),
        );
      }
      final expanded = children.map((child) => Expanded(child: child)).toList();
      return Row(children: [
        for (int i = 0; i < expanded.length; i++) ...[
          expanded[i],
          if (i != expanded.length - 1) const SizedBox(width: 12),
        ]
      ]);
    });
  }

  InputDecoration _dashboardDecoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: kHint),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBorder)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: kInfo, width: 2)),
      errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: kDanger, width: 1)),
      focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: kDanger, width: 2)),
    );
  }

  Widget _dashboardTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _dashboardDecoration(label, hint: hint),
      validator: validator,
    );
  }

  Widget _dashboardNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _dashboardDecoration(label, hint: hint, prefixText: prefix, suffixText: suffix),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  // ----- Category UI -----
  Widget _categoriesSection() {
    if (_loadingLookups) {
      return InputDecorator(
        decoration: _dashboardDecoration('Category'),
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
            SizedBox(width: 12),
            Text('Loading categories…', style: TextStyle(color: kTextMuted)),
          ],
        ),
      );
    }

    if (_lookupError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: _dashboardDecoration('Category'),
            child: Text(_lookupError!, style: const TextStyle(color: kDanger)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadLookups,
              icon: const Icon(Feather.refresh_cw, color: kTextMuted, size: 14),
              label: const Text('Retry', style: TextStyle(color: kTextMuted)),
            ),
          )
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      items: _categories
          .map((e) => DropdownMenuItem<int>(
                value: e.id,
                child: Text(
                  e.category,
                  style: const TextStyle(color: kText),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (id) {
        setState(() {
          _selectedCategoryId = id;
          _selectedColor ??= _categoryDefaultColor(id);
        });
      },
      validator: (v) => v == null ? 'Required' : null,
      dropdownColor: kSurface,
      decoration: _dashboardDecoration('Category'),
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: kTextMuted, size: 20),
      isExpanded: true,
    );
  }

  // ----- Supplier UI -----
  Widget _suppliersSection() {
    if (_loadingLookups) {
      return InputDecorator(
        decoration: _dashboardDecoration('Supplier'),
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
            SizedBox(width: 12),
            Text('Loading suppliers…', style: TextStyle(color: kTextMuted)),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedSupplierId,
      items: _suppliers
          .map((e) => DropdownMenuItem<int>(
                value: e.id,
                child: Text(e.name, style: const TextStyle(color: kText), overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (id) => setState(() => _selectedSupplierId = id),
      validator: (v) => v == null ? 'Required' : null,
      dropdownColor: kSurface,
      decoration: _dashboardDecoration('Supplier'),
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: kTextMuted, size: 20),
      isExpanded: true,
    );
  }

  Widget _dashboardBarcodeField() {
    return TextFormField(
      controller: _barcodeCtrl,
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _dashboardDecoration(
        'Barcode',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kInfo,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kInfo.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
                  );
                  if (result != null && result is String) {
                    setState(() => _barcodeCtrl.text = result);
                  }
                },
                child: const Center(child: Icon(Feather.camera, color: Colors.white, size: 18)),
              ),
            ),
          ),
        ),
      ),
      validator: _reqText,
    );
  }

  Widget _flatColorPicker() {
    final current = _selectedColor ?? _categoryDefaultColor(_selectedCategoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Color Theme', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          if (current != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: current,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: current.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 2))],
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedColor = null),
            icon: const Icon(Feather.refresh_cw, color: kTextMuted, size: 14),
            label: const Text('Reset', style: TextStyle(color: kTextMuted, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorPalette.map((c) {
            final bool isSelected = (current == c);
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withOpacity(isSelected ? 0.6 : 0.35),
                      blurRadius: isSelected ? 14 : 8,
                      offset: Offset(0, isSelected ? 4 : 2),
                    )
                  ],
                ),
                child: isSelected ? const Icon(Feather.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dashboardPreview() {
    final Color previewColor = _selectedColor ?? _categoryDefaultColor(_selectedCategoryId) ?? const Color(0xFF475569);

    final String catName = (_selectedCategoryId == null)
        ? 'Category'
        : (_categories.firstWhere(
              (e) => e.id == _selectedCategoryId,
              orElse: () => const CategoryModel(category: 'Category', colorCode: '#475569'),
            ).category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: previewColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Feather.package, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _nameCtrl.text.isEmpty ? 'Product Preview' : _nameCtrl.text,
                style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$catName • ${_barcodeCtrl.text.isEmpty ? "No Code" : _barcodeCtrl.text}',
                style: const TextStyle(color: kTextMuted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              'Color ${_colorToHex(previewColor)}',
              style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _reorderCtrl.text.isEmpty ? '' : 'Reorder: ${_reorderCtrl.text}',
              style: const TextStyle(color: kTextMuted, fontSize: 12),
            ),
          ]),
        ],
      ),
    );
  }
}
