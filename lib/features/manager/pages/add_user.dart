// lib/features/manager/users/add_user.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';


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

  // Accent color (stored as #RRGGBB)
  static const _palette = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
    Color(0xFF000000),
  ];
  Color _swatch = const Color(0xFF3B82F6);

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
      final hex = (d['color_code'] ?? '#3B82F6').toString();
      _swatch = _colorFromHex(hex);
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

  // --- helpers ---------------------------------------------------------------

  String _hash(String s) => sha256.convert(utf8.encode(s)).toString();

  String _hexFromColor(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse('FF$clean', radix: 16) ?? 0xFF3B82F6;
    return Color(value);
  }

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
    final db = await DatabaseHelper.instance.database;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final contact = _contactCtrl.text.trim();
      final role = _role;
      final colorCode = _hexFromColor(_swatch);

      // Unique email check
      final existing = await db.query(
        'user',
        where: _isEdit ? 'email = ? AND id != ?' : 'email = ?',
        whereArgs: _isEdit ? [email, widget.userData!['id']] : [email],
        columns: const ['id'],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw Exception('Email already exists');
      }

      if (_isEdit) {
        final values = <String, Object?>{
          'name': name,
          'email': email,
          'contact': contact,
          'role': role,
          'color_code': colorCode,
          'updated_at': now,
        };
        if (_changePassword) {
          values['password'] = _hash(_passwordCtrl.text.trim());
        }

        await db.update(
          'user',
          values,
          where: 'id = ?',
          whereArgs: [widget.userData!['id']],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      } else {
        await db.insert(
          'user',
          {
            'name': name,
            'email': email,
            'contact': contact,
            'password': _hash(_passwordCtrl.text.trim()),
            'role': role,
            'color_code': colorCode,
            'created_at': now,
            'updated_at': now,
            'refresh_token_hash': null,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'User updated' : 'User created'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, color: Colors.white),
            label: Text(isEdit ? 'Update' : 'Save',
                style: const TextStyle(color: Colors.white)),
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
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                        decoration: _decoration('Role'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  title: 'Appearance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Accent Color',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _palette.map((c) {
                          final sel = c.value == _swatch.value;
                          return GestureDetector(
                            onTap: () => setState(() => _swatch = c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel ? Colors.black : Colors.black26,
                                  width: sel ? 2 : 1,
                                ),
                              ),
                              child: sel
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
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
                          title:
                              const Text('Change password for this account'),
                          value: _changePassword,
                          onChanged: (v) =>
                              setState(() => _changePassword = v),
                        ),
                      if (!isEdit || _changePassword) ...[
                        _tf(
                          controller: _passwordCtrl,
                          label: 'Password',
                          validator: _pw,
                          obscureText: !_showPw,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showPw ? Icons.visibility_off : Icons.visibility),
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
                            icon: Icon(_showPw2
                                ? Icons.visibility_off
                                : Icons.visibility),
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
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(isEdit ? 'Update User' : 'Create User'),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      obscureText: obscureText,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
