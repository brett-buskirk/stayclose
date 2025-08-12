
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stayclose/models/contact.dart';

class ContactStorage {
  static const _contactsKey = 'contacts';

  Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null) {
      return [];
    }
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Contact.fromJson(json)).toList();
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = contacts.map((contact) => contact.toJson()).toList();
    await prefs.setString(_contactsKey, jsonEncode(jsonList));
  }
}
