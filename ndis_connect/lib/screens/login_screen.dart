import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _signIn(BuildContext context) async {
    final s = AppLocalizations.of(context)!;
    try {
      // Optional biometric gate before auth
      final canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        await auth.authenticate(
          localizedReason: 'Unlock NDIS Connect',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      }
      await context.read<AuthService>().signInAnonymously();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.error}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.login)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signIn(context),
          child: Text(s.login),
        ),
      ),
    );
  }
}
