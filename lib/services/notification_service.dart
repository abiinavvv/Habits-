import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification settings
  static Future<void> initialize() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Android notification details
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification details
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Schedule a notification for a todo
  static Future<void> scheduleTodoNotification(Todo todo) async {
    // Check if due date exists
    if (todo.dueDate == null) return;

    // Android notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'todo_channel',
      'Todo Notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      todo.id.hashCode, // Unique ID
      'Todo Reminder: ${todo.title}',
      todo.description ?? 'Your task is due soon!',
      tz.TZDateTime.from(todo.dueDate!, tz.local),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancel a specific todo notification
  static Future<void> cancelTodoNotification(String todoId) async {
    await flutterLocalNotificationsPlugin.cancel(todoId.hashCode);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
