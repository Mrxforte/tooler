import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ]));
  }
  
  static void showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2)));
  }
  
  static void showWarningDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2)));
  }
  
  static void handleError(Object error, StackTrace stackTrace) {
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
  
  static String getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный email адрес.';
      case 'operation-not-allowed':
        return 'Операция не разрешена.';
      case 'weak-password':
        return 'Слишком простой пароль.';
      case 'user-disabled':
        return 'Пользователь отключен.';
      case 'user-not-found':
        return 'Пользователь не найден.';
      case 'wrong-password':
        return 'Неверный пароль.';
      default:
        return 'Ошибка: ${e.message}';
    }
  }
}
