
import 'package:flutter/material.dart';
import 'package:stayclose/models/contact.dart';
import 'package:stayclose/services/contact_storage.dart';
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
  late String _name;
  late String _phone;
  late String _email;
  List<ImportantDate> _importantDates = [];

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _phone = widget.contact?.phone ?? '';
    _email = widget.contact?.email ?? '';
    _importantDates = List.from(widget.contact?.importantDates ?? []);
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
          importantDates: _importantDates,
        );
        contacts.add(newContact);
      } else {
        final index = contacts.indexWhere((c) => c.id == widget.contact!.id);
        if (index != -1) {
          contacts[index] = Contact(
            id: widget.contact!.id,
            name: _name,
            phone: _phone,
            email: _email,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
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
                        '${date.date.day}/${date.date.month}/${date.date.year}',
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
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
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
