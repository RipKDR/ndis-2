import 'package:flutter/material.dart';
import '../widgets/emergency_support_sheet.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.health_and_safety),
        label: const Text('Emergency Support'),
        onPressed: () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          builder: (_) => const EmergencySupportSheet(),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _FeatureCard(title: 'Rostering', icon: Icons.calendar_month),
            _FeatureCard(title: 'Clients', icon: Icons.group),
            _FeatureCard(title: 'NDIA Submissions', icon: Icons.outgoing_mail),
            _FeatureCard(title: 'Messages', icon: Icons.chat),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const _FeatureCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

