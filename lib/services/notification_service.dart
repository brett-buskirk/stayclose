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
      
      // Get device timezone information for debugging
      final DateTime now = DateTime.now();
      final String timeZoneName = now.timeZoneName;
      final Duration timeZoneOffset = now.timeZoneOffset;
      print('Device timezone name: $timeZoneName');
      print('Device timezone offset: $timeZoneOffset');
      print('Current local time: $now');
      print('Current UTC time: ${now.toUtc()}');
      
      // Set to America/New_York since you're in Eastern time
      tz.setLocalLocation(tz.getLocation('America/New_York'));
      
      // Verify the timezone is set correctly
      final tz.TZDateTime tzNow = tz.TZDateTime.now(tz.local);
      print('TZ timezone location: ${tz.local}');
      print('TZ current time: $tzNow');
      print('Timezone initialization completed successfully');
      
    } catch (e) {
      print('Timezone initialization failed: $e');
      // Fallback to UTC but warn about it
      tz.setLocalLocation(tz.UTC);
      print('WARNING: Fell back to UTC timezone - notifications may be off by timezone offset');
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
      
      // Create the important dates channel with maximum priority settings
      const AndroidNotificationChannel importantDatesChannel = AndroidNotificationChannel(
        'important_dates',
        'Important Dates',
        description: 'Notifications for important dates like birthdays and anniversaries',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );
      
      await androidImplementation.createNotificationChannel(dailyChannel);
      await androidImplementation.createNotificationChannel(remindersChannel);
      await androidImplementation.createNotificationChannel(importantDatesChannel);
      print('Created notification channels: daily_contact_reminder, stayclose_reminders, important_dates');
      
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
      
      // Request full screen intent permission for Android 14+
      try {
        await androidImplementation.requestFullScreenIntentPermission();
        print('Requested full screen intent permission');
      } catch (e) {
        print('Error requesting full screen intent permission: $e');
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

      // Get today's kindred to include in notification
      final contacts = await _contactStorage.getContacts();
      String notificationBody = "Check who's your kindred of the day";
      
      if (contacts.isNotEmpty) {
        // Use the same logic as DailyContactService to get today's kindred
        final today = DateTime.now();
        final daysSinceEpoch = today.difference(DateTime(1970, 1, 1)).inDays;
        final kindredIndex = daysSinceEpoch % contacts.length;
        final todaysKindred = contacts[kindredIndex];
        notificationBody = "Your kindred of the day is ${todaysKindred.name}. Time to reach out! 💝";
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // ID for daily kindred reminder
        'Time to reach out! 📱',
        notificationBody,
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
    // Get user's preferred important date notification time, default to 9:00 AM
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('important_date_hour') ?? 9;
    final minute = prefs.getInt('important_date_minute') ?? 0;
    
    final title = isOnDay 
        ? '🎉 ${contact.name}: ${importantDate.name} Today!'
        : '📅 Upcoming: ${contact.name}\'s ${importantDate.name}';
    
    String body;
    if (isOnDay) {
      body = "Today is ${contact.name}'s ${importantDate.name}! 🎉\n" +
             "📞 ${contact.phone.isNotEmpty ? contact.phone : 'No phone'}\n" +
             "✉️ ${contact.email.isNotEmpty ? contact.email : 'No email'}\n" +
             "Don't forget to reach out and celebrate! 💝";
    } else {
      body = "${contact.name}'s ${importantDate.name} is in 3 days (${importantDate.date.month}/${importantDate.date.day}) 📅\n" +
             "📞 ${contact.phone.isNotEmpty ? contact.phone : 'No phone'}\n" +
             "✉️ ${contact.email.isNotEmpty ? contact.email : 'No email'}\n" +
             "Time to plan something special! 💭";
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate, hour, minute),
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

  // Debug function to test scheduled notification in 1 minute
  Future<void> scheduleTestNotificationInOneMinute() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(minutes: 1));
    
    print('DEBUG: Scheduling test notification');
    print('  - Current time: $now');
    print('  - Scheduled for: $scheduledTime');
    print('  - TZ timezone: ${tz.local}');
    print('  - Local DateTime: ${DateTime.now()}');
    print('  - Local timezone offset: ${DateTime.now().timeZoneOffset}');
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      998, // ID for debug test notification
      '🧪 DEBUG: Scheduled Test',
      'This notification was scheduled for 1 minute from now. Time: ${scheduledTime.toString()}',
      scheduledTime,
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
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    print('DEBUG: Test notification scheduled successfully for 1 minute from now');
  }
}