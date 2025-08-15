import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_vector_icons/flutter_vector_icons.dart";

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key, required this.supplierData});

  final Map supplierData;

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();

  // State variables
  bool _active = true;
  bool _preferredSupplier = false;
  List<String> _locations = [];
  String? _paymentTerms;

  // Color palette matching your project's style
  final List<LinearGradient> _gradientPalette = const [
    LinearGradient(
      colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
    ), // Blue-Purple
    LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEAB308)],
    ), // Orange-Yellow
    LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), // Green
    LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]), // Pink-Red
    LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFEC4899)]), // Red-Pink
    LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]), // Purple
    LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]), // Cyan-Blue
    LinearGradient(
      colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
    ), // Lime-Green
    LinearGradient(
      colors: [Color(0xFF475569), Color(0xFF334155)],
    ), // Gray-Slate
  ];

  LinearGradient? _selectedGradient;
  final List<String> _paymentOptions = const [
    'Cash',
    'Credit 7 Days',
    'Credit 15 Days',
    'Credit 30 Days',
    'Credit 60 Days',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Set default gradient
    _selectedGradient = _gradientPalette[0];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _brandCtrl.dispose();
    _locationCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  // Location management
  void _addLocation() {
    if (_locationCtrl.text.trim().isNotEmpty) {
      setState(() {
        _locations.add(_locationCtrl.text.trim());
        _locationCtrl.clear();
      });
    }
  }

  void _removeLocation(int index) {
    setState(() {
      _locations.removeAt(index);
    });
  }

  // Form submission
  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    var payload = {
      "id": _idCtrl.text.trim(),
      "name": _nameCtrl.text.trim(),
      "contact": _contactCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "brand": _brandCtrl.text.trim(),
      "locations": _locations,
      "paymentTerms": _paymentTerms,
      "active": _active,
      "preferredSupplier": _preferredSupplier,
      "colorGradient": _selectedGradient,
      "remarks": _remarkCtrl.text.trim(),
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
            children: [
              const Icon(Feather.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                '✨ Supplier saved: ${payload['name']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
    _idCtrl.clear();
    _nameCtrl.clear();
    _contactCtrl.clear();
    _emailCtrl.clear();
    _brandCtrl.clear();
    _locationCtrl.clear();
    _remarkCtrl.clear();
    setState(() {
      _active = true;
      _preferredSupplier = false;
      _locations.clear();
      _paymentTerms = null;
      _selectedGradient = _gradientPalette[0];
    });
  }

  final _scrollCtrl = ScrollController();
  void _scrollToFirstError() {
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            var currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus ||
                currentFocus.focusedChild == null) {
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
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
            ),
          ),
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
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
                    icon: const Icon(
                      Feather.arrow_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                    ).createShader(bounds),
                    child: const Text(
                      "Add Supplier",
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
                          // Basic Information Section
                          _dashboardCard(
                            icon: Feather.info,
                            title: "Basic Information",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            children: [
                              _buildRow([
                                _dashboardTextField(
                                  controller: _idCtrl,
                                  label: "Supplier ID",
                                  hint: "Ex: SUP001",
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                _dashboardTextField(
                                  controller: _nameCtrl,
                                  label: "Supplier Name",
                                  hint: "Ex: ABC Traders",
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ]),
                              const SizedBox(height: 12),
                              _buildRow([
                                _dashboardTextField(
                                  controller: _contactCtrl,
                                  label: "Contact Number",
                                  hint: "071-2345678",
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                _dashboardTextField(
                                  controller: _emailCtrl,
                                  label: "Email (Optional)",
                                  hint: "supplier@email.com",
                                ),
                              ]),
                              const SizedBox(height: 12),
                              _dashboardTextField(
                                controller: _brandCtrl,
                                label: "Brand/Company",
                                hint: "Associated brand or company name",
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 12),
                              _buildRow([
                                _dashboardSwitch(
                                  label: "Active Status",
                                  value: _active,
                                  onChanged: (v) => setState(() => _active = v),
                                ),
                                _dashboardSwitch(
                                  label: "Preferred Supplier",
                                  value: _preferredSupplier,
                                  onChanged: (v) =>
                                      setState(() => _preferredSupplier = v),
                                  compact: true,
                                ),
                              ]),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Payment & Terms Section
                          _dashboardCard(
                            icon: Feather.credit_card,
                            title: "Payment & Terms",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            children: [
                              _dashboardDropdown(
                                label: "Payment Terms",
                                value: _paymentTerms,
                                items: _paymentOptions,
                                onChanged: (v) =>
                                    setState(() => _paymentTerms = v),
                                validator: (v) =>
                                    v == null ? 'Select payment terms' : null,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Locations Section
                          _dashboardCard(
                            icon: Feather.map_pin,
                            title: "Locations",
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEAB308)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _dashboardTextField(
                                      controller: _locationCtrl,
                                      label: "Add Location",
                                      hint: "Ex: Colombo, Kandy",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF60A5FA),
                                          Color(0xFFA855F7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF60A5FA,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _addLocation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Feather.plus,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_locations.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Added Locations:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _locations
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              int index = entry.key;
                                              String location = entry.value;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF475569),
                                                          Color(0xFF334155),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Feather.map_pin,
                                                      color: Colors.white70,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      location,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _removeLocation(
                                                            index,
                                                          ),
                                                      child: const Icon(
                                                        Feather.x,
                                                        color: Colors.red,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Appearance & Notes Section
                          _dashboardCard(
                            icon: Feather.layers,
                            title: "Appearance & Notes",
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            children: [
                              _dashboardGradientPicker(),
                              const SizedBox(height: 16),
                              _dashboardTextField(
                                controller: _remarkCtrl,
                                label: "Remarks/Notes",
                                hint: "Optional notes about the supplier",
                                maxLines: 3,
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
                                        const Color(
                                          0xFF475569,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xFF334155,
                                        ).withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _resetForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Feather.refresh_cw,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Reset",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.3),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Feather.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Save Supplier",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
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
          colors: gradient.colors
              .map((color) => color.withOpacity(0.1))
              .toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
    return Row(
      children: children.map((child) => Expanded(child: child)).expand((
        widget,
      ) sync* {
        yield widget;
        if (widget != children.map((child) => Expanded(child: child)).last) {
          yield const SizedBox(width: 12);
        }
      }).toList(),
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
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _dashboardDecoration(label, hint: hint),
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
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: const Color(0xFF1E293B),
      decoration: _dashboardDecoration(label),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      icon: const Icon(Feather.chevron_down, color: Colors.white70, size: 20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              inactiveThumbColor: Colors.white70,
              activeTrackColor: value
                  ? const Color(0xFF10B981)
                  : const Color(0xFF475569),
              inactiveTrackColor: const Color(0xFF475569),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashRadius: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardGradientPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Color Theme",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedGradient != null)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _selectedGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedGradient!.colors.first.withOpacity(0.4),
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
                onPressed: () =>
                    setState(() => _selectedGradient = _gradientPalette[0]),
                icon: const Icon(
                  Feather.refresh_cw,
                  color: Colors.white70,
                  size: 14,
                ),
                label: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
            final isSelected = _selectedGradient == gradient;
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
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(
                        isSelected ? 0.6 : 0.3,
                      ),
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
              gradient:
                  _selectedGradient ??
                  const LinearGradient(
                    colors: [Color(0xFF475569), Color(0xFF334155)],
                  ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _selectedGradient != null
                  ? [
                      BoxShadow(
                        color: _selectedGradient!.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: const Icon(Feather.truck, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? "Supplier Preview" : _nameCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_brandCtrl.text.isEmpty ? "Brand" : _brandCtrl.text} • ${_contactCtrl.text.isEmpty ? "No Contact" : _contactCtrl.text}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                if (_locations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${_locations.length} Location${_locations.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _active
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_active
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _active ? "Active" : "Inactive",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_preferredSupplier) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAB308), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⭐ PREFERRED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
