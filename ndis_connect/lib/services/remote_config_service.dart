import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _rc;
  RemoteConfigService(this._rc);

  bool get pointsEnabled => _rc.getBool('points_enabled');
  String get aiAssistLevel => _rc.getString('ai_assist_level');
  String get badgeVariant => _rc.getString('ab_badge_variant');
  String get remindersFunctionUrl => _rc.getString('reminders_function_url');
}
