import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType {
  taskReminder,
  appointmentReminder,
  budgetAlert,
  serviceUpdate,
  emergency,
  general
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime scheduledTime;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.scheduledTime,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values
          .firstWhere((e) => e.name == map['type'], orElse: () => NotificationType.general),
      priority: NotificationPriority.values
          .firstWhere((e) => e.name == map['priority'], orElse: () => NotificationPriority.normal),
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      data: map['data'] as Map<String, dynamic>?,
    );
  }
}

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late SharedPreferences _prefs;
  final List<NotificationData> _scheduledNotifications = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _requestPermissions();
    await _setupFirebaseMessaging();
    await _loadScheduledNotifications();
  }

  Future<bool> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      debugPrint('Failed to setup Firebase messaging: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
  }

  Future<void> scheduleNotification(NotificationData notification) async {
    try {
      _scheduledNotifications.add(notification);
      await _saveScheduledNotifications();
      debugPrint('Scheduled notification: ${notification.title}');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(String notificationId) async {
    try {
      _scheduledNotifications.removeWhere((n) => n.id == notificationId);
      await _saveScheduledNotifications();
      debugPrint('Cancelled notification: $notificationId');
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  List<NotificationData> getScheduledNotifications() {
    return List.from(_scheduledNotifications);
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
    String? description,
  }) async {
    final notification = NotificationData(
      id: 'task_reminder_$taskId',
      title: 'Task Reminder',
      body: description ?? 'Don\'t forget: $taskTitle',
      type: NotificationType.taskReminder,
      priority: NotificationPriority.normal,
      scheduledTime: reminderTime,
      data: {'taskId': taskId, 'taskTitle': taskTitle},
    );
    await scheduleNotification(notification);
  }

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> _saveScheduledNotifications() async {
    try {
      final notificationsJson = _scheduledNotifications.map((n) => n.toMap()).toList();
      await _prefs.setString('scheduled_notifications', jsonEncode(notificationsJson));
    } catch (e) {
      debugPrint('Failed to save scheduled notifications: $e');
    }
  }

  Future<void> _loadScheduledNotifications() async {
    try {
      final notificationsJson = _prefs.getString('scheduled_notifications');
      if (notificationsJson != null) {
        final notificationsList = jsonDecode(notificationsJson) as List<dynamic>;
        _scheduledNotifications.clear();
        _scheduledNotifications.addAll(
          notificationsList
              .map((n) => NotificationData.fromMap(n as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to load scheduled notifications: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
