
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stayclose/models/contact.dart';

class DailyContactScreen extends StatelessWidget {
  final Contact? contact;

  DailyContactScreen({this.contact});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact of the Day'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: contact != null
          ? SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Icon(
                    Icons.today,
                    size: 80,
                    color: Colors.teal,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Today\'s contact is:',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.teal,
                            child: Text(
                              contact!.name.isNotEmpty ? contact!.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            contact!.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          if (contact!.phone.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.phone, color: Colors.teal),
                                SizedBox(width: 12),
                                Expanded(child: Text(contact!.phone, style: TextStyle(fontSize: 16))),
                                IconButton(
                                  onPressed: () => _copyToClipboard(context, contact!.phone, 'Phone number'),
                                  icon: Icon(Icons.copy, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                          ],
                          if (contact!.email.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.teal),
                                SizedBox(width: 12),
                                Expanded(child: Text(contact!.email, style: TextStyle(fontSize: 16))),
                                IconButton(
                                  onPressed: () => _copyToClipboard(context, contact!.email, 'Email'),
                                  icon: Icon(Icons.copy, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                          ],
                          if (contact!.importantDates.isNotEmpty) ...[
                            Divider(),
                            SizedBox(height: 12),
                            Text(
                              'Important Dates',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            ...contact!.importantDates.map<Widget>((date) => Padding(
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
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Why not reach out today?',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (contact!.phone.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Call ${contact!.name}'),
                                content: Text('Would you like to call ${contact!.phone}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _copyToClipboard(context, contact!.phone, 'Phone number');
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
                              title: Text('Text ${contact!.name}'),
                              content: Text('Send a message to stay in touch!'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (contact!.phone.isNotEmpty) {
                                      _copyToClipboard(context, contact!.phone, 'Phone number');
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
                      if (contact!.email.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Email ${contact!.name}'),
                                content: Text('Would you like to email ${contact!.email}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _copyToClipboard(context, contact!.email, 'Email');
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
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No contacts available',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add some contacts to get daily reminders!',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
