
import 'package:flutter/material.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/screens/add_edit_contact_screen.dart';
import 'package:stayclose/screens/settings_screen.dart';
import 'package:stayclose/services/contact_storage.dart';
import 'package:stayclose/services/notification_service.dart';
import 'package:stayclose/services/image_service.dart';
import 'package:stayclose/services/circle_service.dart';
import 'package:stayclose/widgets/circle_badge.dart';
import 'package:stayclose/widgets/circle_filter_chip.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final ContactStorage _contactStorage = ContactStorage();
  final NotificationService _notificationService = NotificationService();
  final ImageService _imageService = ImageService();
  final CircleService _circleService = CircleService();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<Circle> _circles = [];
  String _searchQuery = '';
  String _selectedCircle = 'All';
  bool _isMultiSelectMode = false;
  Set<String> _selectedContactIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadContacts(),
      _loadCircles(),
    ]);
  }

  Future<void> _loadCircles() async {
    try {
      final circles = await _circleService.getAllCircles();
      setState(() {
        _circles = circles;
      });
    } catch (e) {
      print('Error loading circles: $e');
    }
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactStorage.getContacts();
    // Sort contacts alphabetically by name
    contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _contacts = contacts;
      _filterContacts();
    });
    // Reschedule notifications when contacts change
    try {
      await _notificationService.scheduleImportantDateNotifications();
    } catch (e) {
      print('Failed to reschedule notifications: $e');
    }
  }

  void _filterContacts() {
    List<Contact> circleFiltered;
    
    // First filter by circle
    if (_selectedCircle == 'All') {
      circleFiltered = List.from(_contacts);
    } else {
      circleFiltered = _contacts.where((contact) => contact.circle == _selectedCircle).toList();
    }
    
    // Then filter by search query
    if (_searchQuery.isEmpty) {
      _filteredContacts = circleFiltered;
    } else {
      _filteredContacts = circleFiltered.where((contact) {
        final name = contact.name.toLowerCase();
        final phone = contact.phone.toLowerCase();
        final email = contact.email.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               phone.contains(query) || 
               email.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterContacts();
    });
  }

  void _onCircleChanged(String circle) {
    setState(() {
      _selectedCircle = circle;
      _filterContacts();
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedContactIds.clear();
      }
    });
  }

  void _toggleContactSelection(String contactId) {
    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });
  }

  void _selectAllFilteredContacts() {
    setState(() {
      if (_selectedContactIds.length == _filteredContacts.length) {
        // Deselect all if all are selected
        _selectedContactIds.clear();
      } else {
        // Select all filtered contacts
        _selectedContactIds.addAll(_filteredContacts.map((c) => c.id));
      }
    });
  }

  Future<void> _showBulkAssignDialog() async {
    if (_selectedContactIds.isEmpty) return;

    final selectedContacts = _contacts.where((c) => _selectedContactIds.contains(c.id)).toList();
    
    await showDialog(
      context: context,
      builder: (context) => _BulkAssignDialog(
        selectedContacts: selectedContacts,
        availableCircles: _circles,
        onAssignmentComplete: (targetCircle, updatedContacts) async {
          await _handleBulkAssignment(targetCircle, updatedContacts);
        },
      ),
    );
  }

  Future<void> _handleBulkAssignment(Circle targetCircle, List<Contact> updatedContacts) async {
    try {
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(targetCircle.colorValue)),
              SizedBox(height: 16),
              Text('Moving ${updatedContacts.length} contacts to ${targetCircle.name}...'),
            ],
          ),
        ),
      );

      // Update contacts in storage
      final allContacts = await _contactStorage.getContacts();
      
      // Replace the updated contacts in the list
      for (final updatedContact in updatedContacts) {
        final index = allContacts.indexWhere((c) => c.id == updatedContact.id);
        if (index != -1) {
          allContacts[index] = updatedContact;
        }
      }
      
      // Save the updated list
      await _contactStorage.saveContacts(allContacts);

      // Close progress dialog
      Navigator.pop(context);

      // Reload data and exit multi-select mode
      await _loadContacts();
      setState(() {
        _isMultiSelectMode = false;
        _selectedContactIds.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedContacts.length} contacts moved to ${targetCircle.name}'),
            backgroundColor: Color(targetCircle.colorValue),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => _showUndoDialog(updatedContacts, targetCircle),
            ),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if open
      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUndoDialog(List<Contact> changedContacts, Circle targetCircle) async {
    // For simplicity, we'll track the previous circle in a map
    // In a production app, you might want a more robust undo system
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Undo Move'),
        content: Text('This would restore the previous circle assignments. Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
                child: _ContactSelectionList(
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
          circle: 'Friends', // Default circle for imported contacts
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

      // Refresh the contact list
      await _loadContacts();
      
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
        leading: _isMultiSelectMode 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _selectedContactIds.contains(contact.id),
                    onChanged: (selected) => _toggleContactSelection(contact.id),
                    activeColor: Colors.orange,
                  ),
                  SizedBox(width: 8),
                  _imageService.buildContactAvatar(
                    imagePath: contact.imagePath,
                    contactName: contact.name,
                    radius: 20,
                  ),
                ],
              )
            : _imageService.buildContactAvatar(
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
            // Circle badge
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: CircleBadge(circle: contact.circle),
            ),
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
          if (_isMultiSelectMode) {
            _toggleContactSelection(contact.id);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddEditContactScreen(contact: contact),
              ),
            ).then((_) => _loadContacts());
          }
        },
      ),
    );
  }

  Widget _buildCircleFilterButton(String circle) {
    final isSelected = _selectedCircle == circle;
    
    return CircleFilterChip(
      circle: circle,
      isSelected: isSelected,
      onSelected: (selected) => _onCircleChanged(circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode 
            ? Text('${_selectedContactIds.length} selected')
            : Text('All Kindred'),
        backgroundColor: _isMultiSelectMode ? Colors.orange : Colors.teal,
        foregroundColor: Colors.white,
        leading: _isMultiSelectMode 
            ? IconButton(
                onPressed: _toggleMultiSelectMode,
                icon: Icon(Icons.close),
                tooltip: 'Exit selection',
              )
            : null,
        actions: _isMultiSelectMode 
            ? [
                if (_filteredContacts.isNotEmpty)
                  IconButton(
                    onPressed: _selectAllFilteredContacts,
                    icon: Icon(_selectedContactIds.length == _filteredContacts.length 
                        ? Icons.deselect 
                        : Icons.select_all),
                    tooltip: _selectedContactIds.length == _filteredContacts.length 
                        ? 'Deselect all' 
                        : 'Select all',
                  ),
              ]
            : [
                IconButton(
                  onPressed: _toggleMultiSelectMode,
                  icon: Icon(Icons.checklist),
                  tooltip: 'Multi-select',
                ),
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
          : Column(
              children: [
                // Circle filter buttons
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCircleFilterButton('All'),
                      ..._circles.map((circle) => _buildCircleFilterButton(circle.name)),
                    ],
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search kindred...',
                      prefixIcon: Icon(Icons.search, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                
                // Search results info
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredContacts.length} result${_filteredContacts.length == 1 ? '' : 's'} for "${_searchQuery}"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _filterContacts();
                              });
                            },
                            child: Text('Clear', style: TextStyle(color: Colors.teal)),
                          ),
                      ],
                    ),
                  ),
                
                // Contact list
                Expanded(
                  child: _filteredContacts.isEmpty && _searchQuery.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No kindred found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your search',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            return _buildContactCard(_filteredContacts[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _isMultiSelectMode && _selectedContactIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkAssignDialog,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icon(Icons.group_work),
              label: Text('Assign to Circle'),
              heroTag: "bulk_assign",
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: () async {
                    await _showImportContactsDialog();
                  },
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  icon: Icon(Icons.contact_phone),
                  label: Text('Import Contacts'),
                  heroTag: "import", // Required for multiple FABs
                ),
                SizedBox(height: 12),
                FloatingActionButton.extended(
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
                  heroTag: "add", // Required for multiple FABs
                ),
              ],
            ),
    );
  }
}

class _BulkAssignDialog extends StatefulWidget {
  final List<Contact> selectedContacts;
  final List<Circle> availableCircles;
  final Function(Circle, List<Contact>) onAssignmentComplete;

  const _BulkAssignDialog({
    required this.selectedContacts,
    required this.availableCircles,
    required this.onAssignmentComplete,
  });

  @override
  _BulkAssignDialogState createState() => _BulkAssignDialogState();
}

class _BulkAssignDialogState extends State<_BulkAssignDialog> {
  Circle? _selectedCircle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign ${widget.selectedContacts.length} contacts to circle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected contacts:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Container(
            height: 100,
            child: ListView.builder(
              itemCount: widget.selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = widget.selectedContacts[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.circle),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Move to circle:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<Circle>(
            value: _selectedCircle,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select target circle',
            ),
            items: widget.availableCircles.map((circle) {
              return DropdownMenuItem<Circle>(
                value: circle,
                child: Row(
                  children: [
                    Text(circle.emoji),
                    SizedBox(width: 8),
                    Text(circle.name),
                    SizedBox(width: 8),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(circle.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (Circle? value) {
              setState(() {
                _selectedCircle = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCircle == null
              ? null
              : () {
                  // Create updated contacts with new circle
                  final updatedContacts = widget.selectedContacts.map((contact) {
                    return Contact(
                      id: contact.id,
                      name: contact.name,
                      phone: contact.phone,
                      email: contact.email,
                      imagePath: contact.imagePath,
                      circle: _selectedCircle!.name,
                      importantDates: contact.importantDates,
                    );
                  }).toList();

                  Navigator.pop(context);
                  widget.onAssignmentComplete(_selectedCircle!, updatedContacts);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedCircle != null ? Color(_selectedCircle!.colorValue) : null,
          ),
          child: Text('Assign', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ContactSelectionList extends StatefulWidget {
  final List<flutter_contacts.Contact> deviceContacts;
  final Function(List<flutter_contacts.Contact>) onContactsSelected;

  _ContactSelectionList({
    required this.deviceContacts,
    required this.onContactsSelected,
  });

  @override
  _ContactSelectionListState createState() => _ContactSelectionListState();
}

class _ContactSelectionListState extends State<_ContactSelectionList> {
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
