import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class CircleService {
  static const String _circleColorsKey = 'circle_colors';

  Future<Color> getCircleColor(String circle) async {
    final prefs = await SharedPreferences.getInstance();
    final colorsJson = prefs.getString(_circleColorsKey);
    
    if (colorsJson != null) {
      // Parse stored colors
      final Map<String, dynamic> colorsMap = {};
      final pairs = colorsJson.split('|');
      for (final pair in pairs) {
        if (pair.isNotEmpty) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            colorsMap[parts[0]] = int.tryParse(parts[1]);
          }
        }
      }
      
      final colorValue = colorsMap[circle];
      if (colorValue != null) {
        return Color(colorValue);
      }
    }
    
    // Return default color if not customized
    return Color(Circles.getDefaultCircleColor(circle));
  }

  Future<void> setCircleColor(String circle, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final colorsJson = prefs.getString(_circleColorsKey) ?? '';
    
    // Parse existing colors
    final Map<String, int> colorsMap = {};
    final pairs = colorsJson.split('|');
    for (final pair in pairs) {
      if (pair.isNotEmpty) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final colorValue = int.tryParse(parts[1]);
          if (colorValue != null) {
            colorsMap[parts[0]] = colorValue;
          }
        }
      }
    }
    
    // Update the color for this circle
    colorsMap[circle] = color.value;
    
    // Convert back to string format
    final newColorsJson = colorsMap.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
    
    await prefs.setString(_circleColorsKey, newColorsJson);
  }

  Future<Map<String, Color>> getAllCircleColors() async {
    final Map<String, Color> colors = {};
    
    for (final circle in Circles.getAllCircles()) {
      colors[circle] = await getCircleColor(circle);
    }
    
    return colors;
  }

  Future<void> resetCircleColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_circleColorsKey);
  }
}