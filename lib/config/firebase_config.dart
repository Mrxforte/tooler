import 'package:firebase_core/firebase_core.dart';

/// Firebase Configuration
/// 
/// WARNING: These are placeholder credentials for development.
/// Replace with actual Firebase project credentials before deployment.
/// Keep actual credentials secure and use environment variables for production.
class FirebaseConfig {
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForDevelopment',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'tooler-dev',
    storageBucket: 'tooler-dev.appspot.com',
  );
}
