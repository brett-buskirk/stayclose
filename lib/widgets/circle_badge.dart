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

  @override
  void initState() {
    super.initState();
    _loadCircleColor();
  }

  @override
  void didUpdateWidget(CircleBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle != widget.circle) {
      _loadCircleColor();
    }
  }

  Future<void> _loadCircleColor() async {
    try {
      final color = await _circleService.getCircleColor(widget.circle);
      if (mounted) {
        setState(() {
          _circleColor = color;
        });
      }
    } catch (e) {
      print('Error loading circle color for ${widget.circle}: $e');
      // Use fallback color
      if (mounted) {
        setState(() {
          _circleColor = Color(Circles.getDefaultCircleColor(widget.circle));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _circleColor ?? Color(Circles.getDefaultCircleColor(widget.circle));
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${Circles.getCircleEmoji(widget.circle)} ${widget.circle}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}