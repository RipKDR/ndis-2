import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/app_settings_viewmodel.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final vm = context.watch<AppSettingsViewModel>();
    return ErrorBoundary(
      context: 'SettingsScreen',
      onRetry: () {
        // Retry functionality
      },
      child: Scaffold(
        appBar: AppBar(title: AccessibleText(s.settings)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              value: vm.highContrast,
              onChanged: vm.toggleHighContrast,
              title: AccessibleText(s.highContrast),
            ),
            ListTile(
              title: AccessibleText(s.language),
              subtitle: AccessibleText(vm.locale?.toLanguageTag() ?? 'system'),
              onTap: () async {
                final locale = await showDialog<Locale?>(
                  context: context,
                  builder: (_) => const _LanguageDialog(),
                );
                if (locale != null) vm.setLocale(locale);
              },
            ),
            ListTile(
              title: const AccessibleText('Text size'),
              subtitle: Slider(
                value: vm.textScale,
                onChanged: vm.setTextScale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: '${(vm.textScale * 100).toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AccessibleText('Choose language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const AccessibleText('English (AU)'),
            onTap: () => Navigator.pop(context, const Locale('en', 'AU')),
          ),
          ListTile(
            title: const AccessibleText('Yolngu (demo)'),
            onTap: () => Navigator.pop(context, const Locale.fromSubtags(languageCode: 'yol')),
          ),
          ListTile(
            title: const AccessibleText('System default'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      ),
    );
  }
}
