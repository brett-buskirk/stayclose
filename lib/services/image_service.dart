import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  Future<String?> pickAndCropImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Crop image to square
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 512,
        maxHeight: 512,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Contact Photo',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Contact Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return null;

      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(croppedFile.path);
      return savedPath;
    } catch (e) {
      print('Error picking/cropping image: $e');
      return null;
    }
  }

  Future<String> _saveImageToAppDirectory(String sourcePath) async {
    // Get app directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory contactImagesDir = Directory(path.join(appDir.path, 'contact_images'));
    
    // Create directory if it doesn't exist
    if (!await contactImagesDir.exists()) {
      await contactImagesDir.create(recursive: true);
    }

    // Generate unique filename
    final String fileName = '${_uuid.v4()}.jpg';
    final String targetPath = path.join(contactImagesDir.path, fileName);

    // Copy file to app directory
    final File sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);

    return targetPath;
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> showImageSourceDialog({
    required BuildContext context,
    required Function(String?) onImageSelected,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.teal),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagePath = await pickAndCropImage(
                    context: context,
                    source: ImageSource.gallery,
                  );
                  onImageSelected(imagePath);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.teal),
                title: Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagePath = await pickAndCropImage(
                    context: context,
                    source: ImageSource.camera,
                  );
                  onImageSelected(imagePath);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildContactAvatar({
    String? imagePath,
    required String contactName,
    double radius = 25,
    Color backgroundColor = Colors.teal,
  }) {
    if (imagePath != null && imagePath.isNotEmpty) {
      final File imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(imageFile),
          backgroundColor: backgroundColor,
        );
      }
    }

    // Fallback to initial letter avatar
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }

  Widget buildLargeContactAvatar({
    String? imagePath,
    required String contactName,
    double radius = 50,
    Color backgroundColor = Colors.teal,
    VoidCallback? onTap,
  }) {
    Widget avatar = buildContactAvatar(
      imagePath: imagePath,
      contactName: contactName,
      radius: radius,
      backgroundColor: backgroundColor,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            avatar,
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatar;
  }

  // Clean up orphaned images (images not referenced by any contact)
  Future<void> cleanupUnusedImages(List<String> usedImagePaths) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory contactImagesDir = Directory(path.join(appDir.path, 'contact_images'));
      
      if (!await contactImagesDir.exists()) return;

      final List<FileSystemEntity> files = await contactImagesDir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final String filePath = file.path;
          if (!usedImagePaths.contains(filePath)) {
            await file.delete();
            print('Deleted unused image: $filePath');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up unused images: $e');
    }
  }
}