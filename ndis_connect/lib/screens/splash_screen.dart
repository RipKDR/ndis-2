import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/error_boundary.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'onboarding_role_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with ErrorHandlingMixin {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await executeWithErrorHandling<void>(
      _setupAuthListener(),
      operationName: 'splash_screen_initialization',
      showSnackBarOnError: false, // Don't show snackbar on splash
    );
  }

  Future<void> _setupAuthListener() async {
    try {
      final auth = context.read<AuthService>();
      _sub = auth.authStateChanges.listen((user) async {
        if (!mounted) return;

        await executeWithErrorHandling<void>(
          _handleAuthStateChange(user),
          operationName: 'auth_state_change',
          showSnackBarOnError: false,
        );
      });
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'setup_auth_listener'},
        showSnackBar: false,
      );

      // Fallback: navigate to login after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      }
    }
  }

  Future<void> _handleAuthStateChange(User? user) async {
    try {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      } else {
        // Wait a moment for UserViewModel to load profile
        await Future.delayed(const Duration(milliseconds: 100));

        final userViewModel = context.read<UserViewModel>();
        final role = userViewModel.role;

        if (role.isEmpty) {
          Navigator.of(context).pushReplacementNamed(OnboardingRoleScreen.route);
        } else {
          Navigator.of(context).pushReplacementNamed(DashboardScreen.route);
        }
      }
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'handle_auth_state_change', 'user_uid': user?.uid},
        showSnackBar: false,
      );

      // Fallback: navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'SplashScreen',
      onRetry: () {
        // Retry initialization
        _initializeApp();
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading NDIS Connect...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
