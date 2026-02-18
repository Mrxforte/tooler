// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/construction_object.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../data/services/image_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';

class AddEditObjectScreen extends StatefulWidget {
  final ConstructionObject? object;
  const AddEditObjectScreen({super.key, this.object});
  @override
  _AddEditObjectScreenState createState() => _AddEditObjectScreenState();
}
class _AddEditObjectScreenState extends State<AddEditObjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String? _imageUrl;
  String? _localImagePath;
  @override
  void initState() {
    super.initState();
    if (widget.object != null) {
      _nameController.text = widget.object!.name;
      _descriptionController.text = widget.object!.description;
      _imageUrl = widget.object!.imageUrl;
      _localImagePath = widget.object!.localImagePath;
    }
  }
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    final file = await ImageService.pickImage();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }
  Future<void> _takePhoto() async {
    final file = await ImageService.takePhoto();
    if (file != null) {
      setState(() {
        _imageFile = file;
        _imageUrl = null;
        _localImagePath = null;
      });
    }
  }
  Future<void> _saveObject() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ErrorHandler.showErrorDialog(context, 'Пожалуйста, заполните все обязательные поля');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final object = ConstructionObject(
        id: widget.object?.id ?? IdGenerator.generateObjectId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
        toolIds: widget.object?.toolIds ?? [],
        createdAt: widget.object?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        userId: authProvider.user?.uid ?? 'local',
        isFavorite: widget.object?.isFavorite ?? false,
      );
      if (widget.object == null) {
        await objectsProvider.addObject(object, imageFile: _imageFile);
      } else {
        await objectsProvider.updateObject(object, imageFile: _imageFile);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка сохранения: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.object != null;
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.canControlObjects) {
      return const Scaffold(
          body: Center(child: Text('У вас нет прав на редактирование объектов')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать объект' : 'Добавить объект'),
        actions: [
          if (isEdit && auth.canControlObjects)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Подтверждение удаления'),
                    content: Text('Удалить "${widget.object!.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          final navigator = Navigator.of(context);
                          await Provider.of<ObjectsProvider>(context, listen: false)
                              .deleteObject(widget.object!.id, context: context);
                          await Future.delayed(const Duration(milliseconds: 500));
                          if (context.mounted) {
                            navigator.pop(); // Close screen
                          }
                        },
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _getImageWidget(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Название объекта *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveObject,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEdit ? 'Сохранить изменения' : 'Добавить объект',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
    );
  }
  Widget _getImageWidget() {
    if (_imageFile != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(_imageFile!, fit: BoxFit.cover));
    }
    if (_imageUrl != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(_imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder()));
    }
    if (_localImagePath != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(_localImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder()));
    }
    return _buildPlaceholder();
  }
  Widget _buildPlaceholder() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Добавить фото объекта', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_imageFile != null || _imageUrl != null || _localImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _imageUrl = null;
                    _localImagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
