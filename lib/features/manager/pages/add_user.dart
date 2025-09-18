// lib/features/manager/users/add_user.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos_system/data/models/manager/adduser/user_model.dart';
import 'package:pos_system/data/repositories/manager/adduser/user_repository.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key, this.userData});

  /// Pass `null` to create; pass a map (with at least `id`) to edit.
  final Map<String, dynamic>? userData;

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // State
  String _role = 'Cashier';
  bool _changePassword = false; // used only in edit mode
  bool _showPw = false;
  bool _showPw2 = false;

  final _roles = const ['Admin', 'Manager', 'Cashier', 'StockKeeper'];

  bool get _isEdit => widget.userData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.userData!;
      _nameCtrl.text = (d['name'] ?? '').toString();
      _emailCtrl.text = (d['email'] ?? '').toString();
      _contactCtrl.text = (d['contact'] ?? '').toString();
      _role = (d['role'] ?? 'Cashier').toString();
      _changePassword = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // --- validators ------------------------------------------------------------

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(v.trim())) return 'Invalid email';
    return null;
  }

  String? _phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 12) return 'Invalid phone';
    return null;
  }

  String? _pw(String? v) {
    if (_isEdit && !_changePassword) return null;
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 6) return 'At least 6 characters';
    return null;
  }

  String? _pw2(String? v) {
    if (_isEdit && !_changePassword) return null;
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim() != _passwordCtrl.text.trim()) return 'Passwords do not match';
    return null;
  }

  // --- save ------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final contact = _contactCtrl.text.trim();
      final role = _role;

      // Always save user color as black (hex)
      const colorCode = '#000000';

      final repo = UserRepository.instance;

      if (_isEdit) {
        final current = widget.userData!;
        final model = User(
          id: (current['id'] as num).toInt(),
          name: name,
          email: email,
          contact: contact,
          passwordHash: (current['password'] ?? '') as String, // unchanged unless toggled
          role: role,
          colorCode: colorCode,
          createdAt: (current['created_at'] as num?)?.toInt() ?? now,
          updatedAt: now,
          refreshTokenHash: current['refresh_token_hash'] as String?,
        );

        // Optional password change
        final newPw = _changePassword ? _passwordCtrl.text.trim() : null;
        await repo.update(model, newPlainPassword: newPw);
      } else {
        final model = User(
          name: name,
          email: email,
          contact: contact,
          // Placeholder; repository will hash if plainPassword is provided
          passwordHash: 'TO_BE_REPLACED',
          role: role,
          colorCode: colorCode,
          createdAt: now,
          updatedAt: now,
          refreshTokenHash: null,
        );
        await repo.create(model, plainPassword: _passwordCtrl.text.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved successfully', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEdit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(
          isEdit ? 'Edit User' : 'Add User',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(isEdit ? 'Update' : 'Save',
                style: const TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _card(
                  title: 'Basic Info',
                  child: Column(
                    children: [
                      _tf(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        validator: _req,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _tf(
                        controller: _emailCtrl,
                        label: 'Email',
                        validator: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _tf(
                        controller: _contactCtrl,
                        label: 'Contact Number',
                        validator: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))
                        ],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: _roles
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.black))))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                        decoration: _decoration('Role'),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  title: isEdit ? 'Password (optional)' : 'Password',
                  child: Column(
                    children: [
                      if (isEdit)
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Change password for this account',
                              style: TextStyle(color: Colors.black)),
                          value: _changePassword,
                          onChanged: (v) =>
                              setState(() => _changePassword = v),
                          activeColor: Colors.black,
                        ),
                      if (!isEdit || _changePassword) ...[
                        _tf(
                          controller: _passwordCtrl,
                          label: 'Password',
                          validator: _pw,
                          obscureText: !_showPw,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPw ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black,
                            ),
                            onPressed: () => setState(() => _showPw = !_showPw),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _tf(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          validator: _pw2,
                          obscureText: !_showPw2,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPw2 ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black,
                            ),
                            onPressed: () =>
                                setState(() => _showPw2 = !_showPw2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.black12,
                      elevation: 1.5,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isEdit ? 'Update User' : 'Create User',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- small UI helpers ------------------------------------------------------

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
        ),
      );

  Widget _tf({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      obscureText: obscureText,
      cursorColor: Colors.black,
      decoration: _decoration(label).copyWith(suffixIcon: suffixIcon),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
