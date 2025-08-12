import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/screens/contact_list_screen.dart';
import 'package:stayclose/screens/add_edit_contact_screen.dart';
import 'package:stayclose/screens/settings_screen.dart';
import 'package:stayclose/services/contact_storage.dart';
import 'package:stayclose/services/daily_contact_service.dart';
import 'package:stayclose/services/notification_service.dart';
import 'package:stayclose/services/image_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContactStorage _contactStorage = ContactStorage();
  final DailyContactService _dailyContactService = DailyContactService();
  final NotificationService _notificationService = NotificationService();
  final ImageService _imageService = ImageService();
  Contact? _dailyContact;
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadContactsAndSelectDaily();
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.init();
      // Schedule notifications after successful initialization
      await _notificationService.scheduleDailyContactReminder();
      await _notificationService.scheduleImportantDateNotifications();
    } catch (e) {
      print('Notification service initialization failed: $e');
      // App will continue to work without notifications
    }
  }

  Future<void> _loadContactsAndSelectDaily() async {
    try {
      final contacts = await _contactStorage.getContacts();
      final dailyContact = await _dailyContactService.selectDailyContact(contacts);
      
      setState(() {
        _contacts = contacts;
        _dailyContact = dailyContact;
        _isLoading = false;
      });
      
      // Reschedule notifications when contacts change
      try {
        await _notificationService.scheduleImportantDateNotifications();
      } catch (e) {
        print('Failed to reschedule notifications: $e');
      }
    } catch (e) {
      print('Failed to load contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  Future<void> _refreshDailyContact() async {
    await _dailyContactService.resetDailyContact();
    await _loadContactsAndSelectDaily();
  }

  void _navigateToContactsList() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactListScreen(),
      ),
    );
    
    // Refresh when returning from contacts list
    if (result == true || result == null) {
      await _loadContactsAndSelectDaily();
    }
  }

  void _navigateToAddContact() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(),
      ),
    );
    
    // Refresh when returning from add contact
    if (result == true || result == null) {
      await _loadContactsAndSelectDaily();
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(),
      ),
    );
  }

  Widget _buildDailyContactCard() {
    if (_dailyContact == null) {
      return Card(
        elevation: 4,
        margin: EdgeInsets.all(20),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 20),
              Text(
                'No kindred yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Add your first kindred to get daily reminders!',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _navigateToAddContact,
                icon: Icon(Icons.add),
                label: Text('Add Your First Kindred'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(20),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            _imageService.buildLargeContactAvatar(
              imagePath: _dailyContact!.imagePath,
              contactName: _dailyContact!.name,
              radius: 60,
            ),
            SizedBox(height: 20),
            Text(
              _dailyContact!.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (_dailyContact!.phone.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.teal),
                  SizedBox(width: 12),
                  Expanded(child: Text(_dailyContact!.phone, style: TextStyle(fontSize: 16))),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, _dailyContact!.phone, 'Phone number'),
                    icon: Icon(Icons.copy, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            if (_dailyContact!.email.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.email, color: Colors.teal),
                  SizedBox(width: 12),
                  Expanded(child: Text(_dailyContact!.email, style: TextStyle(fontSize: 16))),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, _dailyContact!.email, 'Email'),
                    icon: Icon(Icons.copy, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            if (_dailyContact!.importantDates.isNotEmpty) ...[
              Divider(),
              SizedBox(height: 12),
              Text(
                'Important Dates',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              ..._dailyContact!.importantDates.map<Widget>((date) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('${date.name}: '),
                    Text(
                      '${date.date.day}/${date.date.month}/${date.date.year}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_dailyContact == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Why not reach out today?',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_dailyContact!.phone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Call ${_dailyContact!.name}'),
                        content: Text('Would you like to call ${_dailyContact!.phone}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _copyToClipboard(context, _dailyContact!.phone, 'Phone number');
                            },
                            child: Text('Copy Number'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.phone),
                  label: Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Text ${_dailyContact!.name}'),
                      content: Text('Send a message to stay in touch!'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (_dailyContact!.phone.isNotEmpty) {
                              _copyToClipboard(context, _dailyContact!.phone, 'Phone number');
                            }
                          },
                          child: Text('Copy Number'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.message),
                label: Text('Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_dailyContact!.email.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Email ${_dailyContact!.name}'),
                        content: Text('Would you like to email ${_dailyContact!.email}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _copyToClipboard(context, _dailyContact!.email, 'Email');
                            },
                            child: Text('Copy Email'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.email),
                  label: Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StayClose'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _navigateToContactsList,
            icon: Icon(Icons.people),
            tooltip: 'All Kindred',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshDailyContact();
              } else if (value == 'add_contact') {
                _navigateToAddContact();
              } else if (value == 'settings') {
                _navigateToSettings();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Pick New Kindred'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_contact',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Add Kindred'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Icon(
                    Icons.today,
                    size: 60,
                    color: Colors.teal,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Kindred of the Day',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  _buildDailyContactCard(),
                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 40),
                ],
              ),
            ),
      floatingActionButton: _contacts.isNotEmpty ? FloatingActionButton(
        onPressed: _navigateToAddContact,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add Kindred',
        child: Icon(Icons.add),
      ) : null,
    );
  }
}