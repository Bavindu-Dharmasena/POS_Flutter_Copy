// lib/widgets/status_switch.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const StatusSwitch({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Status',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? Icons.verified_user_rounded : Icons.pause_circle_outline_rounded,
              key: ValueKey(isActive),
              color: isActive ? Colors.green.shade400 : colorScheme.outline,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Switch(
            value: isActive,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}