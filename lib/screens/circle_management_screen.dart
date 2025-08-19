import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/circle_service.dart';
import '../widgets/circle_color_picker.dart';
import 'package:uuid/uuid.dart';

class CircleManagementScreen extends StatefulWidget {
  @override
  _CircleManagementScreenState createState() => _CircleManagementScreenState();
}

class _CircleManagementScreenState extends State<CircleManagementScreen> {
  final CircleService _circleService = CircleService();
  List<Circle> _circles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      final circles = await _circleService.getAllCircles();
      setState(() {
        _circles = circles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateCircleDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _CreateCircleDialog(
        onCircleCreated: (circle) async {
          await _loadCircles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Circle "${circle.name}" created!'),
                backgroundColor: Color(circle.colorValue),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showEditCircleDialog(Circle circle) async {
    if (circle.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default circles cannot be edited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _EditCircleDialog(
        circle: circle,
        onCircleUpdated: () async {
          await _loadCircles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Circle updated!'),
                backgroundColor: Colors.teal,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteCircle(Circle circle) async {
    if (circle.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default circles cannot be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog with reassignment options
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _DeleteCircleDialog(
        circle: circle,
        availableCircles: _circles.where((c) => c.id != circle.id).toList(),
      ),
    );

    if (result != null) {
      try {
        await _circleService.deleteCircle(circle.id, result);
        await _loadCircles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Circle "${circle.name}" deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete circle: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _onReorderCircles(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Circle item = _circles.removeAt(oldIndex);
      _circles.insert(newIndex, item);
    });

    try {
      await _circleService.reorderCircles(_circles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Circle order updated'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      // Revert the UI change if the service call fails
      setState(() {
        final Circle item = _circles.removeAt(newIndex);
        _circles.insert(oldIndex, item);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update circle order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Circles'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showCreateCircleDialog,
            icon: Icon(Icons.add),
            tooltip: 'Create circle',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Your Circles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create custom circles to organize your contacts. Drag and drop to reorder circles.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _circles.length,
                    onReorder: _onReorderCircles,
                    itemBuilder: (context, index) {
                      final circle = _circles[index];
                      return Card(
                        key: ValueKey(circle.id),
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey[400],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(circle.colorValue),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    circle.emoji,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Text(
                                circle.name,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (circle.isDefault) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            circle.isDefault 
                                ? 'Built-in circle (colors can be customized)'
                                : 'Custom circle',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditCircleDialog(circle);
                                  break;
                                case 'delete':
                                  _deleteCircle(circle);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (!circle.isDefault)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  margin: EdgeInsets.all(16),
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
                          '• Create circles that match your relationships (Gaming, Neighbors, etc.)\n'
                          '• Choose unique emojis to quickly identify each circle\n'
                          '• Use distinct colors for better visual organization\n'
                          '• Drag and drop circles to reorder them\n'
                          '• Default circles cannot be deleted but can be customized\n'
                          '• When deleting a circle, all contacts will be reassigned',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCircleDialog,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Create new circle',
      ),
    );
  }
}

class _CreateCircleDialog extends StatefulWidget {
  final Function(Circle) onCircleCreated;

  const _CreateCircleDialog({required this.onCircleCreated});

  @override
  _CreateCircleDialogState createState() => _CreateCircleDialogState();
}

class _CreateCircleDialogState extends State<_CreateCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CircleService _circleService = CircleService();
  
  String _selectedEmoji = '🔵';
  Color _selectedColor = Color(0xFF2196F3);
  bool _isCreating = false;

  final List<String> _popularEmojis = [
    '🔵', '🟢', '🔴', '🟣', '🟡', '🟠',
    '👥', '💼', '🎮', '🏠', '🎓', '💪',
    '🌟', '❤️', '⚡', '🔥', '✨', '🎯',
  ];

  Future<void> _createCircle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final circle = await _circleService.createCircle(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        color: _selectedColor,
      );
      
      widget.onCircleCreated(circle);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Circle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Circle Name',
                hintText: 'e.g., Gaming, Neighbors, College',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a circle name';
                }
                if (value.length > 20) {
                  return 'Name must be 20 characters or less';
                }
                return null;
              },
              maxLength: 20,
            ),
            SizedBox(height: 16),
            Text('Choose Emoji:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularEmojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Circles.availableColors.map((colorValue) {
                final color = Color(colorValue);
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _selectedColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedEmoji, style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Preview',
                    style: TextStyle(
                      color: _selectedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createCircle,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Create'),
        ),
      ],
    );
  }
}

class _EditCircleDialog extends StatefulWidget {
  final Circle circle;
  final VoidCallback onCircleUpdated;

  const _EditCircleDialog({
    required this.circle,
    required this.onCircleUpdated,
  });

  @override
  _EditCircleDialogState createState() => _EditCircleDialogState();
}

class _EditCircleDialogState extends State<_EditCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CircleService _circleService = CircleService();
  
  late String _selectedEmoji;
  late Color _selectedColor;
  bool _isUpdating = false;

  final List<String> _popularEmojis = [
    '🔵', '🟢', '🔴', '🟣', '🟡', '🟠',
    '👥', '💼', '🎮', '🏠', '🎓', '💪',
    '🌟', '❤️', '⚡', '🔥', '✨', '🎯',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.circle.name;
    _selectedEmoji = widget.circle.emoji;
    _selectedColor = Color(widget.circle.colorValue);
  }

  Future<void> _updateCircle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedCircle = widget.circle.copyWith(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        colorValue: _selectedColor.value,
      );
      
      await _circleService.updateCircle(updatedCircle);
      widget.onCircleUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Circle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Circle Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a circle name';
                }
                if (value.length > 20) {
                  return 'Name must be 20 characters or less';
                }
                return null;
              },
              maxLength: 20,
            ),
            SizedBox(height: 16),
            Text('Choose Emoji:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularEmojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Circles.availableColors.map((colorValue) {
                final color = Color(colorValue);
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _selectedColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedEmoji, style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Preview',
                    style: TextStyle(
                      color: _selectedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateCircle,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Update'),
        ),
      ],
    );
  }
}

class _DeleteCircleDialog extends StatefulWidget {
  final Circle circle;
  final List<Circle> availableCircles;

  const _DeleteCircleDialog({
    required this.circle,
    required this.availableCircles,
  });

  @override
  _DeleteCircleDialogState createState() => _DeleteCircleDialogState();
}

class _DeleteCircleDialogState extends State<_DeleteCircleDialog> {
  String? _selectedReassignCircle;

  @override
  void initState() {
    super.initState();
    if (widget.availableCircles.isNotEmpty) {
      _selectedReassignCircle = widget.availableCircles.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete Circle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete "${widget.circle.name}"?'),
          SizedBox(height: 16),
          Text(
            'All contacts in this circle will be moved to:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedReassignCircle,
            isExpanded: true,
            items: widget.availableCircles.map((circle) {
              return DropdownMenuItem(
                value: circle.id,
                child: Row(
                  children: [
                    Text(circle.emoji),
                    SizedBox(width: 8),
                    Text(circle.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedReassignCircle = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReassignCircle != null
              ? () => Navigator.pop(context, _selectedReassignCircle)
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}