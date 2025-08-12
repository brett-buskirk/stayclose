
import 'package:flutter/material.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/screens/add_edit_contact_screen.dart';
import 'package:stayclose/screens/settings_screen.dart';
import 'package:stayclose/services/contact_storage.dart';
import 'package:stayclose/services/notification_service.dart';
import 'package:stayclose/services/image_service.dart';

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final ContactStorage _contactStorage = ContactStorage();
  final NotificationService _notificationService = NotificationService();
  final ImageService _imageService = ImageService();
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactStorage.getContacts();
    setState(() {
      _contacts = contacts;
    });
    // Reschedule notifications when contacts change
    try {
      await _notificationService.scheduleImportantDateNotifications();
    } catch (e) {
      print('Failed to reschedule notifications: $e');
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _contacts.removeWhere((c) => c.id == contact.id);
      await _contactStorage.saveContacts(_contacts);
      _loadContacts();
    }
  }


  Widget _buildContactCard(Contact contact) {
    final upcomingDates = contact.importantDates
        .where((date) {
          final now = DateTime.now();
          final thisYear = DateTime(now.year, date.date.month, date.date.day);
          final nextYear = DateTime(now.year + 1, date.date.month, date.date.day);
          
          return (thisYear.isAfter(now) && thisYear.difference(now).inDays <= 30) ||
                 (thisYear.isBefore(now) && nextYear.difference(now).inDays <= 30);
        })
        .toList();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: _imageService.buildContactAvatar(
          imagePath: contact.imagePath,
          contactName: contact.name,
          radius: 25,
        ),
        title: Text(
          contact.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phone.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(contact.phone),
                ],
              ),
            if (contact.email.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(contact.email),
                ],
              ),
            if (upcomingDates.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Upcoming: ${upcomingDates.first.name}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditContactScreen(contact: contact),
                ),
              ).then((_) => _loadContacts());
            } else if (value == 'delete') {
              _deleteContact(contact);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditContactScreen(contact: contact),
            ),
          ).then((_) => _loadContacts());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Kindred'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No kindred yet',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first kindred to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                return _buildContactCard(_contacts[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditContactScreen(),
            ),
          ).then((_) => _loadContacts());
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Kindred'),
      ),
    );
  }
}
