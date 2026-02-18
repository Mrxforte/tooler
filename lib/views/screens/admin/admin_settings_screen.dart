// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/admin_settings_provider.dart';
import '../../../viewmodels/auth_provider.dart';

/// AdminSettingsScreen - UI for managing admin configuration
/// 
/// Features:
/// - View current admin secret word
/// - Change admin secret word
/// - Toggle visibility of secret
/// - Confirmation dialog before saving
/// - Validation feedback

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentSecretController = TextEditingController();
  final _newSecretController = TextEditingController();
  final _confirmSecretController = TextEditingController();
  
  bool _obscureCurrentSecret = true;
  bool _obscureNewSecret = true;
  bool _obscureConfirmSecret = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSecret();
  }

  Future<void> _loadCurrentSecret() async {
    final adminSettings = Provider.of<AdminSettingsProvider>(context, listen: false);
    final currentSecret = await adminSettings.getSecretWord();
    _currentSecretController.text = currentSecret;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _currentSecretController.dispose();
    _newSecretController.dispose();
    _confirmSecretController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSecret() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) {
      return;
    }

    final adminSettings = Provider.of<AdminSettingsProvider>(context, listen: false);
    final success = await adminSettings.updateSecretWord(_newSecretController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Секретное слово успешно обновлено'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear new secret fields
      _newSecretController.clear();
      _confirmSecretController.clear();
      
      // Reload current secret
      await _loadCurrentSecret();
    } else if (mounted) {
      final error = adminSettings.error ?? 'Неизвестная ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите изменение'),
        content: const Text(
          'Вы уверены, что хотите изменить секретное слово администратора?\n\n'
          'После изменения новые администраторы должны будут использовать новое секретное слово при регистрации.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminSettings = Provider.of<AdminSettingsProvider>(context);

    // Security check - only admins can access this screen
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки администратора'),
        ),
        body: const Center(
          child: Text(
            'У вас нет прав доступа к этой странице',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки администратора'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки администратора'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Секретное слово используется при регистрации новых администраторов',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current secret
              Text(
                'Текущее секретное слово',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentSecretController,
                obscureText: _obscureCurrentSecret,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentSecret = !_obscureCurrentSecret;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 32),

              // Change secret section
              Text(
                'Изменить секретное слово',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // New secret
              TextFormField(
                controller: _newSecretController,
                obscureText: _obscureNewSecret,
                decoration: InputDecoration(
                  labelText: 'Новое секретное слово',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewSecret = !_obscureNewSecret;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите новое секретное слово';
                  }
                  if (value.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  if (value == _currentSecretController.text) {
                    return 'Новое секретное слово должно отличаться от текущего';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm new secret
              TextFormField(
                controller: _confirmSecretController,
                obscureText: _obscureConfirmSecret,
                decoration: InputDecoration(
                  labelText: 'Подтвердите новое секретное слово',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmSecret = !_obscureConfirmSecret;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Подтвердите новое секретное слово';
                  }
                  if (value != _newSecretController.text) {
                    return 'Секретные слова не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: adminSettings.isLoading ? null : _handleSaveSecret,
                  icon: adminSettings.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    adminSettings.isLoading
                        ? 'Сохранение...'
                        : 'Сохранить новое секретное слово',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              // Error message
              if (adminSettings.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          adminSettings.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Warning card
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Важно!',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'После изменения секретного слова обязательно сообщите его новым администраторам. '
                              'Существующие администраторы сохранят свои права.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
