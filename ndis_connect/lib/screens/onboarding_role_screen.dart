import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';
import 'dashboard_screen.dart';

class OnboardingRoleScreen extends StatefulWidget {
  static const route = '/onboarding-role';
  const OnboardingRoleScreen({super.key});

  @override
  State<OnboardingRoleScreen> createState() => _OnboardingRoleScreenState();
}

class _OnboardingRoleScreenState extends State<OnboardingRoleScreen> with ErrorHandlingMixin {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceWelcome();
    });
  }

  Future<void> _announceWelcome() async {
    await executeWithErrorHandling<void>(
      _performTtsAnnouncement(),
      operationName: 'welcome_announcement',
      showSnackBarOnError: false,
    );
  }

  Future<void> _performTtsAnnouncement() async {
    try {
      final ttsService = context.read<TtsService>();
      await ttsService.speak('Welcome to NDIS Connect. Choose your role: Participant or Provider');
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'tts_announcement'},
        showSnackBar: false,
      );
    }
  }

  Future<void> _choose(String role) async {
    if (_loading) return;

    setState(() => _loading = true);

    await executeWithErrorHandling<void>(
      _performRoleSelection(role),
      operationName: 'role_selection',
      showSnackBarOnError: true,
    );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _performRoleSelection(String role) async {
    try {
      final userViewModel = context.read<UserViewModel>();
      await userViewModel.setRole(role);

      if (mounted) {
        Navigator.pushReplacementNamed(context, DashboardScreen.route);
      }
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'role_selection', 'role': role},
        showSnackBar: true,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'OnboardingRoleScreen',
      onRetry: () {
        setState(() => _loading = false);
        _announceWelcome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AccessibleText(
            'Welcome',
            header: true,
            headerLevel: 1,
          ),
        ),
        body: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Setting up your account...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AccessibleText(
                      'Who are you?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      header: true,
                      headerLevel: 2,
                    ),
                    const SizedBox(height: 8),
                    const AccessibleText(
                      'Select your role to customize your experience.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _RoleCard(
                            icon: Icons.accessibility_new,
                            title: 'Participant',
                            description:
                                'I am an NDIS participant looking to manage my plan, track my budget, and organize tasks and appointments.',
                            onTap: () => _choose('participant'),
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            icon: Icons.handshake,
                            title: 'Provider',
                            description:
                                'I am a service provider managing clients, scheduling services, and handling NDIA submissions.',
                            onTap: () => _choose('provider'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      semanticLabel: '$title role: $description',
      tooltip: 'Tap to select $title role',
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
                semanticLabel: null, // Let card handle semantics
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AccessibleText(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              semanticLabel: null, // Let card handle semantics
            ),
          ],
        ),
      ),
    );
  }
}
