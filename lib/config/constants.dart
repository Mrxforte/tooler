class HiveBoxNames {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';
  static const String appSettingsBox = 'app_settings';
}

class AppConstants {
  static const Duration defaultCacheAge = Duration(days: 7);
}

class AuthConstants {
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  static const List<String> adminPermissions = ['read', 'write', 'delete', 'manage_users'];
  static const List<String> userPermissions = ['read', 'write'];
  
  // WARNING: This is for DEMO/DEVELOPMENT purposes only!
  // In production, admin verification MUST be done server-side (Firebase Cloud Functions)
  // Never store admin keys in client code - they can be easily extracted from compiled apps
  // This key should be removed and admin role assignment should require backend validation
  static const String adminSecretKey = 'TOOLER_ADMIN_2024';
}
