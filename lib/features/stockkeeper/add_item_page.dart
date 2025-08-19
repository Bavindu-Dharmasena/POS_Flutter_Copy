import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../common/barcode_scanner_page.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({Key? key}) : super(key: key);

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _unitPriceCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _saleCtrl = TextEditingController();
  final TextEditingController _reorderCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();

  // Dropdowns
  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedSupplier;

  // Flat color palette per category
  final Map<String, Color> categoryColors = const {
    'Drinks': Color(0xFF3B82F6),        // Blue
    'Snacks': Color(0xFFF97316),        // Orange
    'Grocery': Color(0xFF10B981),       // Green
    'Bakery': Color(0xFFEC4899),        // Pink
    'Personal Care': Color(0xFFEF4444), // Red
    'Other': Color(0xFF475569),         // Slate
  };

  // Flat color choices for appearance
  final List<Color> _colorPalette = const [
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Green
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFF475569), // Slate
  ];

  Color? _selectedColor;

  final List<String> _units = const ['Unit', 'Pack', 'Box', 'Kg', 'g', 'L', 'mL'];
  final List<String> _suppliers = const ['Default Supplier', 'AAA Traders', 'FreshCo', 'Kandy Foods'];

  bool _isEditingByCode = false;

  // App palette (no gradients)
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26); // cards
  static const Color kBorder = Color(0x1FFFFFFF);  // faint white border
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;
  static const Color kHint = Colors.white38;

  static const Color kInfo = Color(0xFF3B82F6);    // info/primary
  static const Color kSuccess = Color(0xFF10B981); // save button / success
  static const Color kWarn = Color(0xFFF59E0B);    // header back, accents
  static const Color kDanger = Color(0xFFEF4444);  // validation / errors
// headings accent

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _unitPriceCtrl.addListener(_onPriceOrDiscountChanged);
    _discountCtrl.addListener(_onPriceOrDiscountChanged);
    _saleCtrl.addListener(_onSaleChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitPriceCtrl.dispose();
    _discountCtrl.dispose();
    _saleCtrl.dispose();
    _reorderCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  // ---------- Calculations ----------
  // Sale = Unit Price - Discount Amount (clamped at >= 0)
  void _onPriceOrDiscountChanged() {
    if (_isEditingByCode) return;
    _isEditingByCode = true;
    final double unit = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final double discount = double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final double sale = math.max(0.0, unit - discount);
    _saleCtrl.text = _fmt2(sale);
    _isEditingByCode = false;
  }

  // When user edits Sale directly, back-compute Discount = Unit Price - Sale (>= 0)
  void _onSaleChanged() {
    if (_isEditingByCode) return;
    _isEditingByCode = true;
    final double unit = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final double sale = double.tryParse(_saleCtrl.text.replaceAll(',', '.')) ?? 0.0;
    var discount = unit - sale;
    if (discount < 0) discount = 0;
    _discountCtrl.text = _fmt2(discount);
    _isEditingByCode = false;
  }

  String _fmt2(double v) => v.isFinite ? v.toStringAsFixed(2) : '';

  // ---------- Actions ----------
  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final payload = {
      'name': _nameCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim(),
      'unit': _selectedUnit,
      'category': _selectedCategory,
      'unitPrice': double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'discountAmount': double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'salePrice': double.tryParse(_saleCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'supplier': _selectedSupplier,
      'reorderLevel': int.tryParse(_reorderCtrl.text) ?? 0,
      'color': _selectedColor?.value, // store ARGB int if you like
      'remark': _remarkCtrl.text.trim(),
    };

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
            color: kSuccess,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kSuccess.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Feather.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Product saved: ${payload['name']}',
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

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameCtrl.clear();
    _barcodeCtrl.clear();
    _unitPriceCtrl.clear();
    _discountCtrl.clear();
    _saleCtrl.clear();
    _reorderCtrl.clear();
    _remarkCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _selectedUnit = null;
      _selectedSupplier = null;
      _selectedColor = null;
    });
  }

  final _scrollCtrl = ScrollController();
  void _scrollToFirstError() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  // ---------- UI ----------
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
                    boxShadow: [
                      BoxShadow(
                        color: kBg,
                        
                        // offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Feather.arrow_left, color: Colors.white, size: 20),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Add Product',
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
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
                          // Basic Info Section
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
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                _dashboardBarcodeField(),
                              ]),
                              const SizedBox(height: 12),
                              _buildRow([
                                _dashboardDropdown<String>(
                                  label: 'Unit',
                                  value: _selectedUnit,
                                  items: _units,
                                  onChanged: (v) => setState(() => _selectedUnit = v),
                                  validator: (v) => v == null ? 'Select unit' : null,
                                ),
                                _dashboardCategoryField(),
                              ]),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Pricing Section
                          _dashboardCard(
                            icon: Feather.trending_up,
                            title: 'Pricing',
                            color: kSuccess,
                            children: [
                              _buildRow([
                                _dashboardNumberField(
                                  controller: _unitPriceCtrl,
                                  label: 'Unit Price',
                                  prefix: 'Rs. ',
                                  validator: _reqMoney,
                                ),
                                _dashboardNumberField(
                                  controller: _discountCtrl,
                                  label: 'Discount Amount',
                                  prefix: 'Rs. ',
                                  validator: _reqDiscountValidAgainstUnit,
                                ),
                              ]),
                              const SizedBox(height: 12),
                              _dashboardNumberField(
                                controller: _saleCtrl,
                                label: 'Sale Price',
                                prefix: 'Rs. ',
                                validator: _reqMoney,
                                fullWidth: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Inventory & Supplier Section
                          _dashboardCard(
                            icon: Feather.package,
                            title: 'Inventory & Supplier',
                            color: kWarn,
                            children: [
                              _dashboardDropdown<String>(
                                label: 'Supplier',
                                value: _selectedSupplier,
                                items: _suppliers,
                                onChanged: (v) => setState(() => _selectedSupplier = v),
                                validator: (v) => v == null ? 'Select supplier' : null,
                              ),
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

                          // Appearance Section
                          _dashboardCard(
                            icon: Feather.layers,
                            title: 'Appearance',
                            color: const Color(0xFFEC4899), // Pink
                            children: [
                              _flatColorPicker(),
                              const SizedBox(height: 12),
                              _dashboardTextField(
                                controller: _remarkCtrl,
                                label: 'Notes',
                                hint: 'Optional remarks',
                                maxLines: 2,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 16),
                              _dashboardPreview(),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _resetForm,
                                    style: _btnStyle(background: const Color(0xFF334155)), // Slate-700
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Feather.refresh_cw, color: Colors.white70, size: 18),
                                        SizedBox(width: 8),
                                        Text('Reset', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
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
                                        Text('Save Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  // ---------- Dashboard-Style Components ----------
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color, // solid color icon tile
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    if (children.length == 1) return children.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: children
                .expand((child) => [child, const SizedBox(height: 12)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }

        final expanded = children.map((child) => Expanded(child: child)).toList();
        return Row(
          children: [
            for (int i = 0; i < expanded.length; i++) ...[
              expanded[i],
              if (i != expanded.length - 1) const SizedBox(width: 12),
            ]
          ],
        );
      },
    );
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kInfo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDanger, width: 2),
      ),
    );
  }

  Widget _dashboardTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool fullWidth = false,
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
    bool fullWidth = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _dashboardDecoration(label, hint: hint, prefixText: prefix, suffixText: suffix),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: validator,
    );
  }

  Widget _dashboardDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: kText),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: kSurface,
      decoration: _dashboardDecoration(label),
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
              boxShadow: [
                BoxShadow(
                  color: kInfo.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                child: const Center(
                  child: Icon(Feather.camera, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _dashboardCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: categoryColors.entries
          .map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        e.key,
                        style: const TextStyle(color: kText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() {
        _selectedCategory = v;
        if (v != null) _selectedColor ??= categoryColors[v]; // default color if none picked
      }),
      validator: (v) => v == null ? 'Select category' : null,
      dropdownColor: kSurface,
      decoration: _dashboardDecoration('Category'),
      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: kTextMuted, size: 20),
      isExpanded: true,
    );
  }

  Widget _flatColorPicker() {
    final current = _selectedColor ?? (_selectedCategory != null ? categoryColors[_selectedCategory!] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Color Theme', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            if (current != null)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: current.withOpacity(0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          ],
        ),
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
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Feather.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dashboardPreview() {
    final Color previewColor = _selectedColor ??
        (_selectedCategory != null ? categoryColors[_selectedCategory!]! : const Color(0xFF475569));

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
              boxShadow: [
                BoxShadow(
                  color: previewColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Feather.package, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Product Preview' : _nameCtrl.text,
                  style: const TextStyle(
                    color: kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedCategory ?? 'Category'} • ${_barcodeCtrl.text.isEmpty ? 'No Code' : _barcodeCtrl.text}',
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _saleCtrl.text.isEmpty ? 'Rs. 0.00' : 'Rs. ${_saleCtrl.text}',
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _unitPriceCtrl.text.isEmpty ? '' : 'Unit: Rs. ${_unitPriceCtrl.text}',
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Validators ----------
  String? _reqMoney(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Must be >= 0';
    return null;
  }

  String? _reqInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Must be >= 0';
    return null;
  }

  // Discount must be >=0 and <= Unit Price (when Unit Price provided)
  String? _reqDiscountValidAgainstUnit(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return 'Invalid number';
    if (d < 0) return 'Must be >= 0';
    final unit = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.'));
    if (unit != null && d > unit) return 'Cannot exceed unit price';
    return null;
  }
}
