
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stayclose/models/contact.dart';

class DailyContactService {
  static const String _lastContactDateKey = 'last_contact_date';
  static const String _lastContactIdKey = 'last_contact_id';
  
  Future<Contact?> selectDailyContact(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      return null;
    }

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final prefs = await SharedPreferences.getInstance();
    final lastContactDate = prefs.getString(_lastContactDateKey);
    final lastContactId = prefs.getString(_lastContactIdKey);

    // If we've already selected a contact for today, return the same one
    if (lastContactDate == todayString && lastContactId != null) {
      final existingContact = contacts.firstWhere(
        (contact) => contact.id == lastContactId,
        orElse: () => _selectNewDailyContact(contacts, lastContactId),
      );
      return existingContact;
    }

    // Select a new contact for today
    final selectedContact = _selectNewDailyContact(contacts, lastContactId);
    
    // Save the selection
    await prefs.setString(_lastContactDateKey, todayString);
    await prefs.setString(_lastContactIdKey, selectedContact.id);
    
    return selectedContact;
  }

  Contact _selectNewDailyContact(List<Contact> contacts, String? excludeId) {
    // Try to avoid selecting the same person as yesterday
    List<Contact> availableContacts = contacts;
    if (excludeId != null && contacts.length > 1) {
      availableContacts = contacts.where((c) => c.id != excludeId).toList();
    }
    
    if (availableContacts.isEmpty) {
      availableContacts = contacts;
    }

    // Give preference to contacts with upcoming important dates
    final now = DateTime.now();
    final contactsWithUpcomingDates = availableContacts.where((contact) {
      return contact.importantDates.any((date) {
        final thisYear = DateTime(now.year, date.date.month, date.date.day);
        final nextYear = DateTime(now.year + 1, date.date.month, date.date.day);
        
        return (thisYear.isAfter(now) && thisYear.difference(now).inDays <= 7) ||
               (thisYear.isBefore(now) && nextYear.difference(now).inDays <= 7);
      });
    }).toList();

    // 30% chance to select someone with an upcoming important date
    final random = Random();
    if (contactsWithUpcomingDates.isNotEmpty && random.nextDouble() < 0.3) {
      return contactsWithUpcomingDates[random.nextInt(contactsWithUpcomingDates.length)];
    }

    // Otherwise select randomly from all available contacts
    return availableContacts[random.nextInt(availableContacts.length)];
  }

  Future<void> resetDailyContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastContactDateKey);
    await prefs.remove(_lastContactIdKey);
  }
}
