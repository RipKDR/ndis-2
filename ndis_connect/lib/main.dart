import 'dart:async';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' as fnd show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/environment.dart';
import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/error_handling_service.dart';
import 'services/notifications_service.dart';
import 'services/remote_config_service.dart';
import 'services/storage_encryption_service.dart';
import 'services/tts_service.dart';
import 'services/user_service.dart';
import 'viewmodels/app_settings_viewmodel.dart';
import 'viewmodels/connectivity_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Create/Load local encryption key for Hive
  const secureStorage = FlutterSecureStorage();
  final encryptionKey = await secureStorage.read(key: 'hive_key');
  if (encryptionKey == null) {
    final key = enc.Key.fromSecureRandom(32);
    await secureStorage.write(key: 'hive_key', value: key.base64);
  }

  // Initialize Firebase safely. If it fails, continue with no-op fallbacks.
  var firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAvailable = true;

    // Register background handler only on mobile platforms
    if (!kIsWeb &&
        (fnd.defaultTargetPlatform == fnd.TargetPlatform.android ||
            fnd.defaultTargetPlatform == fnd.TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    // Only enable crashlytics in production/staging
    if (AppConfig.enableCrashlytics) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

    // Remote Config defaults and activation
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(<String, dynamic>{
      'points_enabled': true,
      'ai_assist_level': 'basic',
      'ab_badge_variant': 'A',
    });
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // If Firebase fails to initialize (missing config/keys/etc.), continue.
    // Services that depend on Firebase must handle the absence gracefully.
    // Log the error locally; avoid crashing the app at startup.
    // ignore: avoid_print
    print('Firebase initialize failed, continuing without Firebase: $e');
    firebaseAvailable = false;
  }

  final authService = AuthService();
  final analyticsService = AnalyticsService();
  final rcService = RemoteConfigService(firebaseAvailable ? FirebaseRemoteConfig.instance : null);
  final storageEncryptionService = StorageEncryptionService();
  final ttsService = TtsService();
  final userService = UserService();
  final notificationsService = NotificationsService();
  final errorHandlingService = ErrorHandlingService();

  // Initialize services. Only initialize Firebase-dependent services when Firebase is available.
  if (firebaseAvailable) {
    await notificationsService.initialize();
  } else {
    // NotificationsService will remain in a safe, uninitialized state and expose no-op methods.
  }
  errorHandlingService.initialize();

  runZonedGuarded(() {
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ConnectivityViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel(userService, FirebaseAuth.instance)),
        Provider.value(value: authService),
        Provider.value(value: analyticsService),
        Provider.value(value: rcService),
        Provider.value(value: storageEncryptionService),
        Provider.value(value: ttsService),
        Provider.value(value: notificationsService),
        Provider.value(value: errorHandlingService),
      ],
      child: const NdisApp(),
    ));
  }, (error, stack) {
    // If Crashlytics is available use it, otherwise log the error.
    if (AppConfig.enableCrashlytics) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return;
      } catch (_) {
        // fall through to local logging
      }
    }
    // ignore: avoid_print
    print('Unhandled error: $error');
  });
}

// Must be a top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
