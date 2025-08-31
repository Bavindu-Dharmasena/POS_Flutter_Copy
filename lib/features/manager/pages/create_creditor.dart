import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateCreditorPage extends StatefulWidget {
  const CreateCreditorPage({super.key});

  @override
  State<CreateCreditorPage> createState() => _CreateCreditorPageState();
}

class _CreateCreditorPageState extends State<CreateCreditorPage>
    with TickerProviderStateMixin {
  // ----------------------------- Form & Controllers -----------------------------
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _contactPerson = TextEditingController();
  final _limit = TextEditingController(text: '0');
  final _notes = TextEditingController();

  // tags UI
  final _tagCtrl = TextEditingController();
  final Set<String> _tags = {};

  // state
  bool _reminders = false;
  int _reminderDays = 7;
  bool _isActive = true;
  bool _expandedMore = false;
  bool _dirty = false;

  late final AnimationController _expandAC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  
  late final AnimationController _fadeAC = 
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  
  late final AnimationController _slideAC = 
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  // ----------------------------- Lifecycle -----------------------------
  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _email, _address, _contactPerson, _limit, _notes, _tagCtrl]) {
      c.addListener(() => _markDirty());
    }
    
    // Start entrance animations
    _fadeAC.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideAC.forward();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _contactPerson.dispose();
    _limit.dispose();
    _notes.dispose();
    _tagCtrl.dispose();
    _expandAC.dispose();
    _fadeAC.dispose();
    _slideAC.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // ----------------------------- Navigation guard -----------------------------
  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Discard changes?'),
          ],
        ),
        content: const Text('You have unsaved changes. Do you really want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel')
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  // ----------------------------- Validators -----------------------------
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _phoneVal(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 12) return 'Enter a valid phone number';
    return null;
  }

  String? _emailVal(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final ok = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$").hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _limitVal(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = _parseCurrencyToInt(v);
    if (n < 0) return 'Credit limit cannot be negative';
    if (n > 1e12.toInt()) return 'Credit limit is too large';
    return null;
  }

  // ----------------------------- Currency helpers -----------------------------
  final _currencyFormatter = _CurrencyInputFormatter(symbol: 'Rs ');
  int _parseCurrencyToInt(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }

  String _riskLabel(int limit) {
    if (limit >= 1000000) return 'High';
    if (limit >= 250000) return 'Medium';
    if (limit > 0) return 'Low';
    return 'None';
  }

  Color _riskColor(BuildContext context, String risk) {
    switch (risk) {
      case 'High':
        return Colors.red.shade400;
      case 'Medium':
        return Colors.orange.shade400;
      case 'Low':
        return Colors.green.shade400;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  // ----------------------------- Save actions -----------------------------
  void _save({bool andNew = false}) async {
    if (_formKey.currentState!.validate()) {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      final payload = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'contactPerson': _contactPerson.text.trim(),
        'creditLimit': _parseCurrencyToInt(_limit.text),
        'isActive': _isActive,
        'reminders': _reminders,
        'reminderDays': _reminders ? _reminderDays : null,
        'tags': _tags.toList(),
        'notes': _notes.text.trim(),
      };

      debugPrint('Submitting creditor: $payload');

      // Show beautiful success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Success!',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        'Creditor "${_name.text.trim()}" has been created',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() => _dirty = false);

      if (andNew) {
        _formKey.currentState!.reset();
        for (final c in [_name, _phone, _email, _address, _contactPerson, _notes]) {
          c.clear();
        }
        _limit.text = '0';
        _tags.clear();
        _reminders = false;
        _reminderDays = 7;
        _isActive = true;
        setState(() {});
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true);
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // ----------------------------- Shortcuts -----------------------------
  Map<LogicalKeySet, Intent> get _shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const _SubmitIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
      };

  Map<Type, Action<Intent>> get _actions => {
        _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (_) => _save()),
        _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) async {
          final leave = await _confirmLeave();
          if (leave && mounted) Navigator.pop(context);
          return null;
        }),
      };

  // ----------------------------- Build -----------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final limitInt = _parseCurrencyToInt(_limit.text);
    final risk = _riskLabel(limitInt);

    return WillPopScope(
      onWillPop: _confirmLeave,
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actions,
          child: Scaffold(
            backgroundColor: cs.surfaceContainerLowest,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: cs.onSurface,
              title: FadeTransition(
                opacity: _fadeAC,
                child: const Text(
                  'Create Creditor',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _slideAC, curve: Curves.easeOutCubic)),
                    child: _RiskChip(label: risk, color: _riskColor(context, risk)),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _slideAC, curve: Curves.easeOutCubic)),
              child: _BottomBar(
                onCancel: () async {
                  final leave = await _confirmLeave();
                  if (leave && mounted) Navigator.pop(context);
                },
                onSave: () => _save(),
                onSaveNew: () => _save(andNew: true),
                enabled: true,
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: FadeTransition(
                    opacity: _fadeAC,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: _slideAC, curve: Curves.easeOutCubic)),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            _SectionCard(
                              title: 'Basic Details',
                              subtitle: 'Who is this creditor and how can we reach them?',
                              icon: Icons.business_rounded,
                              child: LayoutBuilder(
                                builder: (ctx, c) {
                                  final isWide = c.maxWidth > 720;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      _w(isWide, _nameField()),
                                      _w(isWide, _phoneField()),
                                      _w(isWide, _emailField()),
                                      _w(isWide, _contactPersonField()),
                                      _w(isWide, _addressField(), span2: true),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Credit & Status',
                              subtitle: 'Set limits and manage active status',
                              icon: Icons.account_balance_wallet_rounded,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _limitField()),
                                      const SizedBox(width: 16),
                                      _activeSwitch(cs),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cs.primaryContainer),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline_rounded, 
                                             color: cs.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Set a realistic limit based on purchase history. Risk adjusts automatically.',
                                            style: TextStyle(
                                              color: cs.onPrimaryContainer,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Tags & Notes',
                              subtitle: 'Categorize and add helpful context',
                              icon: Icons.label_outline_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _tagEditor(),
                                  const SizedBox(height: 16),
                                  _notesField(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Reminders',
                              subtitle: 'Stay on top of payments',
                              icon: Icons.notifications_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: cs.surfaceContainerLow,
                                    ),
                                    child: SwitchListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      title: const Text('Enable payment reminders',
                                                      style: TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: const Text('We\'ll nudge you to review outstanding amounts'),
                                      value: _reminders,
                                      onChanged: (v) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _reminders = v);
                                      },
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    child: _reminders
                                        ? Container(
                                            margin: const EdgeInsets.only(top: 12),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: cs.surfaceContainerLow,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.schedule_rounded, color: cs.primary),
                                                const SizedBox(width: 12),
                                                const Text('Remind every'),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: cs.primaryContainer,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<int>(
                                                      value: _reminderDays,
                                                      onChanged: (v) {
                                                        HapticFeedback.selectionClick();
                                                        setState(() => _reminderDays = v ?? 7);
                                                      },
                                                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w500),
                                                      items: const [3, 7, 14, 30]
                                                          .map((d) => DropdownMenuItem(
                                                                value: d,
                                                                child: Text('$d days'),
                                                              ))
                                                          .toList(),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _moreOptions(cs),
                            const SizedBox(height: 100), // Extra space for bottom bar
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
      ),
    );
  }

  // ----------------------------- Widgets -----------------------------
  Widget _w(bool isWide, Widget child, {bool span2 = false}) {
    final w = isWide
        ? SizedBox(width: span2 ? (1000 - 16) / 1 : (1000 - 16) / 2, child: child)
        : child;
    return w;
  }

  Widget _nameField() => _BeautifulTextField(
        controller: _name,
        autofillHints: const [AutofillHints.name],
        label: 'Business Name',
        hint: 'e.g., ABC Suppliers (Pvt) Ltd',
        icon: Icons.business_rounded,
        required: true,
        validator: _req,
      );

  Widget _phoneField() => _BeautifulTextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
        label: 'Phone Number',
        hint: '+94 71 234 5678',
        icon: Icons.phone_rounded,
        validator: _phoneVal,
      );

  Widget _emailField() => _BeautifulTextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        label: 'Email Address',
        hint: 'contact@company.com',
        icon: Icons.alternate_email_rounded,
        validator: _emailVal,
      );

  Widget _contactPersonField() => _BeautifulTextField(
        controller: _contactPerson,
        label: 'Contact Person',
        hint: 'e.g., Mrs. Perera',
        icon: Icons.person_outline_rounded,
      );

  Widget _addressField() => _BeautifulTextField(
        controller: _address,
        label: 'Business Address',
        hint: 'Street, City, Province',
        icon: Icons.location_on_outlined,
        minLines: 1,
        maxLines: 3,
      );

  Widget _limitField() => _BeautifulTextField(
        controller: _limit,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
          _currencyFormatter,
        ],
        label: 'Credit Limit',
        hint: 'Rs 0',
        icon: Icons.payments_outlined,
        validator: _limitVal,
      );

  Widget _activeSwitch(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Status', style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            )),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isActive ? Icons.verified_user_rounded : Icons.pause_circle_outline_rounded,
                key: ValueKey(_isActive),
                color: _isActive ? Colors.green.shade400 : cs.outline,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Switch(
              value: _isActive,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _isActive = v);
              },
            ),
          ],
        ),
      );

  Widget _tagEditor() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t, style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            )),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _tags.remove(t));
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          _BeautifulTextField(
            controller: _tagCtrl,
            label: 'Add Tags',
            hint: 'e.g., wholesale, priority, local',
            icon: Icons.sell_outlined,
            onSubmitted: (v) {
              if (v.trim().isEmpty) return;
              HapticFeedback.lightImpact();
              setState(() {
                _tags.add(v.trim());
                _tagCtrl.clear();
              });
            },
            suffixIcon: IconButton(
              onPressed: () {
                if (_tagCtrl.text.trim().isEmpty) return;
                HapticFeedback.lightImpact();
                setState(() {
                  _tags.add(_tagCtrl.text.trim());
                  _tagCtrl.clear();
                });
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add tag',
            ),
          ),
        ],
      );

  Widget _notesField() => _BeautifulTextField(
        controller: _notes,
        label: 'Additional Notes',
        hint: 'Special terms, payment methods, contact preferences...',
        icon: Icons.notes_outlined,
        minLines: 3,
        maxLines: 6,
        alignLabelWithHint: true,
      );

  Widget _moreOptions(ColorScheme cs) => Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expandedMore = !_expandedMore;
                    if (_expandedMore) {
                      _expandAC.forward();
                    } else {
                      _expandAC.reverse();
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: _expandedMore ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _expandedMore ? 'Hide advanced options' : 'Show advanced options',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAC.drive(CurveTween(curve: Curves.easeInOutCubic)),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _expandedMore ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: _SectionCard(
                  title: 'Advanced Options',
                  subtitle: 'Additional integrations and settings',
                  icon: Icons.settings_outlined,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.link_rounded, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ERP Integration',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Connect to existing accounting systems',
                                    style: TextStyle(color: cs.outline, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
        ],
      );
}

// ----------------------------- Beautiful Text Field -----------------------------
class _BeautifulTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool required;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;
  final int? minLines;
  final int? maxLines;
  final bool alignLabelWithHint;
  final Function(String)? onSubmitted;

  const _BeautifulTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.minLines,
    this.maxLines,
    this.alignLabelWithHint = false,
    this.onSubmitted,
  });

  @override
  State<_BeautifulTextField> createState() => _BeautifulTextFieldState();
}

class _BeautifulTextFieldState extends State<_BeautifulTextField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? cs.primary 
              : cs.outline.withOpacity(0.3),
          width: _isFocused ? 2 : 1,
        ),
        color: cs.surfaceContainerLow,
        boxShadow: _isFocused ? [
          BoxShadow(
            color: cs.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.required ? '${widget.label} *' : widget.label,
          hintText: widget.hint,
          alignLabelWithHint: widget.alignLabelWithHint,
          prefixIcon: widget.icon != null 
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    widget.icon,
                    color: _isFocused ? cs.primary : cs.outline,
                    size: 22,
                  ),
                )
              : null,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.icon != null ? 60 : 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: _isFocused ? cs.primary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          errorStyle: TextStyle(
            color: cs.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ----------------------------- Reusable UI -----------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: cs.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final Color color;
  
  const _RiskChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insights_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Risk: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onSaveNew;
  final VoidCallback onCancel;
  final bool enabled;
  
  const _BottomBar({
    required this.onSave,
    required this.onSaveNew,
    required this.onCancel,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withOpacity(0.3)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: enabled ? onCancel : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Esc',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [cs.secondaryContainer, cs.secondaryContainer.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: enabled ? onSaveNew : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: cs.onSecondaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'Save & New',
                            style: TextStyle(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: enabled ? onSave : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: cs.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Save',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ctrl+Enter',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
}

// ----------------------------- Keyboard intents -----------------------------
class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

// ----------------------------- Currency InputFormatter -----------------------------
class _CurrencyInputFormatter extends TextInputFormatter {
  final String symbol;
  _CurrencyInputFormatter({required this.symbol});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return TextEditingValue(
        text: '0',
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';

    final withCommas = _addCommas(digits);
    final formatted = 'Rs $withCommas';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addCommas(String s) {
    final rev = s.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < rev.length; i += 3) {
      chunks.add(rev.sublist(i, (i + 3) > rev.length ? rev.length : (i + 3)).join());
    }
    return chunks.map((c) => c.split('').reversed.join()).toList().reversed.join(',');
  }
}