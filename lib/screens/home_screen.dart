import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/screens/contact_list_screen.dart';
import 'package:stayclose/screens/add_edit_contact_screen.dart';
import 'package:stayclose/screens/settings_screen.dart';
import 'package:stayclose/screens/welcome_screen.dart';
import 'package:stayclose/services/contact_storage.dart';
import 'package:stayclose/services/daily_contact_service.dart';
import 'package:stayclose/services/notification_service.dart';
import 'package:stayclose/services/image_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      
      // Check if we should show welcome screen after loading contacts
      await _checkFirstTime();
      
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
      
      // Still check for first time even if loading failed
      await _checkFirstTime();
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorDialog('Unable to make phone call', 'Phone app not available on this device');
      }
    } catch (e) {
      _showErrorDialog('Error making phone call', e.toString());
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showErrorDialog('Unable to send SMS', 'SMS app not available on this device');
      }
    } catch (e) {
      _showErrorDialog('Error sending SMS', e.toString());
    }
  }

  Future<void> _sendEmail(String emailAddress) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: emailAddress);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorDialog('Unable to send email', 'Email app not available on this device');
      }
    } catch (e) {
      _showErrorDialog('Error sending email', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    
    // Show welcome screen if first time AND no contacts
    if (!hasSeenWelcome && _contacts.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeScreen();
      });
    }
  }

  Future<void> _showWelcomeScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(
          onComplete: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_seen_welcome', true);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showInfoDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(),
      ),
    );
  }

  Future<void> _showImportContactsDialog() async {
    // Request contact permission
    final permissionStatus = await Permission.contacts.request();
    
    if (permissionStatus.isDenied) {
      _showErrorDialog(
        'Permission Required',
        'Contact access is needed to import contacts from your device. Please grant permission in settings.',
      );
      return;
    }

    if (permissionStatus.isPermanentlyDenied) {
      _showErrorDialog(
        'Permission Required',
        'Contact access was permanently denied. Please enable it in device settings.',
      );
      await openAppSettings();
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Loading device contacts...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Fetch device contacts
      final deviceContacts = await flutter_contacts.FlutterContacts.getContacts(withProperties: true);
      
      // Close loading dialog
      Navigator.pop(context);

      if (deviceContacts.isEmpty) {
        _showErrorDialog('No Contacts', 'No contacts found on your device.');
        return;
      }

      // Show contact selection dialog
      _showContactSelectionDialog(deviceContacts.toList());
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorDialog('Error', 'Failed to load contacts: $e');
    }
  }

  void _showContactSelectionDialog(List<flutter_contacts.Contact> deviceContacts) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              AppBar(
                title: Text('Select Contacts to Import'),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              Expanded(
                child: ContactSelectionList(
                  deviceContacts: deviceContacts,
                  onContactsSelected: (selectedContacts) {
                    Navigator.pop(context);
                    _importSelectedContacts(selectedContacts);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importSelectedContacts(List<flutter_contacts.Contact> selectedContacts) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Importing ${selectedContacts.length} contacts...'),
                ],
              ),
            ),
          ),
        ),
      );

      int importedCount = 0;
      
      for (final deviceContact in selectedContacts) {
        // Convert device contact to our Contact model
        final contact = Contact(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + importedCount.toString(),
          name: deviceContact.displayName.isNotEmpty ? deviceContact.displayName : 'Unknown',
          phone: deviceContact.phones.isNotEmpty 
            ? deviceContact.phones.first.number 
            : '',
          email: deviceContact.emails.isNotEmpty 
            ? deviceContact.emails.first.address 
            : '',
          imagePath: null, // We'll handle image import separately if needed
          importantDates: [], // User can add these manually later
        );

        // Only import contacts with at least a name and phone/email
        if (contact.name.isNotEmpty && 
            (contact.phone.isNotEmpty || contact.email.isNotEmpty)) {
          _contacts.add(contact);
          importedCount++;
        }
      }

      // Save the updated contacts list
      await _contactStorage.saveContacts(_contacts);
      
      Navigator.pop(context); // Close loading dialog

      // Refresh the contact list and daily contact
      await _loadContactsAndSelectDaily();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $importedCount contacts'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Import Failed', 'Failed to import contacts: $e');
    }
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
              SizedBox(height: 12),
              Text(
                'or',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showImportContactsDialog,
                icon: Icon(Icons.contact_phone, color: Colors.orange),
                label: Text('Import from Device'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
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
                      '${date.date.month}/${date.date.day}/${date.date.year}',
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
                  onPressed: () => _makePhoneCall(_dailyContact!.phone),
                  icon: Icon(Icons.phone),
                  label: Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_dailyContact!.phone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _sendSMS(_dailyContact!.phone),
                  icon: Icon(Icons.message),
                  label: Text('Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_dailyContact!.email.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _sendEmail(_dailyContact!.email),
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
            onPressed: _showInfoDialog,
            icon: Icon(Icons.info_outline),
            tooltip: 'About StayClose',
          ),
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
              } else if (value == 'import_contacts') {
                _showImportContactsDialog();
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
                value: 'import_contacts',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Import from Device'),
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
          : _dailyContact == null 
              ? Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height - kToolbarHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        child: Image.asset(
                          'assets/favicon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Kindred of the Day',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      _buildDailyContactCard(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
                        width: 60,
                        height: 60,
                        child: Image.asset(
                          'assets/favicon.png',
                          fit: BoxFit.contain,
                        ),
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

class ContactSelectionList extends StatefulWidget {
  final List<flutter_contacts.Contact> deviceContacts;
  final Function(List<flutter_contacts.Contact>) onContactsSelected;

  ContactSelectionList({
    required this.deviceContacts,
    required this.onContactsSelected,
  });

  @override
  _ContactSelectionListState createState() => _ContactSelectionListState();
}

class _ContactSelectionListState extends State<ContactSelectionList> {
  Map<String, bool> _selectedContacts = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize all contacts as not selected
    for (final contact in widget.deviceContacts) {
      _selectedContacts[contact.id] = false;
    }
  }

  List<flutter_contacts.Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return widget.deviceContacts;
    }
    return widget.deviceContacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<flutter_contacts.Contact> get _selectedContactsList {
    return widget.deviceContacts.where((contact) {
      return _selectedContacts[contact.id] == true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Select all/none buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (final contact in _filteredContacts) {
                      _selectedContacts[contact.id] = true;
                    }
                  });
                },
                icon: Icon(Icons.select_all),
                label: Text('Select All'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedContacts.updateAll((key, value) => false);
                  });
                },
                icon: Icon(Icons.clear),
                label: Text('Clear All'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              Spacer(),
              Text(
                '${_selectedContactsList.length} selected',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 8),
        
        // Contact list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];
              final isSelected = _selectedContacts[contact.id] ?? false;
              
              return CheckboxListTile(
                title: Text(contact.displayName.isEmpty ? 'Unknown' : contact.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.phones.isNotEmpty)
                      Text('📞 ${contact.phones.first.number}'),
                    if (contact.emails.isNotEmpty)
                      Text('📧 ${contact.emails.first.address}'),
                  ],
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    _selectedContacts[contact.id] = value ?? false;
                  });
                },
                activeColor: Colors.teal,
              );
            },
          ),
        ),
        
        // Import button
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedContactsList.isEmpty 
                ? null 
                : () => widget.onContactsSelected(_selectedContactsList),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Import ${_selectedContactsList.length} Contacts',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}