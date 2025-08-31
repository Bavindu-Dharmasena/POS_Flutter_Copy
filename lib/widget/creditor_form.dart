// lib/widgets/creditor_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/creditor_model.dart';
import 'section_card.dart';
import 'beautiful_text_field.dart';
import 'tag_editor.dart';
import 'status_switch.dart';
import 'reminder_settings.dart';
import 'advanced_options.dart';
import '../utils/currency_formatter.dart'; // Ensure this import exists
import '../utils/form_validators.dart';

class CreditorForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ValueNotifier<CreditorModel> creditorNotifier;

  const CreditorForm({
    super.key,
    required this.formKey,
    required this.creditorNotifier,
  });

  @override
  State<CreditorForm> createState() => _CreditorFormState();
}

class _CreditorFormState extends State<CreditorForm>
    with TickerProviderStateMixin {
  
  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _notesController;

  // Advanced options animation
  late final AnimationController _expandController;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeControllers() {
    final creditor = widget.creditorNotifier.value;
    
    _nameController = TextEditingController(text: creditor.name);
    _phoneController = TextEditingController(text: creditor.phone);
    _emailController = TextEditingController(text: creditor.email);
    _addressController = TextEditingController(text: creditor.address);
    _contactPersonController = TextEditingController(text: creditor.contactPerson);
    _creditLimitController = TextEditingController(
      text: creditor.creditLimit == 0 ? '0' : 'Rs ${CurrencyFormatter.formatAmount(creditor.creditLimit)}'
    );
    _notesController = TextEditingController(text: creditor.notes);
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _setupListeners() {
    _nameController.addListener(_updateCreditor);
    _phoneController.addListener(_updateCreditor);
    _emailController.addListener(_updateCreditor);
    _addressController.addListener(_updateCreditor);
    _contactPersonController.addListener(_updateCreditor);
    _creditLimitController.addListener(_updateCreditor);
    _notesController.addListener(_updateCreditor);
  }

  void _updateCreditor() {
    final current = widget.creditorNotifier.value;
    widget.creditorNotifier.value = current.copyWith(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      contactPerson: _contactPersonController.text,
      creditLimit: CurrencyFormatter.parseCurrencyToInt(_creditLimitController.text),
      notes: _notesController.text,
    );
  }

  void _updateCreditorField<T>(T value, CreditorModel Function(CreditorModel, T) updater) {
    widget.creditorNotifier.value = updater(widget.creditorNotifier.value, value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildBasicDetailsSection(),
          const SizedBox(height: 16),
          _buildCreditStatusSection(),
          const SizedBox(height: 16),
          _buildTagsNotesSection(),
          const SizedBox(height: 16),
          _buildRemindersSection(),
          const SizedBox(height: 12),
          _buildAdvancedOptionsToggle(),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBasicDetailsSection() {
    return SectionCard(
      title: 'Basic Details',
      subtitle: 'Who is this creditor and how can we reach them?',
      icon: Icons.business_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildResponsiveField(isWide, _buildNameField()),
              _buildResponsiveField(isWide, _buildPhoneField()),
              _buildResponsiveField(isWide, _buildEmailField()),
              _buildResponsiveField(isWide, _buildContactPersonField()),
              _buildResponsiveField(isWide, _buildAddressField(), fullWidth: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreditStatusSection() {
    return ValueListenableBuilder<CreditorModel>(
      valueListenable: widget.creditorNotifier,
      builder: (context, creditor, _) {
        return SectionCard(
          title: 'Credit & Status',
          subtitle: 'Set limits and manage active status',
          icon: Icons.account_balance_wallet_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCreditLimitField()),
                  const SizedBox(width: 16),
                  StatusSwitch(
                    isActive: creditor.isActive,
                    onChanged: (value) => _updateCreditorField(
                      value,
                      (creditor, isActive) => creditor.copyWith(isActive: isActive),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRiskInfoCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagsNotesSection() {
    return ValueListenableBuilder<CreditorModel>(
      valueListenable: widget.creditorNotifier,
      builder: (context, creditor, _) {
        return SectionCard(
          title: 'Tags & Notes',
          subtitle: 'Categorize and add helpful context',
          icon: Icons.label_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TagEditor(
                tags: creditor.tags,
                onTagsChanged: (tags) => _updateCreditorField(
                  tags,
                  (creditor, tags) => creditor.copyWith(tags: tags),
                ),
              ),
              const SizedBox(height: 16),
              _buildNotesField(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersSection() {
    return ValueListenableBuilder<CreditorModel>(
      valueListenable: widget.creditorNotifier,
      builder: (context, creditor, _) {
        return SectionCard(
          title: 'Reminders',
          subtitle: 'Stay on top of payments',
          icon: Icons.notifications_outlined,
          child: ReminderSettings(
            enableReminders: creditor.enableReminders,
            reminderDays: creditor.reminderDays,
            onReminderToggled: (enabled) => _updateCreditorField(
              enabled,
              (creditor, enabled) => creditor.copyWith(enableReminders: enabled),
            ),
            onReminderDaysChanged: (days) => _updateCreditorField(
              days,
              (creditor, days) => creditor.copyWith(reminderDays: days),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedOptionsToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
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
                  _showAdvancedOptions = !_showAdvancedOptions;
                  if (_showAdvancedOptions) {
                    _expandController.forward();
                  } else {
                    _expandController.reverse();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedRotation(
                      turns: _showAdvancedOptions ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showAdvancedOptions ? 'Hide advanced options' : 'Show advanced options',
                      style: TextStyle(
                        color: colorScheme.primary,
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
          sizeFactor: _expandController.drive(CurveTween(curve: Curves.easeInOutCubic)),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showAdvancedOptions ? 1 : 0,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              child: const AdvancedOptions(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveField(bool isWide, Widget child, {bool fullWidth = false}) {
    if (!isWide) return child;
    
    final width = fullWidth ? (1000 - 16) / 1 : (1000 - 16) / 2;
    return SizedBox(width: width, child: child);
  }

  Widget _buildNameField() => BeautifulTextField(
        controller: _nameController,
        autofillHints: const [AutofillHints.name],
        label: 'Business Name',
        hint: 'e.g., ABC Suppliers (Pvt) Ltd',
        icon: Icons.business_rounded,
        required: true,
        validator: FormValidators.required,
      );

  Widget _buildPhoneField() => BeautifulTextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
        label: 'Phone Number',
        hint: '+94 71 234 5678',
        icon: Icons.phone_rounded,
        validator: FormValidators.phone,
      );

  Widget _buildEmailField() => BeautifulTextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        label: 'Email Address',
        hint: 'contact@company.com',
        icon: Icons.alternate_email_rounded,
        validator: FormValidators.email,
      );

  Widget _buildContactPersonField() => BeautifulTextField(
        controller: _contactPersonController,
        label: 'Contact Person',
        hint: 'e.g., Mrs. Perera',
        icon: Icons.person_outline_rounded,
      );

  Widget _buildAddressField() => BeautifulTextField(
        controller: _addressController,
        label: 'Business Address',
        hint: 'Street, City, Province',
        icon: Icons.location_on_outlined,
        minLines: 1,
        maxLines: 3,
      );

  Widget _buildCreditLimitField() => BeautifulTextField(
        controller: _creditLimitController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
          CurrencyInputFormatter(symbol: 'Rs '),
        ],
        label: 'Credit Limit',
        hint: 'Rs 0',
        icon: Icons.payments_outlined,
        validator: FormValidators.creditLimit,
      );

  Widget _buildNotesField() => BeautifulTextField(
        controller: _notesController,
        label: 'Additional Notes',
        hint: 'Special terms, payment methods, contact preferences...',
        icon: Icons.notes_outlined,
        minLines: 3,
        maxLines: 6,
        alignLabelWithHint: true,
      );

  Widget _buildRiskInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set a realistic limit based on purchase history. Risk adjusts automatically.',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}