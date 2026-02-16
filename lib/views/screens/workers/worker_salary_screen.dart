// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../core/utils/id_generator.dart';

class WorkerSalaryScreen extends StatefulWidget {
  final Worker worker;
  const WorkerSalaryScreen({super.key, required this.worker});

  @override
  State<WorkerSalaryScreen> createState() => _WorkerSalaryScreenState();
}

class _WorkerSalaryScreenState extends State<WorkerSalaryScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _entryType = 'salary'; // salary, advance, penalty
  double _hoursWorked = 0;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Provider.of<SalaryProvider>(context, listen: false).loadData();
  }

  @override
  Widget build(BuildContext context) {
    final salaryProvider = Provider.of<SalaryProvider>(context);

    // Filter by date range
    List<SalaryEntry> salaries = salaryProvider.getSalariesForWorker(widget.worker.id,
        start: _startDate, end: _endDate);
    List<Advance> advances = salaryProvider.getAdvancesForWorker(widget.worker.id,
        start: _startDate, end: _endDate);
    List<Penalty> penalties = salaryProvider.getPenaltiesForWorker(widget.worker.id,
        start: _startDate, end: _endDate);

    double totalSalaries = salaries.fold(0, (total, e) => total + e.amount);
    double totalAdvances = advances.fold(0, (total, e) => total + (e.repaid ? 0 : e.amount));
    double totalPenalties = penalties.fold(0, (total, e) => total + e.amount);
    double balance = totalSalaries - totalAdvances - totalPenalties;

    return Scaffold(
      appBar: AppBar(
        title: Text('Зарплата: ${widget.worker.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEntryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => ReportService.shareWorkerReport(
                widget.worker, salaries, advances, penalties, context, ReportType.pdf,
                startDate: _startDate, endDate: _endDate),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_startDate != null || _endDate != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Период: ${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'начало'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'конец'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  ),
                ],
              ),
            ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Начислено:', style: TextStyle(fontSize: 16)),
                      Text('${totalSalaries.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Авансы:', style: TextStyle(fontSize: 16)),
                      Text('${totalAdvances.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Штрафы:', style: TextStyle(fontSize: 16)),
                      Text('${totalPenalties.toStringAsFixed(2)} ₽',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Баланс:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${balance.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Зарплата'),
                      Tab(text: 'Авансы'),
                      Tab(text: 'Штрафы'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSalaryList(salaries),
                        _buildAdvancesList(advances),
                        _buildPenaltiesList(penalties),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryList(List<SalaryEntry> salaries) {
    return salaries.isEmpty
        ? const Center(child: Text('Нет записей'))
        : ListView.builder(
            itemCount: salaries.length,
            itemBuilder: (context, index) {
              final s = salaries[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(s.date)} — ${s.amount} ₽'),
                subtitle: Text(
                    'Часов: ${s.hoursWorked}${s.notes != null ? ' · ${s.notes}' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deleteSalary(s.id),
                ),
              );
            },
          );
  }

  Widget _buildAdvancesList(List<Advance> advances) {
    return advances.isEmpty
        ? const Center(child: Text('Нет авансов'))
        : ListView.builder(
            itemCount: advances.length,
            itemBuilder: (context, index) {
              final a = advances[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(a.date)} — ${a.amount} ₽'),
                subtitle: Text('${a.reason ?? 'Без причины'}${a.repaid ? ' (Погашен)' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deleteAdvance(a.id),
                ),
              );
            },
          );
  }

  Widget _buildPenaltiesList(List<Penalty> penalties) {
    return penalties.isEmpty
        ? const Center(child: Text('Нет штрафов'))
        : ListView.builder(
            itemCount: penalties.length,
            itemBuilder: (context, index) {
              final p = penalties[index];
              return ListTile(
                title: Text('${DateFormat('dd.MM.yyyy').format(p.date)} — ${p.amount} ₽'),
                subtitle: Text(p.reason ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      Provider.of<SalaryProvider>(context, listen: false).deletePenalty(p.id),
                ),
              );
            },
          );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить запись'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _entryType,
                  items: const [
                    DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                    DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                    DropdownMenuItem(value: 'penalty', child: Text('Штраф')),
                  ],
                  onChanged: (v) => setState(() => _entryType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Сумма'),
                  keyboardType: TextInputType.number,
                ),
                if (_entryType == 'salary') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Количество часов'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _hoursWorked = double.tryParse(v) ?? 0,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                      labelText: _entryType == 'salary' ? 'Примечание' : 'Причина'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Дата: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 0;
                if (amount <= 0) return;

                final salaryProvider =
                    Provider.of<SalaryProvider>(context, listen: false);

                if (_entryType == 'salary') {
                  await salaryProvider.addSalary(SalaryEntry(
                    id: IdGenerator.generateSalaryId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    hoursWorked: _hoursWorked,
                    amount: amount,
                    notes: _reasonController.text,
                  ));
                } else if (_entryType == 'advance') {
                  await salaryProvider.addAdvance(Advance(
                    id: IdGenerator.generateAdvanceId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    amount: amount,
                    reason: _reasonController.text,
                  ));
                } else if (_entryType == 'penalty') {
                  await salaryProvider.addPenalty(Penalty(
                    id: IdGenerator.generatePenaltyId(),
                    workerId: widget.worker.id,
                    date: _selectedDate,
                    amount: amount,
                    reason: _reasonController.text,
                  ));
                }

                _amountController.clear();
                _reasonController.clear();
                _hoursWorked = 0;
                Navigator.pop(context);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
