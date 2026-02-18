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
          title: Text(widget.worker == null ? 'Добавить работника' : 'Редактировать работника')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Имя *', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email *', prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? 'Введите email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                    labelText: 'Псевдоним', prefixIcon: Icon(Icons.alternate_email)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Телефон', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                    labelText: 'Роль', prefixIcon: Icon(Icons.work)),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text('Рабочий')),
                  DropdownMenuItem(value: 'brigadir', child: Text('Бригадир')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Привязка к объектам',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
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
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedObjectIds.isEmpty
                      ? 'Работник будет в гараже (не привязан)'
                      : 'Выбрано объектов: ${_selectedObjectIds.length}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                    labelText: 'Почасовая ставка', prefixIcon: Icon(Icons.timer)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dailyRateController,
                decoration: const InputDecoration(
                    labelText: 'Дневная ставка', prefixIcon: Icon(Icons.calendar_today)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveWorker,
                child: Text(widget.worker == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWorker() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ErrorHandler.showErrorDialog(context, 'Пожалуйста, заполните все обязательные поля');
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
      hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0,
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
}
