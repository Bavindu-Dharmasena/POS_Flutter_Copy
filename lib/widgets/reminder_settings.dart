// lib/widgets/reminder_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReminderSettings extends StatelessWidget {
  final bool enableReminders;
  final int reminderDays;
  final ValueChanged<bool> onReminderToggled;
  final ValueChanged<int> onReminderDaysChanged;

  const ReminderSettings({
    super.key,
    required this.enableReminders,
    required this.reminderDays,
    required this.onReminderToggled,
    required this.onReminderDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReminderToggle(context, colorScheme),
        _buildReminderFrequency(context, colorScheme),
      ],
    );
  }

  Widget _buildReminderToggle(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerLow,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Enable payment reminders',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('We\'ll nudge you to review outstanding amounts'),
        value: enableReminders,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onReminderToggled(value);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildReminderFrequency(BuildContext context, ColorScheme colorScheme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: enableReminders
          ? Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('Remind every'),
                  const SizedBox(width: 12),
                  _buildDaysDropdown(colorScheme),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDaysDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: reminderDays,
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              onReminderDaysChanged(value);
            }
          },
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
          items: const [3, 7, 14, 30]
              .map((days) => DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  ))
              .toList(),
        ),
      ),
    );
  }
}