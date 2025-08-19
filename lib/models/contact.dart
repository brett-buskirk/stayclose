
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

class Circle {
  String id;
  String name;
  String emoji;
  int colorValue;
  bool isDefault;
  int order;

  Circle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.isDefault,
    required this.order,
  });

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      colorValue: json['colorValue'],
      isDefault: json['isDefault'] ?? false,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'order': order,
    };
  }

  Circle copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    bool? isDefault,
    int? order,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      order: order ?? this.order,
    );
  }
}

class Circles {
  static final List<Circle> defaultCircles = [
    Circle(
      id: 'family',
      name: 'Family',
      emoji: '👨‍👩‍👧‍👦',
      colorValue: 0xFF4CAF50, // Green
      isDefault: true,
      order: 0,
    ),
    Circle(
      id: 'friends',
      name: 'Friends',
      emoji: '👥',
      colorValue: 0xFF2196F3, // Blue
      isDefault: true,
      order: 1,
    ),
    Circle(
      id: 'work',
      name: 'Work',
      emoji: '💼',
      colorValue: 0xFF009688, // Teal
      isDefault: true,
      order: 2,
    ),
    Circle(
      id: 'other',
      name: 'Other',
      emoji: '⭐',
      colorValue: 0xFF9C27B0, // Purple
      isDefault: true,
      order: 3,
    ),
  ];

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

  // Legacy methods for backward compatibility
  static String getCircleEmoji(String circleName) {
    final circle = defaultCircles.firstWhere(
      (c) => c.name == circleName,
      orElse: () => defaultCircles[3], // Default to 'Other'
    );
    return circle.emoji;
  }

  static int getDefaultCircleColor(String circleName) {
    final circle = defaultCircles.firstWhere(
      (c) => c.name == circleName,
      orElse: () => defaultCircles[3], // Default to 'Other'
    );
    return circle.colorValue;
  }

  // New method - will be enhanced to include custom circles
  static List<String> getAllCircles() {
    return defaultCircles.map((c) => c.name).toList();
  }

  // Helper methods for finding circles
  static Circle? findByName(String name, List<Circle> allCircles) {
    try {
      return allCircles.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  static Circle? findById(String id, List<Circle> allCircles) {
    try {
      return allCircles.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
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
