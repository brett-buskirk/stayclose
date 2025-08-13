
class Contact {
  String id;
  String name;
  String phone;
  String email;
  String? imagePath;
  String circle;
  List<ImportantDate> importantDates;

  Contact({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.imagePath,
    this.circle = 'Friends',
    this.importantDates = const [],
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imagePath: json['imagePath'],
      circle: json['circle'] ?? 'Friends', // Default for existing contacts
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
      'circle': circle,
      'importantDates': importantDates.map((e) => e.toJson()).toList(),
    };
  }
}

class Circles {
  static const List<String> defaultCircles = [
    'Family',
    'Friends', 
    'Work',
    'Other',
  ];

  static const Map<String, String> circleEmojis = {
    'Family': '👨‍👩‍👧‍👦',
    'Friends': '👥',
    'Work': '💼',
    'Other': '⭐',
  };

  static String getCircleEmoji(String circle) {
    return circleEmojis[circle] ?? '⭐';
  }

  static List<String> getAllCircles() {
    // This will be enhanced later to include user-defined circles
    return List.from(defaultCircles);
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
