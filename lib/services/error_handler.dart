import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorDialog(BuildContext context, String message) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing error dialog: $e');
    }
  }

  static void showSuccessDialog(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error showing success dialog: $e');
    }
  }

  static void showWarningDialog(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error showing warning dialog: $e');
    }
  }

  static void handleError(Object error, StackTrace stackTrace) {
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
}
