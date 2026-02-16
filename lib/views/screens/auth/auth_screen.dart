import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../data/services/image_service.dart';
import '../../../core/utils/error_handler.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  _AuthScreenState createState() => _AuthScreenState();
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
    final TextEditingController emailController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
              labelText: 'Email', hintText: 'Введите ваш email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: emailController.text.trim());
                ErrorHandler.showSuccessDialog(context, 'Письмо для сброса пароля отправлено');
                Navigator.pop(context);
              } catch (e) {
                ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
        throw Exception('Пароли не совпадают');
      }
      final success = _isLogin
          ? await authProvider.signInWithEmail(
              _emailController.text.trim(), _passwordController.text.trim())
          : await authProvider.signUpWithEmail(
              _emailController.text.trim(), _passwordController.text.trim(),
              profileImage: _profileImage,
              adminPhrase: _adminPhraseController.text.trim().isNotEmpty
                  ? _adminPhraseController.text.trim()
                  : null);
      if (!success) return;
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    if (!_isLogin && _profileImage != null)
                      Stack(
                        children: [
                          CircleAvatar(radius: 60, backgroundImage: FileImage(_profileImage!)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, size: 15, color: Colors.white),
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
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 30,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('Фото',
                                  style: TextStyle(
                                      fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.build, size: 60, color: Colors.white),
                      ),
                    const SizedBox(height: 10),
                    Text('Tooler',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 5),
                    const Text('Управление строительными инструментами',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (v) => v != _passwordController.text ? 'Пароли не совпадают' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminPhraseController,
                        decoration: InputDecoration(
                          labelText: 'Код администратора (если есть)',
                          prefixIcon: const Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                    if (_isLogin) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: authProvider.rememberMe,
                            onChanged: (v) => authProvider.setRememberMe(v!),
                          ),
                          const Text('Запомнить меня'),
                        ],
                      ),
                      const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться',
                      style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _profileImage = null;
                    _adminPhraseController.clear();
                  });
                },
                child: Text(_isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
