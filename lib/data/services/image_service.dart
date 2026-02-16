import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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
      final uploadTask = await ref.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
  
  static Future<File?> pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<File?> takePhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      return picked != null ? File(picked.path) : null;
    } catch (e) {
      return null;
    }
  }
}
