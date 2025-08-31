// lib/utils/keyboard_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _getShortcuts(),
      child: Actions(
        actions: _getActions(),
        child: child,
      ),
    );
  }

  Map<LogicalKeySet, Intent> _getShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): 
          const _SubmitIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): 
          const _CancelIntent(),
    };
  }

  Map<Type, Action<Intent>> _getActions() {
    return {
      _SubmitIntent: CallbackAction<_SubmitIntent>(
        onInvoke: (_) => onSave(),
      ),
      _CancelIntent: CallbackAction<_CancelIntent>(
        onInvoke: (_) {
          onCancel();
          return null;
        },
      ),
    };
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}