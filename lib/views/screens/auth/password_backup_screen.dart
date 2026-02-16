import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/error_handler.dart';

class PasswordBackupScreen extends StatefulWidget {
  final String userEmail;

  const PasswordBackupScreen({super.key, required this.userEmail});

  @override
  State<PasswordBackupScreen> createState() => _PasswordBackupScreenState();
}

class _PasswordBackupScreenState extends State<PasswordBackupScreen> {
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _backupCreated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createBackup() async {
    if (_passwordController.text.isEmpty) {
      ErrorHandler.showWarningDialog(context, 'Введите пароль');
      return;
    }

    final backupContent = '''
═══════════════════════════════════════════════════
             РЕЗЕРВНАЯ КОПИЯ TOOLER
═══════════════════════════════════════════════════

📧 Email: ${widget.userEmail}
🔐 Пароль: ${_passwordController.text}
📅 Дата создания: ${DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now())}

─────────────────────────────────────────────────

⚠️  ВАЖНО! ХРАНИТЕ ЭТОТ ФАЙЛ В БЕЗОПАСНОМ МЕСТЕ!

Инструкции по восстановлению:
1. Перейдите на экран входа в приложение
2. Если забыли пароль, нажмите "Забыли пароль?"
3. Используйте email: ${widget.userEmail}
4. Проверьте вашу почту и последуйте инструкциям
5. Если нужно восстановить пароль из этой копии:
   - Используйте email выше
   - Установите новый пароль при восстановлении

─────────────────────────────────────────────────

🛡️  БЕЗОПАСНОСТЬ:
• Никому не показывайте этот файл
• Храните в защищенном месте
• Не отправляйте по незащищенным каналам
• Удалите файл после восстановления доступа

═══════════════════════════════════════════════════
© Tooler App - Система управления инструментами
═══════════════════════════════════════════════════
    ''';

    try {
      await Share.share(
        backupContent,
        subject: 'Резервная копия Tooler - ${widget.userEmail}',
      );
      setState(() => _backupCreated = true);
      ErrorHandler.showSuccessDialog(context, 'Резервная копия создана и готова к отправке');
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании резервной копии: $e');
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _passwordController.text));
    ErrorHandler.showSuccessDialog(context, 'Пароль скопирован в буфер обмена');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Резервная копия'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildPasswordSection(),
              const SizedBox(height: 24),
              if (_backupCreated) _buildSuccessCard(),
              const SizedBox(height: 24),
              _buildSecurityTipsCard(),
              const SizedBox(height: 24),
              _buildRecoveryInstructionsCard(),
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.backup,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Создать резервную копию',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Сохраните ваши учетные данные в защищенном месте. '
            'Эта копия поможет вам восстановить доступ в случае, если вы забудете пароль.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Введите пароль для резервной копии',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: 'Введите ваш пароль',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('Копировать'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createBackup,
            icon: const Icon(Icons.backup),
            label: const Text('Создать резервную копию'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Резервная копия готова!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Отправьте файл в защищенное место',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Рекомендации безопасности',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSecurityTip('🔒 Никому не показывайте этот файл'),
            _buildSecurityTip('💾 Храните в защищенном облаке (Google Drive, OneDrive)'),
            _buildSecurityTip('🚫 Не отправляйте по незащищенным каналам'),
            _buildSecurityTip('📁 Удалите файл после восстановления доступа'),
            _buildSecurityTip('🔄 Обновляйте копию при смене пароля'),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.6)),
    );
  }

  Widget _buildRecoveryInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Восстановление доступа',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecoveryStep(
              '1',
              'Перейдите на экран входа',
              'Откройте приложение Tooler',
            ),
            _buildRecoveryStep(
              '2',
              'Нажмите "Забыли пароль?"',
              'На экране входа найдите ссылку или кнопку',
            ),
            _buildRecoveryStep(
              '3',
              'Введите ваш email',
              'Email, который вы использовали при регистрации',
            ),
            _buildRecoveryStep(
              '4',
              'Проверьте почту',
              'Переходите по ссылке в письме для сброса пароля',
            ),
            _buildRecoveryStep(
              '5',
              'Установите новый пароль',
              'Из резервной копии используйте старый пароль',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
