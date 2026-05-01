import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(File image, String userId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final ref = _storage.ref().child('users/$userId/images/$fileName');

      final uploadTask = ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Storage upload error: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  static Future<File?> pickImage({int quality = 85}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  static Future<File?> takePhoto({int quality = 85}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }
}
