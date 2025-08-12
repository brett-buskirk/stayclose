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

      if (pickedFile == null) {
        print('Image picker cancelled by user');
        return null;
      }

      print('Image picked: ${pickedFile.path}');

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

      if (croppedFile == null) {
        print('Image cropping cancelled by user');
        return null;
      }

      print('Image cropped: ${croppedFile.path}');

      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(croppedFile.path);
      print('Image saved to: $savedPath');
      return savedPath;
    } catch (e, stackTrace) {
      print('Error picking/cropping image: $e');
      print('Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<String> _saveImageToAppDirectory(String sourcePath) async {
    try {
      // Get app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory contactImagesDir = Directory(path.join(appDir.path, 'contact_images'));
      
      print('App directory: ${appDir.path}');
      print('Contact images directory: ${contactImagesDir.path}');
      
      // Create directory if it doesn't exist
      if (!await contactImagesDir.exists()) {
        await contactImagesDir.create(recursive: true);
        print('Created contact images directory');
      }

      // Generate unique filename
      final String fileName = '${_uuid.v4()}.jpg';
      final String targetPath = path.join(contactImagesDir.path, fileName);
      
      print('Target path: $targetPath');

      // Copy file to app directory
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }
      
      await sourceFile.copy(targetPath);
      
      // Verify the file was copied
      final File targetFile = File(targetPath);
      if (!await targetFile.exists()) {
        throw Exception('Failed to copy file to target location');
      }
      
      print('Successfully saved image to: $targetPath');
      return targetPath;
    } catch (e, stackTrace) {
      print('Error saving image to app directory: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
      try {
        if (imageFile.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(imageFile),
            backgroundColor: backgroundColor,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
          );
        }
      } catch (e) {
        print('Error checking image file: $e');
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