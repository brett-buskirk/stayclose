
import 'package:flutter/material.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/services/contact_storage.dart';
import 'package:stayclose/services/image_service.dart';
import 'package:stayclose/services/circle_service.dart';
import 'package:uuid/uuid.dart';

class AddEditContactScreen extends StatefulWidget {
  final Contact? contact;

  AddEditContactScreen({this.contact});

  @override
  _AddEditContactScreenState createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContactStorage _contactStorage = ContactStorage();
  final ImageService _imageService = ImageService();
  final CircleService _circleService = CircleService();
  late String _name;
  late String _phone;
  late String _email;
  String? _imagePath;
  String _circle = 'Friends'; // Default circle
  List<ImportantDate> _importantDates = [];
  List<Circle> _circles = [];

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _phone = widget.contact?.phone ?? '';
    _email = widget.contact?.email ?? '';
    _imagePath = widget.contact?.imagePath;
    _circle = widget.contact?.circle ?? 'Friends';
    _importantDates = List.from(widget.contact?.importantDates ?? []);
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      final circles = await _circleService.getAllCircles();
      setState(() {
        _circles = circles;
      });
    } catch (e) {
      print('Error loading circles: $e');
      // Use fallback circles if loading fails
      setState(() {
        _circles = Circles.defaultCircles;
      });
    }
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final contacts = await _contactStorage.getContacts();
      if (widget.contact == null) {
        final newContact = Contact(
          id: Uuid().v4(),
          name: _name,
          phone: _phone,
          email: _email,
          imagePath: _imagePath,
          circle: _circle,
          importantDates: _importantDates,
        );
        contacts.add(newContact);
      } else {
        final index = contacts.indexWhere((c) => c.id == widget.contact!.id);
        if (index != -1) {
          // If image changed, delete the old one
          if (widget.contact!.imagePath != _imagePath && widget.contact!.imagePath != null) {
            await _imageService.deleteImage(widget.contact!.imagePath);
          }
          
          contacts[index] = Contact(
            id: widget.contact!.id,
            name: _name,
            phone: _phone,
            email: _email,
            imagePath: _imagePath,
            circle: _circle,
            importantDates: _importantDates,
          );
        }
      }
      await _contactStorage.saveContacts(contacts);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _addImportantDate() {
    showDialog(
      context: context,
      builder: (context) => _ImportantDateDialog(
        onSave: (name, date) {
          setState(() {
            _importantDates.add(ImportantDate(name: name, date: date));
          });
        },
      ),
    );
  }

  void _editImportantDate(int index) {
    final importantDate = _importantDates[index];
    showDialog(
      context: context,
      builder: (context) => _ImportantDateDialog(
        initialName: importantDate.name,
        initialDate: importantDate.date,
        onSave: (name, date) {
          setState(() {
            _importantDates[index] = ImportantDate(name: name, date: date);
          });
        },
      ),
    );
  }

  void _deleteImportantDate(int index) {
    setState(() {
      _importantDates.removeAt(index);
    });
  }

  void _selectImage() {
    _imageService.showImageSourceDialog(
      context: context,
      onImageSelected: (String? imagePath) {
        if (imagePath != null) {
          setState(() {
            _imagePath = imagePath;
          });
        }
      },
    );
  }

  void _removeImage() async {
    if (_imagePath != null) {
      await _imageService.deleteImage(_imagePath);
      setState(() {
        _imagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Kindred' : 'Edit Kindred'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Section
                Center(
                  child: Column(
                    children: [
                      _imageService.buildLargeContactAvatar(
                        imagePath: _imagePath,
                        contactName: _name,
                        radius: 60,
                        onTap: _selectImage,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _selectImage,
                            icon: Icon(Icons.photo_camera, color: Colors.teal),
                            label: Text('Add Photo'),
                            style: TextButton.styleFrom(foregroundColor: Colors.teal),
                          ),
                          if (_imagePath != null) ...[
                            SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: Icon(Icons.delete, color: Colors.red),
                              label: Text('Remove'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _name,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value!,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: _phone,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _phone = value ?? '',
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: _email,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _email = value ?? '',
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
                          'Circle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _circle,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: _circles.map((circle) {
                            return DropdownMenuItem<String>(
                              value: circle.name,
                              child: Row(
                                children: [
                                  Text(circle.emoji),
                                  SizedBox(width: 8),
                                  Text(circle.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _circle = value ?? 'Friends';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Important Dates',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: _addImportantDate,
                      icon: Icon(Icons.add_circle, color: Colors.teal),
                    ),
                  ],
                ),
                ..._importantDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.event, color: Colors.orange),
                      title: Text(date.name),
                      subtitle: Text(
                        '${date.date.month}/${date.date.day}/${date.date.year}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editImportantDate(index),
                            icon: Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _deleteImportantDate(index),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Save Contact', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportantDateDialog extends StatefulWidget {
  final String? initialName;
  final DateTime? initialDate;
  final Function(String, DateTime) onSave;

  const _ImportantDateDialog({
    this.initialName,
    this.initialDate,
    required this.onSave,
  });

  @override
  _ImportantDateDialogState createState() => _ImportantDateDialogState();
}

class _ImportantDateDialogState extends State<_ImportantDateDialog> {
  late TextEditingController _nameController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Add Important Date' : 'Edit Important Date'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name (e.g., Birthday, Anniversary)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 16),
                  Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(_nameController.text, _selectedDate);
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
