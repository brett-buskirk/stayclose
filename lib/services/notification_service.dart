import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/services/contact_storage.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ContactStorage _contactStorage = ContactStorage();

  Future<void> init() async {
    // Initialize timezone data first
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/New_York'));
      print('Timezone set to: America/New_York');
    } catch (e) {
      print('Timezone initialization failed: $e');
      tz.setLocalLocation(tz.local);
      print('Timezone set to local: ${tz.local}');
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('Flutter local notifications initialized');
    
    // Create notification channels explicitly
    await _createNotificationChannels();
    
    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Request permissions for Android
    final androidPermission = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    print('Android notification permission result: $androidPermission');
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      // Create the daily reminder channel with maximum priority settings
      const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
        'daily_contact_reminder',
        'Daily Kindred Reminder',
        description: 'Daily reminder to check your kindred of the day',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );
      
      // Create the general reminders channel with maximum priority settings
      const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
        'stayclose_reminders',
        'StayClose Reminders',
        description: 'Daily contact reminders and important date notifications',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );
      
      await androidImplementation.createNotificationChannel(dailyChannel);
      await androidImplementation.createNotificationChannel(remindersChannel);
      print('Created notification channels: daily_contact_reminder, stayclose_reminders');
      
      // Check exact alarm permission status
      try {
        final hasExactAlarmPermission = await androidImplementation.canScheduleExactNotifications();
        print('Exact alarm permission granted: $hasExactAlarmPermission');
        
        if (hasExactAlarmPermission != true) {
          print('WARNING: Exact alarm permission not granted - scheduled notifications may not work');
          // Request exact alarm permission
          await androidImplementation.requestExactAlarmsPermission();
          print('Requested exact alarms permission');
        }
      } catch (e) {
        print('Error checking exact alarm permissions: $e');
      }
    }
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'stayclose_reminders',
      'StayClose Reminders',
      channelDescription: 'Daily contact reminders and important date notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyContactReminder() async {
    try {
      // Get user's preferred notification time, default to 9:00 AM
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // ID for daily kindred reminder
        'Time to reach out! 📱',
        "Check who's your kindred of the day",
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_contact_reminder',
            'Daily Kindred Reminder',
            channelDescription: 'Daily reminder to check your kindred of the day',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showWhen: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      print('Daily nudge scheduled successfully!');
      print('  - Target time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      print('  - Next scheduled: $scheduledTime');
      print('  - Current time: ${tz.TZDateTime.now(tz.local)}');
      print('  - Time until nudge: ${scheduledTime.difference(tz.TZDateTime.now(tz.local))}');
    } catch (e) {
      print('Failed to schedule daily nudge: $e');
      // For debugging: Check if it's an exact alarm permission issue
      if (e.toString().contains('exact_alarms_not_permitted')) {
        print('HINT: User needs to enable "Alarms & reminders" permission for this app in device settings');
      }
      rethrow; // Re-throw so calling code can handle it
    }
  }

  // Method called from settings to update the daily notification
  Future<void> scheduleDailyContactNotification() async {
    // Cancel existing daily notification
    await flutterLocalNotificationsPlugin.cancel(1);
    // Schedule with new time
    await scheduleDailyContactReminder();
  }

  Future<void> scheduleImportantDateNotifications() async {
    final contacts = await _contactStorage.getContacts();
    
    // Clear existing important date notifications (IDs 1000+)
    for (int i = 1000; i < 2000; i++) {
      await flutterLocalNotificationsPlugin.cancel(i);
    }
    
    int notificationId = 1000;
    final now = DateTime.now();
    
    for (final contact in contacts) {
      for (final importantDate in contact.importantDates) {
        // Schedule notification for this year
        DateTime thisYearDate = DateTime(now.year, importantDate.date.month, importantDate.date.day);
        
        // If the date has passed this year, schedule for next year
        if (thisYearDate.isBefore(now)) {
          thisYearDate = DateTime(now.year + 1, importantDate.date.month, importantDate.date.day);
        }
        
        // Schedule notification for the day of the important date
        await _scheduleImportantDateNotification(
          notificationId++,
          contact,
          importantDate,
          thisYearDate,
          isOnDay: true,
        );
        
        // Schedule reminder notification 3 days before
        final reminderDate = thisYearDate.subtract(Duration(days: 3));
        if (reminderDate.isAfter(now)) {
          await _scheduleImportantDateNotification(
            notificationId++,
            contact,
            importantDate,
            reminderDate,
            isOnDay: false,
          );
        }
      }
    }
  }

  Future<void> _scheduleImportantDateNotification(
    int id,
    Contact contact,
    ImportantDate importantDate,
    DateTime scheduledDate,
    {required bool isOnDay}
  ) async {
    final title = isOnDay 
        ? '🎉 ${importantDate.name} Today!'
        : '📅 Upcoming: ${importantDate.name}';
    
    final body = isOnDay
        ? "Today is ${contact.name}'s ${importantDate.name}. Don't forget to reach out!"
        : "${contact.name}'s ${importantDate.name} is in 3 days (${importantDate.date.month}/${importantDate.date.day})";

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate, 9, 0), // 9:00 AM on the scheduled date
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'important_dates',
          'Important Dates',
          channelDescription: 'Notifications for important dates like birthdays and anniversaries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // Helper method to get the next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Helper method to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime, int hour, int minute) {
    return tz.TZDateTime(tz.local, dateTime.year, dateTime.month, dateTime.day, hour, minute);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showDailyContactNotification(Contact contact) async {
    await showNotification(
      2, // ID for immediate daily kindred notification
      '👋 Your kindred of the day',
      'Time to reach out to ${contact.name}!',
    );
  }

  Future<void> showTestNotification() async {
    await showNotification(
      999, // ID for test notification
      '👋 Test Nudge',
      'This is a test nudge from StayClose. Your nudges are working correctly!',
    );
  }
}