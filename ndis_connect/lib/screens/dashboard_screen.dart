import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/emergency_support_sheet.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _FeatureCard(title: s.budget, icon: Icons.pie_chart, onTap: () => Navigator.pushNamed(context, '/budget')),
              _FeatureCard(title: s.calendar, icon: Icons.calendar_today, onTap: () => Navigator.pushNamed(context, '/calendar')),
              _FeatureCard(title: s.tasks, icon: Icons.check_circle, onTap: () {}),
              _FeatureCard(title: s.serviceMap, icon: Icons.map, onTap: () => Navigator.pushNamed(context, '/map')),
              if (pointsEnabled)
                _FeatureCard(
                  title: s.points,
                  icon: badgeVariant == 'B' ? Icons.military_tech : Icons.emoji_events,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.offlineMode, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _FeatureCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
