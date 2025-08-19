import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/circle_service.dart';

class CircleBadge extends StatefulWidget {
  final String circle;

  const CircleBadge({
    super.key,
    required this.circle,
  });

  @override
  _CircleBadgeState createState() => _CircleBadgeState();
}

class _CircleBadgeState extends State<CircleBadge> {
  final CircleService _circleService = CircleService();
  Color? _circleColor;
  String? _circleEmoji;

  @override
  void initState() {
    super.initState();
    _loadCircleData();
  }

  @override
  void didUpdateWidget(CircleBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle != widget.circle) {
      _loadCircleData();
    }
  }

  Future<void> _loadCircleData() async {
    try {
      final circles = await _circleService.getAllCircles();
      final circle = circles.firstWhere(
        (c) => c.name == widget.circle,
        orElse: () => Circle(
          id: 'fallback', 
          name: widget.circle, 
          emoji: Circles.getCircleEmoji(widget.circle), 
          colorValue: Circles.getDefaultCircleColor(widget.circle), 
          isDefault: true, 
          order: 999,
        ),
      );
      
      if (mounted) {
        setState(() {
          _circleColor = Color(circle.colorValue);
          _circleEmoji = circle.emoji;
        });
      }
    } catch (e) {
      print('Error loading circle data for ${widget.circle}: $e');
      // Use fallback data
      if (mounted) {
        setState(() {
          _circleColor = Color(Circles.getDefaultCircleColor(widget.circle));
          _circleEmoji = Circles.getCircleEmoji(widget.circle);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _circleColor ?? Color(Circles.getDefaultCircleColor(widget.circle));
    final emoji = _circleEmoji ?? Circles.getCircleEmoji(widget.circle);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji ${widget.circle}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}