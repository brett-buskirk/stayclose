import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';

class CircleService {
  static const String _circleColorsKey = 'circle_colors';
  static const String _customCirclesKey = 'custom_circles';
  static const String _circleOrderKey = 'circle_order';
  static const String _defaultCircleKey = 'default_circle';
  
  final Uuid _uuid = Uuid();

  // === CIRCLE MANAGEMENT ===

  /// Get all circles (default + custom) sorted by order
  Future<List<Circle>> getAllCircles() async {
    final customCircles = await getCustomCircles();
    final allCircles = [...Circles.defaultCircles, ...customCircles];
    
    // Sort by order
    allCircles.sort((a, b) => a.order.compareTo(b.order));
    return allCircles;
  }

  /// Get only custom circles
  Future<List<Circle>> getCustomCircles() async {
    final prefs = await SharedPreferences.getInstance();
    final circlesJson = prefs.getString(_customCirclesKey);
    
    if (circlesJson == null) return [];
    
    try {
      final List<dynamic> circlesList = json.decode(circlesJson);
      return circlesList.map((json) => Circle.fromJson(json)).toList();
    } catch (e) {
      print('Error loading custom circles: $e');
      return [];
    }
  }

  /// Create a new custom circle
  Future<Circle> createCircle({
    required String name,
    required String emoji,
    required Color color,
  }) async {
    // Validate name uniqueness
    final allCircles = await getAllCircles();
    if (allCircles.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('Circle name already exists');
    }

    // Validate name length
    if (name.trim().isEmpty || name.length > 20) {
      throw Exception('Circle name must be 1-20 characters');
    }

    // Create new circle
    final newCircle = Circle(
      id: _uuid.v4(),
      name: name.trim(),
      emoji: emoji,
      colorValue: color.value,
      isDefault: false,
      order: allCircles.length, // Add to end
    );

    // Save to storage
    final customCircles = await getCustomCircles();
    customCircles.add(newCircle);
    await _saveCustomCircles(customCircles);

    return newCircle;
  }

  /// Update an existing circle
  Future<void> updateCircle(Circle updatedCircle) async {
    if (updatedCircle.isDefault) {
      throw Exception('Cannot modify default circles');
    }

    final customCircles = await getCustomCircles();
    final index = customCircles.indexWhere((c) => c.id == updatedCircle.id);
    
    if (index == -1) {
      throw Exception('Circle not found');
    }

    // Validate name uniqueness (excluding current circle)
    final allCircles = await getAllCircles();
    if (allCircles.any((c) => c.id != updatedCircle.id && 
                      c.name.toLowerCase() == updatedCircle.name.toLowerCase())) {
      throw Exception('Circle name already exists');
    }

    customCircles[index] = updatedCircle;
    await _saveCustomCircles(customCircles);
  }

  /// Delete a custom circle
  Future<void> deleteCircle(String circleId, String reassignToCircleId) async {
    final customCircles = await getCustomCircles();
    final circleToDelete = customCircles.firstWhere(
      (c) => c.id == circleId,
      orElse: () => throw Exception('Circle not found'),
    );

    if (circleToDelete.isDefault) {
      throw Exception('Cannot delete default circles');
    }

    // Remove from custom circles
    customCircles.removeWhere((c) => c.id == circleId);
    await _saveCustomCircles(customCircles);

    // Note: Contact reassignment should be handled by the calling code
    // This service only manages circle data
  }

  /// Reorder circles
  Future<void> reorderCircles(List<Circle> reorderedCircles) async {
    // Update order values
    for (int i = 0; i < reorderedCircles.length; i++) {
      reorderedCircles[i] = reorderedCircles[i].copyWith(order: i);
    }

    // Separate default and custom circles
    final customCircles = reorderedCircles.where((c) => !c.isDefault).toList();
    await _saveCustomCircles(customCircles);

    // Note: Default circle order changes would need separate handling
    // For now, we maintain the default order for default circles
  }

  /// Save custom circles to storage
  Future<void> _saveCustomCircles(List<Circle> customCircles) async {
    final prefs = await SharedPreferences.getInstance();
    final circlesJson = json.encode(customCircles.map((c) => c.toJson()).toList());
    await prefs.setString(_customCirclesKey, circlesJson);
  }

  // === COLOR MANAGEMENT (Updated for new Circle model) ===

  /// Get color for a circle by name (maintains backward compatibility)
  Future<Color> getCircleColor(String circleName) async {
    final allCircles = await getAllCircles();
    final circle = Circles.findByName(circleName, allCircles);
    
    if (circle != null) {
      return Color(circle.colorValue);
    }
    
    // Fallback to default color
    return Color(Circles.getDefaultCircleColor(circleName));
  }

  /// Set color for a circle by name (maintains backward compatibility)
  Future<void> setCircleColor(String circleName, Color color) async {
    final allCircles = await getAllCircles();
    final circle = Circles.findByName(circleName, allCircles);
    
    if (circle != null && !circle.isDefault) {
      // Update custom circle
      final updatedCircle = circle.copyWith(colorValue: color.value);
      await updateCircle(updatedCircle);
    } else {
      // Handle default circle color customization (legacy support)
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = prefs.getString(_circleColorsKey) ?? '';
      
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
      
      colorsMap[circleName] = color.value;
      
      final newColorsJson = colorsMap.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join('|');
      
      await prefs.setString(_circleColorsKey, newColorsJson);
    }
  }

  /// Get all circle colors mapped by name
  Future<Map<String, Color>> getAllCircleColors() async {
    final Map<String, Color> colors = {};
    final allCircles = await getAllCircles();
    
    for (final circle in allCircles) {
      colors[circle.name] = await getCircleColor(circle.name);
    }
    
    return colors;
  }

  /// Reset all circle colors to defaults
  Future<void> resetCircleColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_circleColorsKey);
    
    // Reset custom circle colors to their stored values
    // (This maintains the circle's individual color but removes customizations)
  }

  // === DEFAULT CIRCLE MANAGEMENT ===

  /// Get the default circle for new contacts
  Future<String> getDefaultCircle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultCircleKey) ?? 'Friends';
  }

  /// Set the default circle for new contacts
  Future<void> setDefaultCircle(String circleName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCircleKey, circleName);
  }

  // === UTILITY METHODS ===

  /// Validate circle name
  bool isValidCircleName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 20;
  }

  /// Check if circle name is unique
  Future<bool> isCircleNameUnique(String name, {String? excludeId}) async {
    final allCircles = await getAllCircles();
    return !allCircles.any((c) => 
      c.id != excludeId && 
      c.name.toLowerCase() == name.toLowerCase()
    );
  }
}