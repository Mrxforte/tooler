// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/worker.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/error_handler.dart';

class AddEditWorkerScreen extends StatefulWidget {
  final Worker? worker;
  const AddEditWorkerScreen({super.key, this.worker});

  @override
  State<AddEditWorkerScreen> createState() => _AddEditWorkerScreenState();
}

class _AddEditWorkerScreenState extends State<AddEditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  String _role = 'worker';
  List<String> _selectedObjectIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.name;
      _emailController.text = widget.worker!.email;
      _nicknameController.text = widget.worker!.nickname ?? '';
      _phoneController.text = widget.worker!.phone ?? '';
      _hourlyRateController.text = widget.worker!.hourlyRate.toString();
      _dailyRateController.text = widget.worker!.dailyRate.toString();
      _role = widget.worker!.role;
      _selectedObjectIds = List<String>.from(widget.worker!.assignedObjectIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker == null ? 'Добавить работника' : 'Редактировать работника'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Личная информация'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Имя *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) => v!.isEmpty ? 'Введите email' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Псевдоним',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  helperText: 'Необязательное поле',
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  helperText: 'Необязательное поле',
                ),
              ),
              const SizedBox(height: 24),

              // Role and Permissions Section
              _buildSectionHeader('Роль и должность'),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: 'Роль',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text('🔨 Рабочий')),
                  DropdownMenuItem(value: 'brigadir', child: Text('👨‍💼 Бригадир')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 24),

              // Payment Section
              _buildSectionHeader('Оплата труда'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _hourlyRateController,
                decoration: InputDecoration(
                  labelText: 'Почасовая ставка *',
                  prefixIcon: const Icon(Icons.timer),
                  suffixText: '₽/час',
                  helperText: 'Используется для расчета зарплаты',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Почасовая ставка обязательна для расчета зарплаты';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Почасовая ставка должна быть больше 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _dailyRateController,
                decoration: InputDecoration(
                  labelText: 'Дневная ставка',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixText: '₽/день',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  helperText: 'Необязательное поле',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Object Assignment Section
              _buildSectionHeader('Привязка к объектам'),
              const SizedBox(height: 16),
              
              if (objectsProvider.objects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Нет доступных объектов',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: objectsProvider.objects.map((obj) {
                        final selected = _selectedObjectIds.contains(obj.id);
                        return FilterChip(
                          label: Text(obj.name),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedObjectIds.add(obj.id);
                              } else {
                                _selectedObjectIds.remove(obj.id);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Theme.of(context).colorScheme.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _selectedObjectIds.isEmpty
                            ? '📍 Работник будет размещен в гараже (не привязан к объекту)'
                            : '✓ Выбрано объектов: ${_selectedObjectIds.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveWorker,
                      icon: Icon(widget.worker == null ? Icons.add : Icons.save),
                      label: Text(widget.worker == null ? 'Добавить' : 'Сохранить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _saveWorker() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ErrorHandler.showErrorDialog(context, 'Пожалуйста, заполните все обязательные поля');
      return;
    }

    // Validate hourly rate
    final hourlyRateText = _hourlyRateController.text.trim();
    if (hourlyRateText.isEmpty) {
      _showHourlyRateWarningDialog();
      return;
    }

    final hourlyRate = double.tryParse(hourlyRateText);
    if (hourlyRate == null || hourlyRate <= 0) {
      _showHourlyRateWarningDialog();
      return;
    }

    final worker = Worker(
      id: widget.worker?.id ?? IdGenerator.generateWorkerId(),
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.isNotEmpty ? _nicknameController.text.trim() : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
      assignedObjectIds: List<String>.from(_selectedObjectIds),
      role: _role,
      hourlyRate: hourlyRate,
      dailyRate: double.tryParse(_dailyRateController.text) ?? 0,
    );

    final provider = Provider.of<WorkerProvider>(context, listen: false);
    if (widget.worker == null) {
      await provider.addWorker(worker);
    } else {
      await provider.updateWorker(worker);
    }
    Navigator.pop(context);
  }

  void _showHourlyRateWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Ошибка в почасовой ставке'),
        content: const Text(
          'Почасовая ставка является обязательным полем и используется для расчета зарплаты.\n\n'
          'Пожалуйста, укажите корректную почасовую ставку (больше 0).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}
