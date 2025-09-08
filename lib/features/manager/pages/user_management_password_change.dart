import 'package:flutter/material.dart';
import 'package:pos_system/data/repositories/manager/user_repository.dart';


class UserManagementPasswordChangePage extends StatefulWidget {
  const UserManagementPasswordChangePage({super.key});

  @override
  State<UserManagementPasswordChangePage> createState() =>
      _UserManagementPasswordChangePageState();
}

// ------------ Simple view model for the list ------------
class UserSummary {
  final String name;
  final String email;
  final String role; // Admin, Manager, Cashier, StockKeeper
  final String colorCode; // e.g. #7C3AED
  final DateTime createdAt;

  const UserSummary({
    required this.name,
    required this.email,
    required this.role,
    required this.colorCode,
    required this.createdAt,
  });

  Color get color {
    try {
      final hex = colorCode.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return Colors.deepPurple; // fallback
  }
}

class _UserManagementPasswordChangePageState
    extends State<UserManagementPasswordChangePage> {
  // ----------------------------- State & Controllers -----------------------------
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Users panel state
  final _userSearchCtrl = TextEditingController();
  bool _loadingUsers = false;
  String? _usersError;
  List<UserSummary> _allUsers = [];
  List<UserSummary> _filteredUsers = [];

  // NEW: repository
  final _repo = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _userSearchCtrl.addListener(_applyUserFilter);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  // ----------------------------- Users: fetching & filtering -----------------------------
  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final rows = await _repo.listUsers();
      _allUsers = rows
          .map((r) => UserSummary(
                name: r.name,
                email: r.email,
                role: r.role,
                colorCode: r.colorCode,
                createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
              ))
          .toList();
      _applyUserFilter();
    } catch (e, st) {
      debugPrint('loadUsers error: $e\n$st');
      _usersError = 'Failed to load users';
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  void _applyUserFilter() {
    final q = _userSearchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredUsers = List<UserSummary>.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((u) {
          return u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  // ----------------------------- Password helpers -----------------------------
  double _passwordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'\d').hasMatch(password)) strength += 0.2;
    if (RegExp(r'''[!@#\$%^&*()_\-+={}\[\]:;'"<>,.?/\\|`~]''').hasMatch(password)) {
      strength += 0.2;
    }
    return strength.clamp(0.0, 1.0);
  }

  String _strengthLabel(double s) {
    if (s < 0.2) return 'Very Weak';
    if (s < 0.4) return 'Weak';
    if (s < 0.6) return 'Fair';
    if (s < 0.8) return 'Good';
    return 'Strong';
  }

  Color _strengthColor(double s) {
    if (s < 0.2) return Colors.red;
    if (s < 0.4) return Colors.deepOrange;
    if (s < 0.6) return Colors.amber.shade700;
    if (s < 0.8) return Colors.lightGreen.shade700;
    return Colors.green;
  }

  bool get _hasMinLen => _newPwdCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPwdCtrl.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPwdCtrl.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_newPwdCtrl.text);
  bool get _hasSpecial => RegExp(r'''[!@#\$%^&*()_\-+={}\[\]:;"'<>,.?/\\|`~]''').hasMatch(_newPwdCtrl.text);

  // --------------------------------- Submit ----------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final ok = await _repo.changePasswordByEmail(
        email: _emailCtrl.text.trim(),
        newPassword: _newPwdCtrl.text.trim(),
      );
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found for that email')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (c) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Password changed successfully for ${_emailCtrl.text.trim()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(c).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('changePassword error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error changing password')),
      );
    }
  }

  // ----------------------------------- UI ------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final strength = _passwordStrength(_newPwdCtrl.text);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'User Management • Password Change',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter the user email and a new password. Or select a registered user from the list.',
                    style: TextStyle(
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  child: Form(
                    key: _formKey,
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: password form + requirements
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormFields(strength),
                                    const SizedBox(height: 20),
                                    _buildRequirementsPanel(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right: users list
                              Expanded(flex: 4, child: _buildUsersPanel()),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormFields(strength),
                              const SizedBox(height: 20),
                              _buildRequirementsPanel(),
                              const SizedBox(height: 20),
                              _buildUsersPanel(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Change Password'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------- Sub-widgets --------------------------------
  Widget _buildFormFields(double strength) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailCtrl,
          label: 'User Email',
          icon: Icons.alternate_email,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
              return 'Invalid email';
            }
            return null;
          },
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _newPwdCtrl,
          label: 'New Password',
          icon: Icons.lock,
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}), // refresh strength & checklist
          suffix: IconButton(
            tooltip: _obscureNew ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscureNew ? Icons.visibility : Icons.visibility_off,
              color: Colors.deepPurple,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 8) return 'At least 8 characters';
            if (!(_hasUpper && _hasLower && _hasDigit && _hasSpecial)) {
              return 'Does not meet requirements';
            }
            return null;
          },
        ),

        const SizedBox(height: 10),
        // Strength meter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: _strengthColor(strength).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _strengthColor(strength).withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: strength,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  color: _strengthColor(strength),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: _strengthColor(strength)),
                  const SizedBox(width: 6),
                  Text(
                    'Strength: ${_strengthLabel(strength)}',
                    style: TextStyle(
                      color: _strengthColor(strength),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildTextField(
          controller: _confirmCtrl,
          label: 'Confirm Password',
          icon: Icons.verified_user,
          obscureText: _obscureConfirm,
          suffix: IconButton(
            tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscureConfirm ? Icons.visibility : Icons.visibility_off,
              color: Colors.deepPurple,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v != _newPwdCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRequirementsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Password Requirements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _reqItem('At least 8 characters', _hasMinLen),
          _reqItem('At least one uppercase letter (A–Z)', _hasUpper),
          _reqItem('At least one lowercase letter (a–z)', _hasLower),
          _reqItem('At least one number (0–9)', _hasDigit),
          _reqItem('At least one special character (!@#\$…)', _hasSpecial),
          const SizedBox(height: 8),
          Text(
            'Tip: Use a passphrase with spaces (if allowed) for better memorability.',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.people_alt, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Registered Users',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          TextField(
            controller: _userSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or role…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          SizedBox(
            height: 360,
            child: _usersError != null
                ? Center(
                    child: Text(
                      _usersError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _loadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: _filteredUsers.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('No users found')),
                                ],
                              )
                            : ListView.separated(
                                itemCount: _filteredUsers.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey[300], height: 1),
                                itemBuilder: (context, i) {
                                  final u = _filteredUsers[i];
                                  final initials = _initials(u.name);
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _emailCtrl.text = u.email,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: u.color,
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        u.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${u.email} • ${u.role} • Joined ${_ymd(u.createdAt)}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      trailing: TextButton.icon(
                                        onPressed: () {
                                          _emailCtrl.text = u.email;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Selected ${u.email}')),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.person_add_alt_1,
                                          color: Colors.deepPurple,
                                        ),
                                        label: const Text(
                                          'Select',
                                          style: TextStyle(color: Colors.deepPurple),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.isEmpty ? '?' : s.characters.take(2).toString().toUpperCase());
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  Widget _reqItem(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: ok ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ok ? Colors.green.shade800 : Colors.grey.shade800,
                fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.deepPurple),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}
