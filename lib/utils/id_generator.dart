import 'dart:math';

class IdGenerator {
  static String generateToolId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'TOOL-$timestamp-$randomNum';
  }

  static String generateObjectId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'OBJ-$timestamp-$randomNum';
  }

  static String generateUniqueId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    final randomStr = List.generate(
      4,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return '$timestamp-$randomStr';
  }
}
