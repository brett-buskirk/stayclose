
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

  static const Map<String, int> defaultCircleColors = {
    'Family': 0xFF4CAF50,    // Green
    'Friends': 0xFF2196F3,   // Blue  
    'Work': 0xFF009688,      // Teal
    'Other': 0xFF9C27B0,     // Purple
  };

  static const List<int> availableColors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFF009688, // Teal
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFFF44336, // Red
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF00BCD4, // Cyan
    0xFF8BC34A, // Light Green
    0xFFFFEB3B, // Yellow
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFFE91E63, // Pink
    0xFFFF5722, // Deep Orange
  ];

  static String getCircleEmoji(String circle) {
    return circleEmojis[circle] ?? '⭐';
  }

  static int getDefaultCircleColor(String circle) {
    return defaultCircleColors[circle] ?? 0xFF009688; // Default to teal
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
