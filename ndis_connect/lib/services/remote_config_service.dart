import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Wrapper for FirebaseRemoteConfig that tolerates a missing remote config
/// instance (when Firebase failed to initialize). In that case the service
/// returns sensible defaults.
class RemoteConfigService {
  final FirebaseRemoteConfig? _rc;
  RemoteConfigService(this._rc);

  bool get pointsEnabled {
    try {
      return _rc?.getBool('points_enabled') ?? true;
    } catch (_) {
      return true;
    }
  }

  String get aiAssistLevel {
    try {
      return _rc?.getString('ai_assist_level') ?? 'basic';
    } catch (_) {
      return 'basic';
    }
  }

  String get badgeVariant {
    try {
      return _rc?.getString('ab_badge_variant') ?? 'A';
    } catch (_) {
      return 'A';
    }
  }

  String get remindersFunctionUrl {
    try {
      return _rc?.getString('reminders_function_url') ?? '';
    } catch (_) {
      return '';
    }
  }
}
