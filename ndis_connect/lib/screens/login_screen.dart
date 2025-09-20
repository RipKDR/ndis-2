import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../ui/components.dart';
import '../widgets/error_boundary.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ErrorHandlingMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _loading = false;
  bool _obscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn(BuildContext context) async {
    // Validate input
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      handleError(
        'Email and password are required',
        context: {'operation': 'sign_in_validation'},
        showSnackBar: true,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      handleError(
        'Please enter a valid email address',
        context: {'operation': 'sign_in_validation', 'email': email},
        showSnackBar: true,
      );
      return;
    }

    setState(() => _loading = true);

    await executeWithErrorHandling<void>(
      _performSignIn(),
      operationName: 'user_sign_in',
      showSnackBarOnError: true,
    );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _performSignIn() async {
    // Optional biometric gate before auth
    await _performBiometricCheck();

    // Perform sign in
    final authService = context.read<AuthService>();
    await authService.signInWithEmailAndPassword(
        _emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Signed in successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _performBiometricCheck() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        final availableBiometrics = await auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          await auth.authenticate(
            localizedReason: 'Unlock NDIS Connect',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      // Biometric failure shouldn't block login, just log it
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'biometric_check'},
        showSnackBar: false, // Don't show error for optional biometric
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.login)),
      body: ErrorBoundary(
        context: 'LoginScreen',
        onRetry: () {
          setState(() {
            _loading = false;
            _emailController.clear();
            _passwordController.clear();
          });
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(s.welcome,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Access your NDIS Connect account',
                      style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  CardContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InputField(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 12),
                        InputField(
                          label: 'Password',
                          controller: _passwordController,
                          hint: null,
                          obscure: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _signIn(context),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AccessibleIconButton(
                            icon: _obscure ? Icons.visibility : Icons.visibility_off,
                            semanticLabel: _obscure ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child:
                              TextButton(onPressed: () {}, child: const Text('Forgot password?')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                      onPressed: _loading ? () {} : () => _signIn(context),
                      child: Text(_loading ? s.loading : s.login)),
                  const SizedBox(height: 12),
                  GhostButton(
                      onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                      child: const Text('Create account')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
