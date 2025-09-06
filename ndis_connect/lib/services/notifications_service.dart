import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground message handling – integrate local notifications if desired
      // For now this is a no-op to keep scaffolding lightweight.
    });
  }

  Future<String?> getToken() => _messaging.getToken();
}

