import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/circle_service.dart';

class CircleFilterChip extends StatefulWidget {
  final String circle;
  final bool isSelected;
  final Function(bool) onSelected;

  const CircleFilterChip({
    super.key,
    required this.circle,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  _CircleFilterChipState createState() => _CircleFilterChipState();
}

class _CircleFilterChipState extends State<CircleFilterChip> {
  final CircleService _circleService = CircleService();
  Color? _circleColor;

  @override
  void initState() {
    super.initState();
    if (widget.circle != 'All') {
      _loadCircleColor();
    }
  }

  @override
  void didUpdateWidget(CircleFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle != widget.circle && widget.circle != 'All') {
      _loadCircleColor();
    }
  }

  Future<void> _loadCircleColor() async {
    final color = await _circleService.getCircleColor(widget.circle);
    if (mounted) {
      setState(() {
        _circleColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.circle == 'All' ? '🌟' : Circles.getCircleEmoji(widget.circle);
    final color = widget.circle == 'All' 
        ? Colors.teal 
        : (_circleColor ?? Color(Circles.getDefaultCircleColor(widget.circle)));
    
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: widget.isSelected,
        onSelected: widget.onSelected,
        label: Text('$emoji ${widget.circle}'),
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: widget.isSelected ? color : Colors.grey[700],
          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}