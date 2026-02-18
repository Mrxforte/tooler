import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('❌ Ошибка'),
            content: Text(message),
            backgroundColor: Colors.red.shade50,
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('OK', style: TextStyle(color: Colors.red)))
            ]));
  }
  
  static void showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
  
  static void showWarningDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  static void showInfoDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
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
