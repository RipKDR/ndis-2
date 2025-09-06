import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../viewmodels/user_viewmodel.dart';
import 'dashboard_screen.dart';

class OnboardingRoleScreen extends StatefulWidget {
  static const route = '/onboarding-role';
  const OnboardingRoleScreen({super.key});

  @override
  State<OnboardingRoleScreen> createState() => _OnboardingRoleScreenState();
}

class _OnboardingRoleScreenState extends State<OnboardingRoleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TtsService>().speak('Choose your role: Participant or Provider');
    });
  }

  Future<void> _choose(String role) async {
    await context.read<UserViewModel>().setRole(role);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, DashboardScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who are you?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.accessibility_new,
              title: 'Participant',
              description: 'View plan, track budget, tasks and appointments.',
              onTap: () => _choose('participant'),
            ),
            _RoleCard(
              icon: Icons.handshake,
              title: 'Provider',
              description: 'Manage clients, rostering, and submissions.',
              onTap: () => _choose('provider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

