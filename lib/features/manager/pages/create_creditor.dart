import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../widgets/gradient_scaffold.dart';
import '../../../widgets/pastel_text_field.dart';

// If AppColors and colorfulTheme are not defined in app_theme.dart, define them below:
class AppColors {
  static const purple = Color(0xFF7C3AED);
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF14B8A6);
  static const amber = Color(0xFFF59E42);
  static const pink = Color(0xFFEC4899);
  static const red = Color(0xFFEF4444);
  static const border = Color(0xFFE5E7EB);
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFFF59E42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData colorfulTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
      useMaterial3: true,
    );
  }
}

class CreateCreditorPage extends StatefulWidget {
  const CreateCreditorPage({super.key});

  @override
  CreateCreditorPageState createState() => CreateCreditorPageState();
}

class CreateCreditorPageState extends State<CreateCreditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _address = TextEditingController();

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
      // Example payload:
      final payload = {
        "businessName": _businessName.text.trim(),
        "phone": _phone.text.trim(),
        "email": _email.text.trim(),
        "contactPerson": _contact.text.trim(),
        "address": _address.text.trim(),
      };
      debugPrint("Saving Creditor: $payload");

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 650));

      if (andNew) {
        _formKey.currentState!.reset();
        _businessName.clear();
        _phone.clear();
        _email.clear();
        _contact.clear();
        _address.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved. Ready for a new creditor.')),
          );
        }
      } else {
        if (mounted) Navigator.of(context).pop(true);
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.enter): const SaveNewIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (i) {
            _doSave(andNew: false);
            return null;
          }),
          SaveNewIntent: CallbackAction<SaveNewIntent>(onInvoke: (i) {
            _doSave(andNew: true);
            return null;
          }),
          CancelIntent: CallbackAction<CancelIntent>(onInvoke: (i) {
            Navigator.of(context).maybePop();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Theme(
            data: AppTheme.colorfulTheme(),
            child: GradientScaffold(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Row(
                            children: const [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFE9D5FF),
                                child: Icon(Icons.apartment, color: AppColors.purple),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Basic Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Who is this creditor and how can we reach them?',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 22),

                          // Grid (responsive)
                          LayoutBuilder(
                            builder: (context, c) {
                              final twoCols = c.maxWidth > 680;
                              return Wrap(
                                runSpacing: 16,
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    width: twoCols ? c.maxWidth / 2 - 8 : c.maxWidth,
                                    child: PastelTextField(
                                      controller: _businessName,
                                      hint: 'Business Name *',
                                      icon: Icons.business,
                                      iconColor: AppColors.blue,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Business name is required'
                                          : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: twoCols ? c.maxWidth / 2 - 8 : c.maxWidth,
                                    child: PastelTextField(
                                      controller: _phone,
                                      hint: 'Phone Number',
                                      icon: Icons.phone,
                                      iconColor: AppColors.teal,
                                      keyboardType: TextInputType.phone,
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
                                    width: twoCols ? c.maxWidth / 2 - 8 : c.maxWidth,
                                    child: PastelTextField(
                                      controller: _email,
                                      hint: 'Email Address',
                                      icon: Icons.email,
                                      iconColor: AppColors.amber,
                                      keyboardType: TextInputType.emailAddress,
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
                                    width: twoCols ? c.maxWidth / 2 - 8 : c.maxWidth,
                                    child: PastelTextField(
                                      controller: _contact,
                                      hint: 'Contact Person',
                                      icon: Icons.person,
                                      iconColor: AppColors.pink,
                                    ),
                                  ),
                                  SizedBox(
                                    width: twoCols ? c.maxWidth / 2 - 8 : c.maxWidth,
                                    child: PastelTextField(
                                      controller: _address,
                                      hint: 'Business Address',
                                      icon: Icons.location_on,
                                      iconColor: AppColors.red,
                                      maxLines: 3,
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
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel  (Esc)'),
                              ),
                              const Spacer(),
                              // Save
                              GradientButton(
                                label: 'Save  (Ctrl+Enter)',
                                gradient: AppColors.primaryGradient,
                                onPressed: _saving ? null : () => _doSave(andNew: false),
                                loading: _saving,
                              ),
                              const SizedBox(width: 12),
                              // Save & New
                              GradientButton(
                                label: 'Save & New  (Ctrl+Shift+Enter)',
                                gradient: AppColors.secondaryGradient,
                                onPressed: _saving ? null : () => _doSave(andNew: true),
                                loading: _saving,
                              ),
                            ],
                          )
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

// Move these intent classes outside of CreateCreditorPageState
class ActivateIntent extends Intent {
  const ActivateIntent();
}

class SaveNewIntent extends Intent {
  const SaveNewIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.loading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btnChild = loading
        ? const SizedBox(
            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: btnChild,
      ),
    );
  }
}