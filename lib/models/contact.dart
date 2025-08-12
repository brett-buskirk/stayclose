
class Contact {
  String id;
  String name;
  String phone;
  String email;
  String? imagePath;
  List<ImportantDate> importantDates;

  Contact({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.imagePath,
    this.importantDates = const [],
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imagePath: json['imagePath'],
      importantDates: (json['importantDates'] as List? ?? [])
          .map((e) => ImportantDate.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'imagePath': imagePath,
      'importantDates': importantDates.map((e) => e.toJson()).toList(),
    };
  }
}

class ImportantDate {
  String name;
  DateTime date;

  ImportantDate({
    required this.name,
    required this.date,
  });

  factory ImportantDate.fromJson(Map<String, dynamic> json) {
    return ImportantDate(
      name: json['name'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
    };
  }
}
