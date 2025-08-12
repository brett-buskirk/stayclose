import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0); // Default 9:00 AM
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationTime();
  }

  Future<void> _loadNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      
      setState(() {
        _notificationTime = TimeOfDay(hour: hour, minute: minute);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification time: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationTime(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);
      
      setState(() {
        _notificationTime = time;
      });

      // Reschedule notifications with new time
      await _notificationService.scheduleDailyContactNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification time updated to ${time.format(context)}'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      print('Error saving notification time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
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

    if (picked != null && picked != _notificationTime) {
      await _saveNotificationTime(picked);
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification'),
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
                          'Daily Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Set when you\'d like to receive your daily kindred reminder',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          leading: Icon(Icons.schedule, color: Colors.teal),
                          title: Text('Notification Time'),
                          subtitle: Text(_notificationTime.format(context)),
                          trailing: Icon(Icons.chevron_right),
                          onTap: _selectTime,
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.notification_add, color: Colors.blue),
                          title: Text('Send Test Notification'),
                          subtitle: Text('Test your notification settings'),
                          trailing: Icon(Icons.send),
                          onTap: _testNotification,
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
                          'About Daily Reminders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• Each day at your chosen time, you\'ll receive a notification\n'
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