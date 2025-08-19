import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/circle_service.dart';
import '../widgets/circle_color_picker.dart';

class CircleColorsScreen extends StatefulWidget {
  @override
  _CircleColorsScreenState createState() => _CircleColorsScreenState();
}

class _CircleColorsScreenState extends State<CircleColorsScreen> {
  final CircleService _circleService = CircleService();
  Map<String, Color> _circleColors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCircleColors();
  }

  Future<void> _loadCircleColors() async {
    try {
      final colors = await _circleService.getAllCircleColors();
      setState(() {
        _circleColors = colors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circle colors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showColorPicker(String circle) async {
    final currentColor = _circleColors[circle] ?? Color(Circles.getDefaultCircleColor(circle));
    
    showDialog(
      context: context,
      builder: (context) => CircleColorPicker(
        currentColor: currentColor,
        circleName: circle,
        onColorSelected: (color) async {
          try {
            await _circleService.setCircleColor(circle, color);
            setState(() {
              _circleColors[circle] = color;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${circle} color updated!'),
                  backgroundColor: color,
                ),
              );
            }
          } catch (e) {
            print('Error saving circle color: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update color'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _resetColors() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Colors'),
        content: Text('Are you sure you want to reset all circle colors to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _circleService.resetCircleColors();
                Navigator.pop(context);
                await _loadCircleColors();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Circle colors reset to defaults'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reset colors'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Circle Colors'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _resetColors,
            icon: Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Circle Colors',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap any circle to change its color. These colors will be used throughout the app for badges, filters, and organization.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ...Circles.getAllCircles().map((circle) {
                  final color = _circleColors[circle] ?? Color(Circles.getDefaultCircleColor(circle));
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.palette,
                          color: _getContrastColor(color),
                        ),
                      ),
                      title: Text(
                        '${Circles.getCircleEmoji(circle)} $circle',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Tap to change color'),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          circle,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => _showColorPicker(circle),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• Colors help you quickly identify different types of contacts\n'
                          '• Choose colors that have good contrast for readability\n'
                          '• Colors will be applied to contact badges and filter chips\n'
                          '• Changes take effect immediately throughout the app',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}