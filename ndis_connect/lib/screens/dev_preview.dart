import 'package:flutter/material.dart';

import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';
import '../widgets/feature_card.dart';

class DevPreviewScreen extends StatelessWidget {
  static const route = '/dev-preview';
  const DevPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'DevPreview',
      onRetry: () {
        // Retry functionality
      },
      child: Scaffold(
        appBar: AppBar(title: const AccessibleText('Dev Preview')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              FeatureCard.large(title: 'Large card', icon: Icons.pie_chart, onTap: () {}),
              FeatureCard.medium(title: 'Medium card', icon: Icons.calendar_today, onTap: () {}),
              FeatureCard.small(title: 'Small card', icon: Icons.check_circle, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
