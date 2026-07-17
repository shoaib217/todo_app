import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:todo_app/core/database/database.dart';

@pragma('vm:entry-point')
Future<void> _handleNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  if (notificationResponse.actionId == 'complete_task') {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      final int? id = int.tryParse(payload);
      if (id != null) {
        final db = appDatabase;
        await db.toggleTodoLocal(id, true);

        await NotificationService.cancelReminder(id);
      }
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
    );
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleReminder(
    int id,
    String title,
    DateTime scheduledDate,
  ) async {
    if (kIsWeb) return;
    // Only schedule if the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: 'Task Reminder',
      body: title,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Todo Reminders',
          icon: '@mipmap/launcher_icon',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'complete_task',
              'Mark Completed',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id.toString(),
    );
  }

  static Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id: id);
  }
}
