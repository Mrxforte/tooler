import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification.dart';
import '../../viewmodels/notification_provider.dart';
import '../../views/screens/notifications/notifications_screen.dart';
import 'id_generator.dart';

class ErrorHandler {
  static DateTime? _lastFeedbackAt;
  static int _feedbackBurstCount = 0;
  static DateTime? _lastNotificationsRedirectAt;

  static bool _shouldRedirectToNotifications() {
    final now = DateTime.now();
    if (_lastFeedbackAt == null ||
        now.difference(_lastFeedbackAt!) > const Duration(seconds: 8)) {
      _feedbackBurstCount = 1;
    } else {
      _feedbackBurstCount++;
    }
    _lastFeedbackAt = now;

    final canRedirectAgain =
        _lastNotificationsRedirectAt == null ||
        now.difference(_lastNotificationsRedirectAt!) >
            const Duration(seconds: 5);

    if (_feedbackBurstCount > 2 && canRedirectAgain) {
      _lastNotificationsRedirectAt = now;
      return true;
    }
    return false;
  }

  static Future<void> _pushFeedbackToNotifications(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final notifProvider = context.read<NotificationProvider>();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local';

      await notifProvider.addNotification(
        AppNotification(
          id: IdGenerator.generateNotificationId(),
          title: title,
          body: message,
          type: type,
          userId: userId,
        ),
      );
    } catch (_) {
      // Ignore notification provider errors to avoid blocking UX feedback.
    }
  }

  static void _openNotificationsScreen(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    });
  }

  static void showErrorDialog(BuildContext context, String message) {
    if (_shouldRedirectToNotifications()) {
      _pushFeedbackToNotifications(
        context,
        title: '❌ Ошибка',
        message: message,
        type: 'error',
      );
      _openNotificationsScreen(context);
      return;
    }

    _showSnackBarFeedback(
      context,
      message: message,
      icon: Icons.error,
      color: Colors.red.shade600,
    );
    _showPopupFeedback(
      context,
      title: '❌ Ошибка',
      message: message,
      icon: Icons.error,
      color: Colors.red,
    );
  }

  static void _showSnackBarFeedback(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void _showPopupFeedback(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  static void showSuccessDialog(BuildContext context, String message) {
    if (_shouldRedirectToNotifications()) {
      _pushFeedbackToNotifications(
        context,
        title: '✅ Успешно',
        message: message,
        type: 'success',
      );
      _openNotificationsScreen(context);
      return;
    }

    _showSnackBarFeedback(
      context,
      message: message,
      icon: Icons.check_circle,
      color: Colors.green.shade600,
    );
  }

  static void showWarningDialog(BuildContext context, String message) {
    _showSnackBarFeedback(
      context,
      message: message,
      icon: Icons.warning,
      color: Colors.orange.shade600,
    );
  }

  static void showInfoDialog(BuildContext context, String message) {
    _showSnackBarFeedback(
      context,
      message: message,
      icon: Icons.info,
      color: Colors.blue.shade600,
    );
  }

  static void handleError(Object error, StackTrace stackTrace) {
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stackTrace');
  }

  static String getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный формат email адреса.';
      case 'operation-not-allowed':
        return 'Операция не разрешена. Обратитесь к администратору.';
      case 'weak-password':
        return 'Пароль слишком простой. Используйте минимум 6 символов.';
      case 'user-disabled':
        return 'Этот аккаунт заблокирован.';
      case 'user-not-found':
        return 'Пользователь с таким email не найден.';
      case 'wrong-password':
        return 'Неверный пароль. Попробуйте еще раз.';
      case 'invalid-credential':
        return 'Неверные учетные данные. Проверьте email и пароль.';
      case 'too-many-requests':
        return 'Слишком много попыток входа. Попробуйте позже.';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету.';
      case 'requires-recent-login':
        return 'Требуется повторный вход в систему.';
      case 'invalid-verification-code':
        return 'Неверный код подтверждения.';
      case 'invalid-verification-id':
        return 'Недействительный идентификатор подтверждения.';
      case 'account-exists-with-different-credential':
        return 'Аккаунт с таким email уже существует.';
      case 'credential-already-in-use':
        return 'Эти учетные данные уже используются.';
      case 'timeout':
        return 'Превышено время ожидания. Попробуйте еще раз.';
      default:
        return 'Произошла ошибка: ${e.code}. Попробуйте еще раз.';
    }
  }
}
