import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  TimeOfDay _nudgeTime = TimeOfDay(hour: 9, minute: 0); // Default 9:00 AM
  TimeOfDay _importantDateTime = TimeOfDay(hour: 9, minute: 0); // Default 9:00 AM
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      final importantHour = prefs.getInt('important_date_hour') ?? 9;
      final importantMinute = prefs.getInt('important_date_minute') ?? 0;
      final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
      
      setState(() {
        _nudgeTime = TimeOfDay(hour: hour, minute: minute);
        _importantDateTime = TimeOfDay(hour: importantHour, minute: importantMinute);
        _currentThemeMode = ThemeMode.values[themeModeIndex];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNudgeTime(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);
      
      setState(() {
        _nudgeTime = time;
      });

      // Always show success message for time update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nudge time updated to ${time.format(context)}'),
            backgroundColor: Colors.teal,
          ),
        );
      }

      // Try to reschedule notifications, but don't fail the whole operation if this fails
      try {
        await _notificationService.scheduleDailyContactNotification();
      } catch (notificationError) {
        print('Failed to reschedule notifications: $notificationError');
        // Show helpful message about permissions
        if (mounted && notificationError.toString().contains('exact_alarms_not_permitted')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time saved! To receive scheduled nudges, enable "Alarms & reminders" for StayClose in device settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time saved, but nudge scheduling may need device permissions'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving nudge time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update nudge time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveImportantDateTime(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('important_date_hour', time.hour);
      await prefs.setInt('important_date_minute', time.minute);
      
      setState(() {
        _importantDateTime = time;
      });

      // Always show success message for time update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Important date notification time updated to ${time.format(context)}'),
            backgroundColor: Colors.teal,
          ),
        );
      }

      // Try to reschedule important date notifications
      try {
        await _notificationService.scheduleImportantDateNotifications();
      } catch (notificationError) {
        print('Failed to reschedule important date notifications: $notificationError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time saved, but notification scheduling may need device permissions'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving important date time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update important date notification time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _nudgeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _nudgeTime) {
      await _saveNudgeTime(picked);
    }
  }

  Future<void> _selectImportantDateTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _importantDateTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.orange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _importantDateTime) {
      await _saveImportantDateTime(picked);
    }
  }

  Future<void> _changeTheme(ThemeMode themeMode) async {
    try {
      final appState = MyApp.of(context);
      if (appState != null) {
        await appState.changeTheme(themeMode);
        setState(() {
          _currentThemeMode = themeMode;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme updated to ${_getThemeName(themeMode)}'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      print('Error changing theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update theme'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showThemeDialog() async {
    final ThemeMode? selectedTheme = await showDialog<ThemeMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Row(
                  children: [
                    Icon(Icons.brightness_auto, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text('System'),
                  ],
                ),
                subtitle: Text('Follow device setting'),
                value: ThemeMode.system,
                groupValue: _currentThemeMode,
                onChanged: (ThemeMode? value) {
                  Navigator.pop(context, value);
                },
                activeColor: Colors.teal,
              ),
              RadioListTile<ThemeMode>(
                title: Row(
                  children: [
                    Icon(Icons.light_mode, color: Colors.amber),
                    SizedBox(width: 12),
                    Text('Light'),
                  ],
                ),
                subtitle: Text('Light theme'),
                value: ThemeMode.light,
                groupValue: _currentThemeMode,
                onChanged: (ThemeMode? value) {
                  Navigator.pop(context, value);
                },
                activeColor: Colors.teal,
              ),
              RadioListTile<ThemeMode>(
                title: Row(
                  children: [
                    Icon(Icons.dark_mode, color: Colors.indigo),
                    SizedBox(width: 12),
                    Text('Dark'),
                  ],
                ),
                subtitle: Text('Dark theme'),
                value: ThemeMode.dark,
                groupValue: _currentThemeMode,
                onChanged: (ThemeMode? value) {
                  Navigator.pop(context, value);
                },
                activeColor: Colors.teal,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedTheme != null && selectedTheme != _currentThemeMode) {
      await _changeTheme(selectedTheme);
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await _notificationService.scheduleTestNotificationInOneMinute();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scheduled test nudge for 1 minute from now!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error scheduling test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling test nudge'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Nudges',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Set when you\'d like to receive your daily kindred nudge',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          leading: Icon(Icons.schedule, color: Colors.teal),
                          title: Text('Nudge Time'),
                          subtitle: Text(_nudgeTime.format(context)),
                          trailing: Icon(Icons.chevron_right),
                          onTap: _selectTime,
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.schedule, color: Colors.orange),
                          title: Text('Test Scheduled Nudge'),
                          subtitle: Text('Schedule a test nudge for 1 minute from now'),
                          trailing: Icon(Icons.schedule_send),
                          onTap: _testScheduledNotification,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Date Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Set when you\'d like to receive notifications for birthdays, anniversaries, and other important dates',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          leading: Icon(Icons.event_note, color: Colors.orange),
                          title: Text('Important Date Time'),
                          subtitle: Text(_importantDateTime.format(context)),
                          trailing: Icon(Icons.chevron_right),
                          onTap: _selectImportantDateTime,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Choose your preferred theme for the app',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          leading: Icon(
                            _currentThemeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : _currentThemeMode == ThemeMode.light
                                    ? Icons.light_mode
                                    : Icons.brightness_auto,
                            color: Colors.teal,
                          ),
                          title: Text('Theme'),
                          subtitle: Text(_getThemeName(_currentThemeMode)),
                          trailing: Icon(Icons.chevron_right),
                          onTap: _showThemeDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Daily Nudges',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• A nudge is a gentle reminder to reach out to someone you care about\n'
                          '• Each day at your chosen time, you\'ll receive a nudge\n'
                          '• The app randomly selects one of your kindred\n'
                          '• This helps you stay connected with important people\n'
                          '• You can change the time anytime in these settings',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}