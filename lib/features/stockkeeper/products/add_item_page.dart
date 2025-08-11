import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../common/barcode_scanner_page.dart';

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
  final TextEditingController _costCtrl = TextEditingController();
  final TextEditingController _markupCtrl = TextEditingController();
  final TextEditingController _saleCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _reorderCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();

  // Dropdowns & toggles
  String? _selectedCategory;
  String? _selectedUnit;
  bool _active = true;
  bool _lowStockWarning = true;

  // Dashboard-inspired color palette
  final Map<String, LinearGradient> categoryGradients = const {
    'Drinks': LinearGradient(
      colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Snacks': LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEAB308)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Grocery': LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Bakery': LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Personal Care': LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Other': LinearGradient(
      colors: [Color(0xFF475569), Color(0xFF334155)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  // Additional gradient options for color picker
  final List<LinearGradient> _gradientPalette = const [
    LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA855F7)]),
    LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEAB308)]),
    LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
    LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
    LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFEC4899)]),
    LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
    LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
    LinearGradient(colors: [Color(0xFF84CC16), Color(0xFF65A30D)]),
  ];

  LinearGradient? _selectedGradient;

  final List<String> _units = const ['Unit', 'Pack', 'Box', 'Kg', 'g', 'L', 'mL'];
  final List<String> _suppliers = const ['Default Supplier', 'AAA Traders', 'FreshCo', 'Kandy Foods'];

  bool _isEditingByCode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _costCtrl.addListener(_onCostOrMarkupChanged);
    _markupCtrl.addListener(_onCostOrMarkupChanged);
    _saleCtrl.addListener(_onSaleChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _markupCtrl.dispose();
    _saleCtrl.dispose();
    _supplierCtrl.dispose();
    _reorderCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  // ---------- Calculations ----------
  void _onCostOrMarkupChanged() {
    if (_isEditingByCode) return;
    _isEditingByCode = true;
    final cost = double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final markup = double.tryParse(_markupCtrl.text.replaceAll('%', '').replaceAll(',', '.')) ?? 0.0;
    if (cost >= 0) {
      final sale = cost * (1 + markup / 100);
      _saleCtrl.text = _fmt2(sale);
    }
    _isEditingByCode = false;
  }

  void _onSaleChanged() {
    if (_isEditingByCode) return;
    _isEditingByCode = true;
    final cost = double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final sale = double.tryParse(_saleCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (cost > 0) {
      final markup = (sale / cost - 1) * 100;
      _markupCtrl.text = _fmt2(markup);
    }
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
      'status': _active ? 'Active' : 'Inactive',
      'cost': double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'markup': double.tryParse(_markupCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'salePrice': double.tryParse(_saleCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'supplier': _supplierCtrl.text.trim(),
      'reorderLevel': int.tryParse(_reorderCtrl.text) ?? 0,
      'lowStockWarning': _lowStockWarning,
      'gradient': _selectedGradient ?? (_selectedCategory != null ? categoryGradients[_selectedCategory] : null),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
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
                  '✨ Product saved: ${payload['name']}', 
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
    _costCtrl.clear();
    _markupCtrl.clear();
    _saleCtrl.clear();
    _supplierCtrl.clear();
    _reorderCtrl.clear();
    _remarkCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _selectedUnit = null;
      _active = true;
      _lowStockWarning = true;
      _selectedGradient = null;
    });
  }

  final _scrollCtrl = ScrollController();
  void _scrollToFirstError() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // ESC key - Navigate back
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
          // ENTER key - Save product
          else if (event.logicalKey == LogicalKeyboardKey.enter || 
                   event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            // Only trigger if not currently focused on a text field
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus || currentFocus.focusedChild == null) {
              _submitForm();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1623),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E3A8A),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAB308), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEAB308).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Feather.arrow_left, color: Colors.white, size: 20),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                      ).createShader(bounds),
                      child: const Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
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
                                  _dashboardDropdown(
                                    label: 'Unit',
                                    value: _selectedUnit,
                                    items: _units,
                                    onChanged: (v) => setState(() => _selectedUnit = v),
                                    validator: (v) => v == null ? 'Select unit' : null,
                                  ),
                                  _dashboardCategoryField(),
                                ]),
                                const SizedBox(height: 12),
                                _dashboardSwitch(
                                  label: 'Active Status',
                                  value: _active,
                                  onChanged: (v) => setState(() => _active = v),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Pricing Section
                            _dashboardCard(
                              icon: Feather.trending_up,
                              title: 'Pricing',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              children: [
                                _buildRow([
                                  _dashboardNumberField(
                                    controller: _costCtrl,
                                    label: 'Cost',
                                    prefix: 'Rs.',
                                    validator: _reqNum,
                                  ),
                                  _dashboardNumberField(
                                    controller: _markupCtrl,
                                    label: 'Markup',
                                    suffix: '%',
                                    validator: _reqNum,
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                _dashboardNumberField(
                                  controller: _saleCtrl,
                                  label: 'Sale Price',
                                  prefix: 'Rs.',
                                  validator: _reqNum,
                                  fullWidth: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Inventory Section
                            _dashboardCard(
                              icon: Feather.package,
                              title: 'Inventory & Supplier',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF97316), Color(0xFFEAB308)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              children: [
                                _dashboardAutocomplete(
                                  label: 'Supplier',
                                  controller: _supplierCtrl,
                                  options: _suppliers,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                _buildRow([
                                  _dashboardNumberField(
                                    controller: _reorderCtrl,
                                    label: 'Reorder Level',
                                    hint: '10',
                                    validator: _reqInt,
                                  ),
                                  Container(
                                    height: 56,
                                    alignment: Alignment.centerLeft,
                                    child: _dashboardSwitch(
                                      label: 'Low Stock Alert',
                                      value: _lowStockWarning,
                                      onChanged: (v) => setState(() => _lowStockWarning = v),
                                      compact: true,
                                    ),
                                  ),
                                ]),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Appearance Section
                            _dashboardCard(
                              icon: Feather.layers,
                              title: 'Appearance',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              children: [
                                _dashboardGradientPicker(),
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
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF475569).withOpacity(0.8),
                                          const Color(0xFF334155).withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _resetForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
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
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
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
      ),
    );
  }

  // ---------- Dashboard-Style Components ----------
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.colors.map((color) => color.withOpacity(0.1)).toList(),
          begin: gradient.begin,
          end: gradient.end,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
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
                      color: Colors.white,
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
        // Use column layout on smaller screens
        if (constraints.maxWidth < 600) {
          return Column(
            children: children
                .expand((child) => [child, const SizedBox(height: 12)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }
        
        // Use row layout on larger screens
        return Row(
          children: children
              .map((child) => Expanded(child: child))
              .expand((widget) sync* {
                yield widget;
                if (widget != children.map((child) => Expanded(child: child)).last) {
                  yield const SizedBox(width: 12);
                }
              })
              .toList(),
        );
      },
    );
  }

  InputDecoration _dashboardDecoration(String label, {String? hint, Widget? suffixIcon, String? prefixText, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
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
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: const Color(0xFF1E293B),
      decoration: _dashboardDecoration(label),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: Colors.white70, size: 20),
      isExpanded: true,
    );
  }

  Widget _dashboardBarcodeField() {
    return TextFormField(
      controller: _barcodeCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _dashboardDecoration(
        'Barcode',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.3),
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
      items: categoryGradients.entries
          .map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: e.value,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        e.key, 
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() {
        _selectedCategory = v;
        if (v != null) _selectedGradient = categoryGradients[v];
      }),
      validator: (v) => v == null ? 'Select category' : null,
      dropdownColor: const Color(0xFF1E293B),
      decoration: _dashboardDecoration('Category'),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      icon: const Icon(Feather.chevron_down, color: Colors.white70, size: 20),
      isExpanded: true,
    );
  }

  Widget _dashboardSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: compact ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label, 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact) const Spacer(),
          if (compact) const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: value 
                ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                : const LinearGradient(colors: [Color(0xFF475569), Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: value ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              inactiveThumbColor: Colors.white70,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardAutocomplete({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return options;
        return options.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _dashboardDecoration(label),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          validator: validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: options.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final opt = options.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => onSelected(opt),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            opt, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dashboardGradientPicker() {
    final currentGradient = _selectedGradient ?? (_selectedCategory != null ? categoryGradients[_selectedCategory] : null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Color Theme', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            if (currentGradient != null)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: currentGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: currentGradient.colors.first.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF475569), Color(0xFF334155)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedGradient = null),
                icon: const Icon(Feather.refresh_cw, color: Colors.white70, size: 14),
                label: const Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _gradientPalette.map((gradient) {
            final isSelected = currentGradient == gradient;
            return GestureDetector(
              onTap: () => setState(() => _selectedGradient = gradient),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(isSelected ? 0.6 : 0.3),
                      blurRadius: isSelected ? 16 : 8,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Feather.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dashboardPreview() {
    final gradient = _selectedGradient ?? (_selectedCategory != null ? categoryGradients[_selectedCategory] : null);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient ?? const LinearGradient(
                colors: [Color(0xFF475569), Color(0xFF334155)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: gradient != null ? [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: gradient != null 
                ? const Icon(Feather.package, color: Colors.white, size: 20)
                : Container(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Product Preview' : _nameCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedCategory ?? 'Category'} • ${_barcodeCtrl.text.isEmpty ? 'No Code' : _barcodeCtrl.text}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _active 
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: (_active ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _active ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _reqNum(String? v) {
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
}