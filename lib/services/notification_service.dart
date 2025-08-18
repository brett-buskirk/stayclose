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
      
      // Try to detect local timezone, fall back to America/New_York if detection fails
      String? detectedTimeZone;
      try {
        // Try to get the device's actual timezone
        detectedTimeZone = now.timeZoneName;
        // Map common timezone abbreviations to full names
        if (detectedTimeZone == 'EST' || detectedTimeZone == 'EDT') {
          detectedTimeZone = 'America/New_York';
        } else if (detectedTimeZone == 'PST' || detectedTimeZone == 'PDT') {
          detectedTimeZone = 'America/Los_Angeles';
        } else if (detectedTimeZone == 'CST' || detectedTimeZone == 'CDT') {
          detectedTimeZone = 'America/Chicago';
        } else if (detectedTimeZone == 'MST' || detectedTimeZone == 'MDT') {
          detectedTimeZone = 'America/Denver';
        }
        
        // Try to set the detected timezone
        tz.setLocalLocation(tz.getLocation(detectedTimeZone));
        print('Successfully set timezone to detected: $detectedTimeZone');
      } catch (timezoneError) {
        print('Failed to set detected timezone ($detectedTimeZone): $timezoneError');
        // Fall back to America/New_York (app author's timezone)
        try {
          tz.setLocalLocation(tz.getLocation('America/New_York'));
          print('Fell back to America/New_York timezone');
        } catch (fallbackError) {
          print('Failed to set fallback timezone: $fallbackError');
          // Final fallback to local device time
          tz.setLocalLocation(tz.local);
          print('Using device local timezone as final fallback');
        }
      }
      
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
    
    // Request permissions for Android with detailed error handling
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Request basic notification permission first
        final notificationPermission = await androidImplementation.requestNotificationsPermission();
        print('Android notification permission result: $notificationPermission');
        
        if (notificationPermission != true) {
          print('WARNING: Basic notification permission denied - notifications will not work');
        }
        
        // Request all notification-related permissions
        await _requestAllAndroidPermissions(androidImplementation);
      } else {
        print('WARNING: Could not get Android notification implementation');
      }
    } catch (e) {
      print('ERROR requesting Android permissions: $e');
    }
  }

  Future<void> _requestAllAndroidPermissions(AndroidFlutterLocalNotificationsPlugin androidImplementation) async {
    // Check and request exact alarm permission
    try {
      final hasExactAlarmPermission = await androidImplementation.canScheduleExactNotifications();
      print('Exact alarm permission status: $hasExactAlarmPermission');
      
      if (hasExactAlarmPermission != true) {
        print('Requesting exact alarms permission...');
        await androidImplementation.requestExactAlarmsPermission();
        
        // Recheck after request
        final recheckExactAlarm = await androidImplementation.canScheduleExactNotifications();
        print('Exact alarm permission after request: $recheckExactAlarm');
        
        if (recheckExactAlarm != true) {
          print('CRITICAL: Exact alarm permission still denied - scheduled notifications will not work');
          print('HINT: User must manually enable "Alarms & reminders" permission in device settings');
        }
      } else {
        print('Exact alarm permission already granted');
      }
    } catch (e) {
      print('ERROR checking/requesting exact alarm permissions: $e');
    }
    
    // Request full screen intent permission for Android 14+
    try {
      await androidImplementation.requestFullScreenIntentPermission();
      print('Requested full screen intent permission');
    } catch (e) {
      print('ERROR requesting full screen intent permission: $e');
    }
    
    // Check if device is ignoring battery optimizations
    try {
      final isBatteryOptimized = await androidImplementation.getActiveNotificationMessagingStyle();
      // Note: This is a workaround as the plugin doesn't have a direct battery optimization check
      print('Battery optimization check completed (workaround used)');
    } catch (e) {
      print('Battery optimization check failed: $e');
    }
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

      // Pre-flight checks before scheduling
      print('Pre-flight notification checks:');
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        final canScheduleExact = await androidImpl.canScheduleExactNotifications();
        print('  - Can schedule exact notifications: $canScheduleExact');
        
        if (canScheduleExact != true) {
          throw Exception('Cannot schedule exact notifications - exact alarm permission required');
        }
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
            autoCancel: false,
            ongoing: false,
            silent: false,
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

  // Diagnostic method to check all notification permissions and settings
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};
    
    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        // Check basic notification permission
        try {
          status['notifications_enabled'] = await androidImpl.areNotificationsEnabled();
        } catch (e) {
          status['notifications_enabled'] = 'error: $e';
        }
        
        // Check exact alarm permission
        try {
          status['exact_alarms_permitted'] = await androidImpl.canScheduleExactNotifications();
        } catch (e) {
          status['exact_alarms_permitted'] = 'error: $e';
        }
        
        // Check scheduled notifications count
        try {
          final pendingRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
          status['pending_notifications_count'] = pendingRequests.length;
          status['pending_notifications'] = pendingRequests.map((req) => {
            'id': req.id,
            'title': req.title,
            'body': req.body,
          }).toList();
        } catch (e) {
          status['pending_notifications'] = 'error: $e';
        }
      }
      
      // Add timezone information
      status['timezone_info'] = {
        'current_timezone': tz.local.name,
        'current_time': tz.TZDateTime.now(tz.local).toString(),
        'device_timezone': DateTime.now().timeZoneName,
        'device_offset': DateTime.now().timeZoneOffset.toString(),
      };
      
    } catch (e) {
      status['error'] = e.toString();
    }
    
    return status;
  }

  // Print comprehensive notification diagnostics
  Future<void> printNotificationDiagnostics() async {
    print('=== NOTIFICATION DIAGNOSTICS ===');
    final status = await getNotificationStatus();
    
    for (final entry in status.entries) {
      print('${entry.key}: ${entry.value}');
    }
    print('=== END DIAGNOSTICS ===');
  }
}