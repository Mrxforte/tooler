// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/error_handler.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _recoveryEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ErrorHandler.showWarningDialog(context, 'Введите email адрес');
      return;
    }

    if (!email.contains('@')) {
      ErrorHandler.showWarningDialog(context, 'Введите корректный email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send Firebase password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Also send backup email notification
      await _sendBackupEmailNotification(email);
      
      setState(() {
        _emailSent = true;
        _recoveryEmail = email;
      });

      if (mounted) {
        ErrorHandler.showSuccessDialog(
          context,
          'Ссылка восстановления отправлена на $email\n\nПроверьте почту и следуйте инструкциям',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Ошибка отправки письма';
        if (e.code == 'user-not-found') {
          message = 'Пользователь с таким email не найден';
        } else if (e.code == 'invalid-email') {
          message = 'Неверный формат email';
        }
        ErrorHandler.showErrorDialog(context, message);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorDialog(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendBackupEmailNotification(String email) async {
    try {
      // Email sending is handled by Firebase sendPasswordResetEmail
      // To implement custom email notifications, configure Firebase Cloud Functions
      // or set up a backend service like:
      // - SendGrid
      // - Mailgun
      // - Firebase Cloud Functions with nodemailer
      
      debugPrint('Password reset email sent to: $email');
      
      if (!mounted) return;
      // Success feedback already shown in _sendPasswordResetEmail
    } catch (e) {
      debugPrint('Backup email notification error: $e');
      // Silently fail - main email was already sent via Firebase
    }
  }

  void _resetForm() {
    _emailController.clear();
    setState(() {
      _emailSent = false;
      _recoveryEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановление пароля'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_emailSent) ...[
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildRecoveryForm(),
              ] else ...[
                _buildSuccessCard(),
                const SizedBox(height: 24),
                _buildNextStepsCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _resetForm,
                    child: const Text('Восстановить для другого аккаунта'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildSecurityTipsCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_reset,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Забыли пароль?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Мы отправим вам ссылку восстановления на вашу почту',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Введите email вашего аккаунта',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'your-email@example.com',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.email),
            suffixIcon: _emailController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _emailController.clear()),
                  )
                : null,
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _sendPasswordResetEmail,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(
              _isLoading ? 'Отправка...' : 'Отправить ссылку восстановления',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✓ Письмо отправлено',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Проверьте вашу почту: $_recoveryEmail',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Следующие шаги:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStepItem('1', 'Откройте почту', 'Проверьте папку входящих писем'),
          const SizedBox(height: 8),
          _buildStepItem('2', 'Нажмите на ссылку', 'Найдите письмо от Firebase и нажмите на ссылку'),
          const SizedBox(height: 8),
          _buildStepItem('3', 'Создайте новый пароль', 'Придумайте безопасный пароль (минимум 6 символов)'),
          const SizedBox(height: 8),
          _buildStepItem('4', 'Вернитесь в приложение', 'Выполните вход с новым паролем'),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Советы по безопасности',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Не делитесь вашим паролем с кем-либо'),
          _buildTip('Используйте уникальный и сложный пароль'),
          _buildTip('Включите двухфакторную аутентификацию, если доступна'),
          _buildTip('Проверяйте email перед нажатием на ссылки'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 18,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
