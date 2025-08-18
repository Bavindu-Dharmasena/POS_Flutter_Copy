import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "settings_provider.dart";

class StockKeeperSetting extends StatelessWidget {
  const StockKeeperSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<SettingsController, bool>(
      (c) => c.isDarkMode,
    );
    final fontSize = context.select<SettingsController, double>(
      (c) => c.fontSize,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("System Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance / Dark Mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDarkMode ? 'Dark mode' : 'Light mode',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const Key('darkModeSwitch'),
                    value: isDarkMode,
                    onChanged: (v) =>
                        context.read<SettingsController>().setDark(v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Font Size
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.text_fields, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Small'),
                      Expanded(
                        child: Slider(
                          key: const Key('fontSizeSlider'),
                          value: fontSize,
                          min: 10,
                          max: 30,
                          divisions: 20,
                          label: '${fontSize.toStringAsFixed(0)} pt',
                          onChanged: (v) =>
                              context.read<SettingsController>().setFontSize(v),
                        ),
                      ),
                      const Text('Large'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PreviewBlock(fontSize: fontSize),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('resetButton'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Defaults'),
                  onPressed: () => context.read<SettingsController>().reset(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('applyCloseButton'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Apply & Close'),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.fontSize});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Heading',
            style: TextStyle(
              fontSize: fontSize + 6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is how your text will look across the app. '
            'Adjust the slider above to find a comfortable reading size.',
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(height: 6),
          Text(
            'Secondary text looks like this.',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: scheme.onSurface.withOpacity(.7),
            ),
          ),
        ],
      ),
    );
  }
}
