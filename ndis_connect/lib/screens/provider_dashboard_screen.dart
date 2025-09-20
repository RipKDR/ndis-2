import 'package:flutter/material.dart';

import '../widgets/accessibility_widgets.dart';
import '../widgets/emergency_support_sheet.dart';
import '../widgets/error_boundary.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'ProviderDashboardScreen',
      onRetry: () {
        // Retry loading provider dashboard data
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AccessibleText(
            'Provider Dashboard',
            header: true,
            headerLevel: 1,
          ),
          actions: [
            AccessibleIconButton(
              icon: Icons.settings,
              tooltip: 'Settings',
              semanticLabel: 'Open provider settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        floatingActionButton: AccessibleButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            useSafeArea: true,
            builder: (_) => const EmergencySupportSheet(),
          ),
          tooltip: 'Emergency Support',
          semanticLabel: 'Open emergency support options',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.health_and_safety),
              SizedBox(width: 8),
              Text('Emergency Support'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccessibleText(
                'Welcome back!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const AccessibleText(
                'Manage your clients and services',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 600 ? 3 : 2;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: const [
                        _FeatureCard(
                          title: 'Rostering',
                          icon: Icons.calendar_month,
                          description: 'Manage schedules and appointments',
                        ),
                        _FeatureCard(
                          title: 'Clients',
                          icon: Icons.group,
                          description: 'View and manage client profiles',
                        ),
                        _FeatureCard(
                          title: 'NDIA Submissions',
                          icon: Icons.outgoing_mail,
                          description: 'Submit reports and claims',
                        ),
                        _FeatureCard(
                          title: 'Messages',
                          icon: Icons.chat,
                          description: 'Communicate with clients and staff',
                        ),
                        _FeatureCard(
                          title: 'Reports',
                          icon: Icons.analytics,
                          description: 'View performance and analytics',
                        ),
                        _FeatureCard(
                          title: 'Support',
                          icon: Icons.help,
                          description: 'Get help and documentation',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: () => _handleCardTap(context),
      semanticLabel: '$title: $description',
      tooltip: 'Tap to open $title',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
              semanticLabel: null, // Let the card handle semantics
            ),
            const SizedBox(height: 12),
            AccessibleText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            AccessibleText(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardTap(BuildContext context) {
    // Navigate based on feature
    switch (title) {
      case 'Rostering':
        Navigator.pushNamed(context, '/calendar');
        break;
      case 'Clients':
        // Navigate to clients screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client management coming soon')),
        );
        break;
      case 'NDIA Submissions':
        // Navigate to submissions screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NDIA submissions coming soon')),
        );
        break;
      case 'Messages':
        Navigator.pushNamed(context, '/chatbot');
        break;
      case 'Reports':
        // Navigate to reports screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports coming soon')),
        );
        break;
      case 'Support':
        Navigator.pushNamed(context, '/feedback');
        break;
    }
  }
}
