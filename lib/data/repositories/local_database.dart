import 'package:hive/hive.dart';
import '../models/tool.dart';
import '../models/construction_object.dart';
import '../models/move_request.dart';
import '../models/notification.dart';
import '../models/worker.dart';
import '../models/salary.dart';
import '../models/attendance.dart';
import '../models/sync_item.dart';

class LocalDatabase {
  static const String toolsBox = 'tools';
  static const String objectsBox = 'objects';
  static const String syncQueueBox = 'sync_queue';
  static const String appSettingsBox = 'app_settings';
  static const String moveRequestsBox = 'move_requests';
  static const String batchMoveRequestsBox = 'batch_move_requests';
  static const String notificationsBox = 'notifications';
  static const String workersBox = 'workers';
  static const String salariesBox = 'salaries';
  static const String advancesBox = 'advances';
  static const String penaltiesBox = 'penalties';
  static const String attendancesBox = 'attendances';
  static const String dailyReportsBox = 'daily_reports';

  static Future<void> init() async {
    try {
      await Hive.openBox<Tool>(toolsBox);
      await Hive.openBox<ConstructionObject>(objectsBox);
      await Hive.openBox<SyncItem>(syncQueueBox);
      await Hive.openBox<String>(appSettingsBox);
      await Hive.openBox<MoveRequest>(moveRequestsBox);
      await Hive.openBox<BatchMoveRequest>(batchMoveRequestsBox);
      await Hive.openBox<AppNotification>(notificationsBox);
      await Hive.openBox<Worker>(workersBox);
      await Hive.openBox<SalaryEntry>(salariesBox);
      await Hive.openBox<Advance>(advancesBox);
      await Hive.openBox<Penalty>(penaltiesBox);
      await Hive.openBox<Attendance>(attendancesBox);
      await Hive.openBox<DailyWorkReport>(dailyReportsBox);
    } catch (e) {
      print('Error opening Hive boxes: $e');
    }
  }

  static Box<Tool> get tools => Hive.box<Tool>(toolsBox);
  static Box<ConstructionObject> get objects => Hive.box<ConstructionObject>(objectsBox);
  static Box<SyncItem> get syncQueue => Hive.box<SyncItem>(syncQueueBox);
  static Box<String> get appSettings => Hive.box<String>(appSettingsBox);
  static Box<MoveRequest> get moveRequests => Hive.box<MoveRequest>(moveRequestsBox);
  static Box<BatchMoveRequest> get batchMoveRequests =>
      Hive.box<BatchMoveRequest>(batchMoveRequestsBox);
  static Box<AppNotification> get notifications => Hive.box<AppNotification>(notificationsBox);
  static Box<Worker> get workers => Hive.box<Worker>(workersBox);
  static Box<SalaryEntry> get salaries => Hive.box<SalaryEntry>(salariesBox);
  static Box<Advance> get advances => Hive.box<Advance>(advancesBox);
  static Box<Penalty> get penalties => Hive.box<Penalty>(penaltiesBox);
  static Box<Attendance> get attendances => Hive.box<Attendance>(attendancesBox);
  static Box<DailyWorkReport> get dailyReports => Hive.box<DailyWorkReport>(dailyReportsBox);

  static Future<void> saveCacheTimestamp() async {
    try {
      await appSettings.put('last_cache_update', DateTime.now().toIso8601String());
    } catch (e) {}
  }
  
  static Future<DateTime?> getLastCacheUpdate() async {
    try {
      final ts = appSettings.get('last_cache_update');
      return ts != null ? DateTime.parse(ts) : null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<bool> shouldRefreshCache({Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final last = await getLastCacheUpdate();
      return last == null || DateTime.now().difference(last) > maxAge;
    } catch (e) {
      return true;
    }
  }
}
