import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'session.dart';

enum LoginStage { username, password }

class TwoStepLoginPage extends StatefulWidget {
  const TwoStepLoginPage({super.key});

  @override
  State<TwoStepLoginPage> createState() => _TwoStepLoginPageState();
}

class _TwoStepLoginPageState extends State<TwoStepLoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginStage _stage = LoginStage.username;
  bool _loading = false;
  String? _username;
  List<String> _roles = [];
  String? _selectedRole;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitUsername() async {
    final name = _usernameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Please enter your username');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final roles = await auth.checkUsername(name); // from seed or backend
      setState(() {
        _username = name;
        _roles = roles;
        _selectedRole = _roles.length == 1 ? _roles.first : null;
        _stage = LoginStage.password;
      });
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitPassword() async {
    if (_passwordCtrl.text.isEmpty) {
      _toast('Please enter your password');
      return;
    }
    if (_roles.isNotEmpty && _selectedRole == null) {
      _toast('Please select a role');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.login(
        _username!,
        _passwordCtrl.text,
        role: _selectedRole ?? (_roles.isNotEmpty ? _roles.first : null),
      );

      // Optional persistence if you use Session
      await Session.instance.saveToken(
        auth.currentUser!.token,
        role: auth.currentUser!.role,
      );

      _navigateByRole(auth.currentUser!.role);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateByRole(String? role) {
    // Clear back stack so user can't go back to any role-selection page
    void go(String route) =>
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);

    final r = (role ?? '').toUpperCase();
    if (r.contains('ADMIN')) {
      go('/admin');
    } else if (r.contains('STOCK')) {
      go('/stockkeeper');
    } else if (r.contains('MANAGER')) {
      go('/manager');
    } else if (r.contains('CASHIER')) {
      go('/cashier');
    } else {
      _toast('Unknown role: $role');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isUsernameStage = _stage == LoginStage.username;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1623), Color(0xFF0E1D2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.lock_outline, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'POS Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .1),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: isUsernameStage
                        ? _UsernameStep(
                            key: const ValueKey('username-step'),
                            controller: _usernameCtrl,
                            loading: _loading,
                            onSubmit: _submitUsername,
                          )
                        : _PasswordStep(
                            key: const ValueKey('password-step'),
                            username: _username!,
                            controller: _passwordCtrl,
                            roles: _roles,
                            selectedRole: _selectedRole,
                            onRoleChanged: (v) => setState(() => _selectedRole = v),
                            loading: _loading,
                            onBack: () => setState(() => _stage = LoginStage.username),
                            onSubmit: _submitPassword,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Step widgets ---------- */

class _UsernameStep extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  const _UsernameStep({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Enter your username',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const SizedBox(height: 8),
        _GlowField(
          hint: 'Username',
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: loading ? 'Checking...' : 'Continue',
          onPressed: loading ? null : onSubmit,
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final String username;
  final TextEditingController controller;
  final List<String> roles;
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _PasswordStep({
    super.key,
    required this.username,
    required this.controller,
    required this.roles,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.loading,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Hello, $username',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const SizedBox(height: 8),
        _GlowField(
          hint: 'Password',
          controller: controller,
          obscure: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (roles.length > 1) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((r) {
                final selected = r == selectedRole;
                return ChoiceChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (_) => onRoleChanged(r),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.22),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Back',
                onPressed: loading ? null : onBack,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryButton(
                label: loading ? 'Signing in...' : 'Sign in',
                onPressed: loading ? null : onSubmit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ---------- Reusable UI widgets ---------- */

class _GlowField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _GlowField({
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focus ? Colors.white : Colors.white.withOpacity(0.14),
                width: 1.2,
              ),
              boxShadow: focus
                  ? [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 12, spreadRadius: 1)]
                  : [],
            ),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onSubmitted: onSubmitted,
              textInputAction: textInputAction,
              style: const TextStyle(color: Colors.white, fontSize: 15.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.black),
        backgroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
        elevation: WidgetStateProperty.all(8),
        shadowColor: WidgetStateProperty.all(Colors.black.withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(
          BorderSide(color: Colors.white.withOpacity(0.45), width: 1.2),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
