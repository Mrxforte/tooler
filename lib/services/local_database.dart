import 'package:hive_flutter/hive_flutter.dart';
import '../models/tool.dart';
import '../models/construction_object.dart';
import '../models/sync_item.dart';

class LocalDatabase {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';
  static const String appSettingsBox = 'app_settings';

  static Future<void> init() async {
    try {
      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
      await Hive.openBox<String>(appSettingsBox);
      print('Hive boxes opened successfully');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      try {
        await Hive.deleteBoxFromDisk(toolsBox);
        await Hive.deleteBoxFromDisk(objectsBox);
        await Hive.deleteBoxFromDisk(syncQueueBox);
        await Hive.deleteBoxFromDisk(appSettingsBox);

        await Hive.openBox<Tool>(toolsBox);
        await Hive.openBox<ConstructionObject>(objectsBox);
        await Hive.openBox<SyncItem>(syncQueueBox);
        await Hive.openBox<String>(appSettingsBox);
      } catch (e) {
        print('Error recreating boxes: $e');
      }
    }
  }

  static Box<Tool> get tools => Hive.box<Tool>(toolsBox);
  static Box<ConstructionObject> get objects =>
      Hive.box<ConstructionObject>(objectsBox);
  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBox);
  static Box<String> get appSettings => Hive.box<String>(appSettingsBox);

  static Future<void> saveCacheTimestamp() async {
    try {
      await appSettings.put(
        'last_cache_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error saving cache timestamp: $e');
    }
  }

  static Future<DateTime?> getLastCacheUpdate() async {
    try {
      final timestamp = appSettings.get('last_cache_update');
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('Error getting cache timestamp: $e');
      return null;
    }
  }

  static Future<bool> shouldRefreshCache({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final lastUpdate = await getLastCacheUpdate();
      if (lastUpdate == null) return true;
      return DateTime.now().difference(lastUpdate) > maxAge;
    } catch (e) {
      print('Error checking cache refresh: $e');
      return true;
    }
  }
}
