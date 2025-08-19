import 'package:flutter/material.dart';
import 'dart:math';

class DefaultAvatarService {
  static const List<DefaultAvatar> _avatars = [
    // Cute animals
    DefaultAvatar(emoji: '🐱', color: Color(0xFFFFB3E6), name: 'Kitty'),
    DefaultAvatar(emoji: '🐶', color: Color(0xFFFFE4B3), name: 'Puppy'),
    DefaultAvatar(emoji: '🐰', color: Color(0xFFE6E6FA), name: 'Bunny'),
    DefaultAvatar(emoji: '🐻', color: Color(0xFFDEB887), name: 'Bear'),
    DefaultAvatar(emoji: '🐼', color: Color(0xFFF0F0F0), name: 'Panda'),
    DefaultAvatar(emoji: '🐸', color: Color(0xFF98FB98), name: 'Frog'),
    DefaultAvatar(emoji: '🐥', color: Color(0xFFFFFF99), name: 'Chick'),
    DefaultAvatar(emoji: '🐧', color: Color(0xFFB0E0E6), name: 'Penguin'),
    DefaultAvatar(emoji: '🦊', color: Color(0xFFFF7F50), name: 'Fox'),
    DefaultAvatar(emoji: '🐨', color: Color(0xFFD3D3D3), name: 'Koala'),
    
    // Cute objects/nature
    DefaultAvatar(emoji: '🌸', color: Color(0xFFFFB6C1), name: 'Blossom'),
    DefaultAvatar(emoji: '🌟', color: Color(0xFFFFD700), name: 'Star'),
    DefaultAvatar(emoji: '🌈', color: Color(0xFFFF69B4), name: 'Rainbow'),
    DefaultAvatar(emoji: '☀️', color: Color(0xFFFFF8DC), name: 'Sunshine'),
    DefaultAvatar(emoji: '🌙', color: Color(0xFFE6E6FA), name: 'Moon'),
    DefaultAvatar(emoji: '💎', color: Color(0xFFB0E0E6), name: 'Diamond'),
    DefaultAvatar(emoji: '🎈', color: Color(0xFFFF6347), name: 'Balloon'),
    DefaultAvatar(emoji: '🎀', color: Color(0xFFFFB3E6), name: 'Bow'),
    DefaultAvatar(emoji: '🍀', color: Color(0xFF90EE90), name: 'Clover'),
    DefaultAvatar(emoji: '🌺', color: Color(0xFFFF69B4), name: 'Hibiscus'),
    
    // Fun/whimsical
    DefaultAvatar(emoji: '🎭', color: Color(0xFFDDA0DD), name: 'Drama'),
    DefaultAvatar(emoji: '🎨', color: Color(0xFFFFB347), name: 'Art'),
    DefaultAvatar(emoji: '🎪', color: Color(0xFFFF1493), name: 'Circus'),
    DefaultAvatar(emoji: '🎯', color: Color(0xFF32CD32), name: 'Target'),
    DefaultAvatar(emoji: '🎲', color: Color(0xFFFF6347), name: 'Dice'),
    DefaultAvatar(emoji: '🎸', color: Color(0xFFCD853F), name: 'Guitar'),
    DefaultAvatar(emoji: '🎵', color: Color(0xFF9370DB), name: 'Music'),
    DefaultAvatar(emoji: '🎺', color: Color(0xFFDAA520), name: 'Trumpet'),
    DefaultAvatar(emoji: '🎻', color: Color(0xFF8B4513), name: 'Violin'),
    DefaultAvatar(emoji: '🎹', color: Color(0xFF000000), name: 'Piano'),
  ];

  /// Get a random default avatar based on contact name for consistency
  static DefaultAvatar getDefaultAvatar(String contactName) {
    if (contactName.isEmpty) {
      return _avatars[0]; // Fallback to first avatar
    }
    
    // Use name hash to ensure same name always gets same avatar
    final nameHash = contactName.toLowerCase().hashCode;
    final index = nameHash.abs() % _avatars.length;
    return _avatars[index];
  }

  /// Get all available default avatars
  static List<DefaultAvatar> getAllAvatars() {
    return List.unmodifiable(_avatars);
  }

  /// Get a random avatar (truly random, not name-based)
  static DefaultAvatar getRandomAvatar() {
    final random = Random();
    return _avatars[random.nextInt(_avatars.length)];
  }

  /// Check if a path is a default avatar identifier
  static bool isDefaultAvatarPath(String? path) {
    return path != null && path.startsWith('default_avatar:');
  }

  /// Convert default avatar to storage identifier
  static String getDefaultAvatarPath(DefaultAvatar avatar) {
    final index = _avatars.indexOf(avatar);
    return 'default_avatar:$index';
  }

  /// Get default avatar from storage identifier
  static DefaultAvatar? getDefaultAvatarFromPath(String path) {
    if (!isDefaultAvatarPath(path)) return null;
    
    final indexStr = path.replaceFirst('default_avatar:', '');
    final index = int.tryParse(indexStr);
    
    if (index != null && index >= 0 && index < _avatars.length) {
      return _avatars[index];
    }
    
    return null;
  }

  /// Build a default avatar widget
  static Widget buildDefaultAvatarWidget({
    required DefaultAvatar avatar,
    required double radius,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: avatar.color.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: avatar.color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            avatar.emoji,
            style: TextStyle(
              fontSize: radius * 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class DefaultAvatar {
  final String emoji;
  final Color color;
  final String name;

  const DefaultAvatar({
    required this.emoji,
    required this.color,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefaultAvatar &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          color == other.color &&
          name == other.name;

  @override
  int get hashCode => emoji.hashCode ^ color.hashCode ^ name.hashCode;
}