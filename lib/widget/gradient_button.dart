import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_controller.dart';

/// This page expects a top-level `late ThemeController themeController;`
/// to be assigned from `main.dart`, e.g.:
///   themeController = ThemeController(); await themeController.load(); page.themeController = themeController;
late ThemeController themeController;

class CreateCreditorPage extends StatefulWidget {
  const CreateCreditorPage({super.key});

  @override
  State<CreateCreditorPage> createState() => _CreateCreditorPageState();
}

/// Gradient primary action button (independent of current theme colors)
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.actionGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: canTap
            ? [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 8))]
            : const [],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCreditorPageState extends State<CreateCreditorPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _person = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _person.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Creditor'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Theme',
            icon: Icon(
              themeController.isDark
                  ? Icons.dark_mode
                  : themeController.isLight
                      ? Icons.light_mode
                      : Icons.brightness_6, // system
            ),
            onSelected: (v) {
              if (v == 'Light')  themeController.set(ThemeMode.light);
              if (v == 'Dark')   themeController.set(ThemeMode.dark);
              if (v == 'System') themeController.set(ThemeMode.system);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'Light',  child: Text('Light')),
              PopupMenuItem(value: 'Dark',   child: Text('Dark')),
              PopupMenuItem(value: 'System', child: Text('Follow system')),
            ],
          ),
          IconButton(
            tooltip: 'Quick toggle',
            icon: Icon(themeController.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeController.toggle(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient(b),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.panelBorder(b)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.primary.withOpacity(.15),
                            child: Icon(Icons.apartment, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Basic Details',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Who is this creditor and how can we reach them?",
                        style: TextStyle(
                          color: b == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Form
                      LayoutBuilder(
                        builder: (ctx, c) {
                          final isWide = c.maxWidth > 720;
                          return Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            children: [
                              _field(
                                c: c,
                                isWide: isWide,
                                controller: _name,
                                label: 'Business Name *',
                                icon: Icons.apartment,
                                keyboard: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),
                              _field(
                                c: c,
                                isWide: isWide,
                                controller: _phone,
                                label: 'Phone Number',
                                icon: Icons.phone,
                                keyboard: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                              _field(
                                c: c,
                                isWide: isWide,
                                controller: _email,
                                label: 'Email Address',
                                icon: Icons.mail,
                                keyboard: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              _field(
                                c: c,
                                isWide: isWide,
                                controller: _person,
                                label: 'Contact Person',
                                icon: Icons.person,
                                keyboard: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(
                                width: c.maxWidth,
                                child: TextField(
                                  controller: _address,
                                  maxLines: 2,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'Business Address',
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Footer actions
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel (Esc)'),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 160,
                            child: FilledButton(
                              onPressed: _save,
                              child: const Text('Save  (Ctrl+Enter)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 200,
                            child: GradientButton(
                              onPressed: _saveAndNew,
                              child: const Text('Save & New  (Ctrl+Shift+Enter)'),
                            ),
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
    );
  }

  Widget _field({
    required BoxConstraints c,
    required bool isWide,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboard,
    TextInputAction? textInputAction,
  }) {
    return SizedBox(
      width: isWide ? (c.maxWidth - 24) / 2 : c.maxWidth,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
    }

  void _save() {
    // TODO: connect to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
  }

  void _saveAndNew() {
    _save();
    _name.clear();
    _phone.clear();
    _email.clear();
    _person.clear();
    _address.clear();
  }
}
