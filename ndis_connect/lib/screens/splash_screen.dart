import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../viewmodels/user_viewmodel.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'onboarding_role_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<User?> _sub;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _sub = auth.authStateChanges.listen((user) async {
      if (!mounted) return;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      } else {
        // Wait a moment for UserViewModel to load profile
        await Future.delayed(const Duration(milliseconds: 100));
        final role = context.read<UserViewModel>().role;
        if (role.isEmpty) {
          Navigator.of(context).pushReplacementNamed(OnboardingRoleScreen.route);
        } else {
          Navigator.of(context).pushReplacementNamed(DashboardScreen.route);
        }
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
