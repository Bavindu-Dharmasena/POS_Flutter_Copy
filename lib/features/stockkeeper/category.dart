import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/data/models/stockkeeper/add_category_model.dart' show Category;
import 'package:pos_system/data/repositories/stockkeeper/category_repository.dart';


class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  // ==== UI Theme ====
  static const Color kBg = Color(0xFF0B1623);
  static const Color kSurface = Color(0xFF121A26);
  static const Color kBorder = Color(0x1FFFFFFF);
  static const Color kText = Colors.white;
  static const Color kTextMuted = Colors.white70;
  static const Color kHint = Colors.white38;
  static const Color kPrimary = Color(0xFF3B82F6);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kDanger = Color(0xFFEF4444);

  // Controllers and state
  final TextEditingController _categoryNameCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CategoryRepository _categoryRepo = CategoryRepository.instance;
  
  bool _isLoading = false;
  Color _selectedColor = const Color(0xFF3B82F6); // Default color

  // Palette of colors for the user to select from
  final List<Color> _colorPalette = const [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF14B8A6), // Teal
    Color(0xFF64748B), // Slate
  ];

  @override
  void dispose() {
    _categoryNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // Convert Color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Add new category to database
  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Category object
      final category = Category(
        category: _categoryNameCtrl.text.trim(),
        colorCode: _colorToHex(_selectedColor),
        categoryImage: null, // You can add image selection later
      );

      // Save to database
      final categoryId = await _categoryRepo.createCategory(category);
      
      if (mounted) {
        _showSnack(
          'Category "${category.category}" added successfully!',
          icon: Feather.check_circle,
          color: kSuccess,
        );
        
        _resetForm();
        
        // Navigate back with result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          icon: Feather.alert_triangle,
          color: kDanger,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Reset the form
  void _resetForm() {
    _categoryNameCtrl.clear();
    _descriptionCtrl.clear();
    _formKey.currentState?.reset();
    setState(() {
      _selectedColor = _colorPalette[0]; // Reset to first color
    });
  }

  // Validate category name
  Future<String?> _validateCategoryName(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Category name must be less than 50 characters';
    }
    
    // Check for special characters
    final regex = RegExp(r'^[a-zA-Z0-9\s&-]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Category name can only contain letters, numbers, spaces, & and -';
    }
    
    return null;
  }

  // Show a snackbar with a message
  void _showSnack(String message, {Color color = kSuccess, IconData icon = Feather.check_circle}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Feather.arrow_left, color: kText),
        ),
        title: const Text(
          'Add New Category',
          style: TextStyle(
            color: kText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Feather.folder_plus,
                        color: kPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Category',
                      style: TextStyle(
                        color: kText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a new category to organize your items better',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Form section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name input
                    const Text(
                      'Category Name',
                      style: TextStyle(
                        color: kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryNameCtrl,
                      style: const TextStyle(color: kText),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g., Electronics, Food & Beverages',
                        hintStyle: const TextStyle(color: kHint),
                        filled: true,
                        fillColor: kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kDanger),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Feather.folder,
                          color: kTextMuted,
                          size: 20,
                        ),
                      ),
                      validator: (value) => _validateCategoryName(value).call(),
                    ),
                    
                    const SizedBox(height: 24),

                    // Color selection
                    const Text(
                      'Category Color',
                      style: TextStyle(
                        color: kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Selected: ${_colorToHex(_selectedColor)}',
                                style: const TextStyle(
                                  color: kTextMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _colorPalette.map((color) {
                              final isSelected = _selectedColor == color;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = color),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 2.5)
                                        : Border.all(color: Colors.transparent, width: 2.5),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Feather.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Notes section (optional info)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Feather.info,
                            color: kPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Categories help organize your items and make them easier to find. Choose a distinctive color for visual identification.',
                              style: TextStyle(
                                color: kPrimary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Feather.plus, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Add Category',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Future<String?> {
  call() {}
}