import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class EmergencySupportSheet extends StatelessWidget {
  const EmergencySupportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.emergency,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _EmergencyButton(label: s.callTripleZero, tel: '000'),
            _EmergencyButton(label: s.callLifeline, tel: '13 11 14'),
            _EmergencyButton(label: s.callNDIS, tel: '1800800110'),
            const SizedBox(height: 8),
            Text(
              'If in immediate danger, call 000.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String label;
  final String tel;
  const _EmergencyButton({required this.label, required this.tel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.call),
        onPressed: () async {
          final uri = Uri.parse('tel:$tel');
          await launchUrl(uri);
        },
        label: Text(label),
      ),
    );
  }
}

