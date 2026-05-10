import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/notification_provider.dart';

/// Static registry so providers can push notifications without a BuildContext.
/// Call [register] once when the user logs in (MainHome.didChangeDependencies).
class NotificationService {
  static NotificationProvider? _provider;

  static void register(NotificationProvider provider) {
    _provider = provider;
  }

  static void unregister() => _provider = null;

  /// Fire-and-forget notification. Uses counter deduplication via [smartAdd].
  static void notify(
    String title,
    String body,
    String type, {
    String? relatedId,
  }) {
    if (_provider == null) return;
    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('user_id') ?? 'local';
      _provider?.smartAdd(
        title: title,
        body: body,
        type: type,
        userId: userId,
        relatedId: relatedId,
      );
    });
  }
}
