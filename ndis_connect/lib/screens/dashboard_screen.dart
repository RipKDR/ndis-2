import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/emergency_support_sheet.dart';
import '../widgets/feature_card.dart';
import 'provider_dashboard_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const route = '/dashboard';
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userVm = context.watch<UserViewModel>();
    if (userVm.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userVm.role == 'provider') {
      return const ProviderDashboardScreen();
    }
    return const ParticipantDashboardScreen();
  }
}

class ParticipantDashboardScreen extends StatelessWidget {
  const ParticipantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final rc = context.read<RemoteConfigService>();
    final pointsEnabled = rc.pointsEnabled;
    final badgeVariant = rc.badgeVariant; // A or B
    return Scaffold(
      appBar: AppBar(
        title: Text(s.participantDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
            tooltip: s.settings,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.health_and_safety),
        label: Text(s.emergency),
        onPressed: () async {
          context.read<AnalyticsService>().logEvent('emergency_opened');
          showModalBottomSheet(
            context: context,
            useSafeArea: true,
            builder: (_) => const EmergencySupportSheet(),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          // Determine number of columns based on width
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1000
              ? 4
              : width >= 700
                  ? 3
                  : width >= 500
                      ? 2
                      : 1;

          final features = <Widget>[
            FeatureCard.large(
              title: s.budget,
              icon: Icons.pie_chart,
              onTap: () => Navigator.pushNamed(context, '/budget'),
            ),
            FeatureCard.large(
              title: s.calendar,
              icon: Icons.calendar_today,
              onTap: () => Navigator.pushNamed(context, '/calendar'),
            ),
            FeatureCard.large(
              title: s.tasks,
              icon: Icons.check_circle,
              onTap: () => Navigator.pushNamed(context, '/tasks'),
            ),
            FeatureCard.large(
              title: s.serviceMap,
              icon: Icons.map,
              onTap: () => Navigator.pushNamed(context, '/map'),
            ),
            FeatureCard.large(
              title: 'AI Assistant',
              icon: Icons.smart_toy,
              onTap: () => Navigator.pushNamed(context, '/chatbot'),
            ),
          ];

          if (pointsEnabled) {
            features.add(FeatureCard.large(
              title: s.points,
              icon: badgeVariant == 'B' ? Icons.military_tech : Icons.emoji_events,
              onTap: () {},
            ));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // Slightly taller cards for easier touch targets on mobile
                    childAspectRatio: width < 600 ? 5 / 4 : 4 / 3,
                  ),
                  itemCount: features.length,
                  itemBuilder: (ctx, idx) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Semantics(
                      container: true,
                      child: features[idx],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(s.offlineMode, style: Theme.of(context).textTheme.labelMedium),
            ],
          );
        }),
      ),
    );
  }
}
