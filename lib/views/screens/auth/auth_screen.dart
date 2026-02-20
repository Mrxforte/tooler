import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../data/services/image_service.dart';
import '../../../core/utils/error_handler.dart';
import 'password_recovery_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminPhraseController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final file = await ImageService.pickImage();
    if (file != null) setState(() => _profileImage = file);
  }

  Future<void> _showForgotPasswordDialog() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      ),
    );
  }

  Future<bool> _checkAccountExists(String email) async {
    try {
      // Try to sign in with a dummy password to check if account exists
      // This will fail but we can determine if account exists from the error
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: 'dummy_password_check',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // user-not-found = account doesn't exist
      // wrong-password = account exists but wrong password
      return e.code != 'user-not-found';
    } catch (e) {
      // If we can't check, assume account doesn't exist
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check password match for signup before starting loading
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      ErrorHandler.showErrorDialog(context, 'Пароли не совпадают');
      return;
    }
    
    if (!mounted) return;
    
    // For registration, check if account already exists
    if (!_isLogin) {
      setState(() => _isLoading = true);
      try {
        final accountExists = await _checkAccountExists(_emailController.text.trim());
        if (!mounted) return;
        
        if (accountExists) {
          setState(() => _isLoading = false);
          _showAccountExistsDialog(_emailController.text.trim());
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ErrorHandler.showErrorDialog(context, 'Ошибка проверки аккаунта: ${e.toString()}');
        }
        return;
      }
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = _isLogin
          ? await authProvider.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim())
          : await authProvider.signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              profileImage: _profileImage,
              adminPhrase: _adminPhraseController.text.trim().isNotEmpty
                  ? _adminPhraseController.text.trim()
                  : null);

      if (!mounted) return;

      if (success) {
        Navigator.popUntil(context, (route) => route.isFirst);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Вход выполнен успешно!' : 'Регистрация прошла успешно!'),
              backgroundColor: Colors.green,
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorDialog(context, ErrorHandler.getFirebaseErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorDialog(context, 'Произошла ошибка: ${e.toString()}');
      }
    }
  }

  void _showAccountExistsDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.orange.shade50,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Аккаунт существует'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Аккаунт с email "$email" уже зарегистрирован в системе.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Что дальше?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Если это ваш аккаунт, перейдите в режим "Вход"',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Если забыли пароль, нажмите "Забыли пароль?"',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Если это не ваш аккаунт, используйте другой email',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLogin = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Перейти в Вход'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Center(
                    child: Column(
                      children: [
                        if (!_isLogin && _profileImage != null)
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: FileImage(_profileImage!),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      size: 15,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: _pickProfileImage,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (!_isLogin)
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt, size: 30, color: Colors.white),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Фото',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build, size: 60, color: Colors.white),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tooler',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Вход в аккаунт' : 'Создать аккаунт',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Введите email' : v!.contains('@') ? null : 'Введите корректный email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            obscureText: _obscurePassword,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Введите пароль' : v!.length >= 6 ? null : 'Минимум 6 символов',
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Подтвердите пароль',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              obscureText: _obscureConfirmPassword,
                              validator: (v) => v != _passwordController.text ? 'Пароли не совпадают' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _adminPhraseController,
                              decoration: InputDecoration(
                                labelText: 'Код администратора (если есть)',
                                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                          if (_isLogin) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: authProvider.rememberMe,
                                  onChanged: (v) => authProvider.setRememberMe(v!),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Запомнить меня', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text('Забыли пароль?'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _isLogin ? 'Войти' : 'Зарегистрироваться',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Toggle Login/Register
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _profileImage = null;
                          _adminPhraseController.clear();
                        });
                      },
                      child: Text(
                        _isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
