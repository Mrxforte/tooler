import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an [XFile] to Firebase Storage. Works on both web and mobile.
  static Future<String?> uploadImage(XFile xfile, String userId) async {
    try {
      // Ensure anonymous auth is active so Storage rules pass
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Use the Firebase Auth UID as the storage folder so rules match
      final authUid =
          FirebaseAuth.instance.currentUser?.uid ?? userId;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(xfile.name)}';
      final ref = _storage.ref().child('images/$authUid/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Use putData on mobile as well for maximum compatibility
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

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

  static Future<XFile?> pickImage({int quality = 85}) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  static Future<XFile?> takePhoto({int quality = 85}) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }
}
