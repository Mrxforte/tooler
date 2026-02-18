import 'dart:math';

class IdGenerator {
  static String generateToolId() =>
      'TOOL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  
  static String generateObjectId() =>
      'OBJ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  
  static String generateUniqueId() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final randomStr =
        List.generate(4, (index) => chars[Random().nextInt(chars.length)]).join();
    return '$timestamp-$randomStr';
  }
  
  static String generateRequestId() =>
      'REQ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateBatchRequestId() =>
      'BATCH-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateNotificationId() =>
      'NOT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateWorkerId() =>
      'WRK-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateSalaryId() =>
      'SAL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateAdvanceId() =>
      'ADV-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generatePenaltyId() =>
      'PEN-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateAttendanceId() =>
      'ATT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  
  static String generateDailyReportId() =>
      'DR-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

  static String generateBonusId() =>
      'BON-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
}
