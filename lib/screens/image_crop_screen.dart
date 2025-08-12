import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class ImageCropScreen extends StatefulWidget {
  final String imagePath;

  const ImageCropScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ImageCropScreenState createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _cropController = CropController();
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageData = bytes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      Navigator.pop(context);
    }
  }

  void _cropImage() {
    _cropController.crop();
  }

  void _cancelCrop() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: _cancelCrop,
        ),
        title: Text(
          'Crop Contact Photo',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _cropImage,
            child: Text(
              'DONE',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    child: Crop(
                      image: _imageData!,
                      controller: _cropController,
                      onCropped: (croppedData) {
                        Navigator.pop(context, croppedData);
                      },
                      aspectRatio: 1.0,
                      baseColor: Colors.black,
                      maskColor: Colors.black.withOpacity(0.7),
                      radius: 8,
                      onMoved: (newRect, oldRect) {},
                      onStatusChanged: (status) {},
                      cornerDotBuilder: (size, edgeAlignment) => Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _cancelCrop,
                        icon: Icon(Icons.close),
                        label: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _cropImage,
                        icon: Icon(Icons.check),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
    );
  }
}