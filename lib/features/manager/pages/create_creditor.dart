import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widget/manager/gradient_scaffold.dart';
import '../../../widget/manager/pastel_text_field.dart';

/// If your project already defines `AppColors` and a theme, remove the
/// classes below and import them from your central theme module instead.
class AppColors {
  // Brand hues
  static const purple = Color(0xFF7C3AED);
  static const blue   = Color(0xFF2563EB);
  static const teal   = Color(0xFF14B8A6);
  static const amber  = Color(0xFFF59E42);
  static const pink   = Color(0xFFEC4899);
  static const red    = Color(0xFFEF4444);

  // Surfaces / borders
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark  = Color(0x22FFFFFF);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)], // purple → blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFFF59E42)], // teal → amber
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Panel background gradients (light/dark)
  static const backgroundGradientLight = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F1A28), Color(0xFF0B1623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData colorfulTheme() {
    final cs = ColorScheme.fromSeed(seedColor: AppColors.purple, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x22000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x22000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
        prefixIconColor: Colors.black45,
      ),
      dividerTheme: const DividerThemeData(color: Color(0x22000000), thickness: .8),
    );
  }
}

class CreateCreditorPage extends StatefulWidget {
  const CreateCreditorPage({super.key});

  @override
  State<CreateCreditorPage> createState() => _CreateCreditorPageState();
}

class _CreateCreditorPageState extends State<CreateCreditorPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessName = TextEditingController();
  final _phone        = TextEditingController();
  final _email        = TextEditingController();
  final _contact      = TextEditingController();
  final _address      = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _phone.dispose();
    _email.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _doSave({required bool andNew}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = {
        "businessName": _businessName.text.trim(),
        "phone": _phone.text.trim(),
        "email": _email.text.trim(),
        "contactPerson": _contact.text.trim(),
        "address": _address.text.trim(),
      };
      debugPrint("Saving Creditor: $payload");

      // TODO: replace with real API call
      await Future.delayed(const Duration(milliseconds: 650));

      if (!mounted) return;
      if (andNew) {
        _formKey.currentState!.reset();
        _businessName.clear();
        _phone.clear();
        _email.clear();
        _contact.clear();
        _address.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved. Ready for a new creditor.')),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard shortcuts
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter, control: true): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true, shift: true): SaveNewIntent(),
        SingleActivator(LogicalKeyboardKey.escape): CancelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
            _doSave(andNew: false);
            return null;
          }),
          SaveNewIntent: CallbackAction<SaveNewIntent>(onInvoke: (_) {
            _doSave(andNew: true);
            return null;
          }),
          CancelIntent: CallbackAction<CancelIntent>(onInvoke: (_) {
            Navigator.of(context).maybePop();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Theme( // local theme wrapper (optional)
            data: AppTheme.colorfulTheme(),
            child: GradientScaffold(
              // If your GradientScaffold supports custom background, it can use:
              // backgroundGradient: Theme.of(context).brightness == Brightness.dark
              //   ? AppColors.backgroundGradientDark
              //   : AppColors.backgroundGradientLight,
              appBar: AppBar(
                title: const Text('Create Creditor'),
                centerTitle: false,
                elevation: 0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFE9D5FF),
                                child: Icon(Icons.apartment, color: AppColors.purple),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Basic Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Who is this creditor and how can we reach them?',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Grid (responsive)
                          LayoutBuilder(
                            builder: (context, c) {
                              final twoCols = c.maxWidth > 680;
                              final halfW  = twoCols ? (c.maxWidth / 2 - 8) : c.maxWidth;
                              final fullW  = c.maxWidth;

                              return Wrap(
                                runSpacing: 16,
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    width: halfW,
                                    child: PastelTextField(
                                      controller: _businessName,
                                      hint: 'Business Name *',
                                      icon: Icons.business,
                                      iconColor: AppColors.blue,
                                      inputFormatters: const [],
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: halfW,
                                    child: PastelTextField(
                                      controller: _phone,
                                      hint: 'Phone Number',
                                      icon: Icons.phone,
                                      iconColor: AppColors.teal,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-()\s]')),
                                      ],
                                      validator: (v) {
                                        final t = v?.trim() ?? '';
                                        if (t.isEmpty) return null;
                                        final reg = RegExp(r'^[0-9+\-()\s]{7,}$');
                                        if (!reg.hasMatch(t)) return 'Invalid phone number';
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: halfW,
                                    child: PastelTextField(
                                      controller: _email,
                                      hint: 'Email Address',
                                      icon: Icons.email,
                                      iconColor: AppColors.amber,
                                      keyboardType: TextInputType.emailAddress,
                                      inputFormatters: const [],
                                      validator: (v) {
                                        final t = v?.trim() ?? '';
                                        if (t.isEmpty) return null;
                                        final reg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                        if (!reg.hasMatch(t)) return 'Invalid email address';
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: halfW,
                                    child: PastelTextField(
                                      controller: _contact,
                                      hint: 'Contact Person',
                                      icon: Icons.person,
                                      iconColor: AppColors.pink,
                                      inputFormatters: const [],
                                    ),
                                  ),
                                  // Address — full width for readability
                                  SizedBox(
                                    width: fullW,
                                    child: PastelTextField(
                                      controller: _address,
                                      hint: 'Business Address',
                                      icon: Icons.location_on,
                                      iconColor: AppColors.red,
                                      maxLines: 3,
                                      inputFormatters: const [],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 26),
                          const Divider(height: 1),
                          const SizedBox(height: 18),

                          // Footer buttons
                          Row(
                            children: [
                              // Cancel
                              OutlinedButton.icon(
                                onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                  side: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel  (Esc)'),
                              ),
                              const Spacer(),
                              // Save
                              _GradientButton(
                                label: 'Save  (Ctrl+Enter)',
                                gradient: AppColors.primaryGradient,
                                onPressed: _saving ? null : () => _doSave(andNew: false),
                                loading: _saving,
                              ),
                              const SizedBox(width: 12),
                              // Save & New
                              _GradientButton(
                                label: 'Save & New  (Ctrl+Shift+Enter)',
                                gradient: AppColors.secondaryGradient,
                                onPressed: _saving ? null : () => _doSave(andNew: true),
                                loading: _saving,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Intents used by keyboard shortcuts
class ActivateIntent extends Intent { const ActivateIntent(); }
class SaveNewIntent extends Intent { const SaveNewIntent(); }
class CancelIntent   extends Intent { const CancelIntent(); }

/// Gradient action button used in the footer
class _GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final bool loading;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnChild = loading
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w600));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: btnChild,
      ),
    );
  }
}
