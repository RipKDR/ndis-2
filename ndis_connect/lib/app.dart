import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/budget_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dev_preview.dart';
import 'screens/feedback_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_role_screen.dart';
import 'screens/service_map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_screen.dart';
import 'screens/tutorial_screen.dart';
import 'ui/design_tokens.dart';
import 'viewmodels/app_settings_viewmodel.dart';
import 'viewmodels/connectivity_viewmodel.dart';

class NdisApp extends StatefulWidget {
  const NdisApp({super.key});

  @override
  State<NdisApp> createState() => _NdisAppState();
}

class _NdisAppState extends State<NdisApp> {
  late final FirebaseAnalytics _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = FirebaseAnalytics.instance;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsViewModel>();
    final highContrast = settings.highContrast;
    final textScale = settings.textScale;
    // Decide dark mode based on platform brightness for now (could be user-controlled)
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final dark = platformBrightness == Brightness.dark;

    final baseTheme = DesignTokens.themeData(highContrast: highContrast, dark: dark).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        title: 'NDIS Connect',
        locale: settings.locale,
        theme: baseTheme,
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: _analytics),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('en', 'AU'),
          Locale.fromSubtags(languageCode: 'yol'),
        ],
        builder: (context, child) {
          // Wrap pages with a simple offline banner if needed
          return ChangeNotifierProvider(
            create: (_) => ConnectivityViewModel(),
            child: Builder(builder: (context) {
              final offline = context.watch<ConnectivityViewModel>().offline;
              return Stack(
                children: [
                  if (child != null) child,
                  if (offline)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.amber[800],
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: const SafeArea(
                          top: false,
                          child: Text(
                            'Offline mode – some data may be stale',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          );
        },
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          DashboardScreen.route: (_) => const DashboardScreen(),
          SettingsScreen.route: (_) => const SettingsScreen(),
          OnboardingRoleScreen.route: (_) => const OnboardingRoleScreen(),
          TutorialScreen.route: (_) => const TutorialScreen(),
          FeedbackScreen.route: (_) => const FeedbackScreen(),
          CalendarScreen.route: (_) => const CalendarScreen(),
          BudgetScreen.route: (_) => const BudgetScreen(),
          TaskScreen.route: (_) => const TaskScreen(),
          ServiceMapScreen.route: (_) => const ServiceMapScreen(),
          ChatbotScreen.route: (_) => const ChatbotScreen(),
          DevPreviewScreen.route: (_) => const DevPreviewScreen(),
        },
        initialRoute: SplashScreen.route,
      ),
    );
  }
}
