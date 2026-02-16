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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Добавить финансовую запись',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Entry type selector with modern cards
                  Column(
                    children: [
                      const Text('Тип записи', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeCard(
                              'Зарплата',
                              Icons.attach_money,
                              Colors.green.shade400,
                              _entryType == 'salary',
                              () => setState(() => _entryType = 'salary'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeCard(
                              'Аванс',
                              Icons.account_balance_wallet,
                              Colors.blue.shade400,
                              _entryType == 'advance',
                              () => setState(() => _entryType = 'advance'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeCard(
                              'Штраф',
                              Icons.warning_rounded,
                              Colors.red.shade400,
                              _entryType == 'penalty',
                              () => setState(() => _entryType = 'penalty'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount field
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Сумма (₽)',
                      prefixIcon: const Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                        ? Colors.grey.shade900 
                        : Colors.grey.shade50,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  // Hours worked (only for salary)
                  if (_entryType == 'salary') ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Количество часов',
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDarkMode 
                          ? Colors.grey.shade900 
                          : Colors.grey.shade50,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => _hoursWorked = double.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Reason/Note field
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: _entryType == 'salary' ? 'Примечание (опционально)' : 'Причина',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                        ? Colors.grey.shade900 
                        : Colors.grey.shade50,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode 
                          ? Colors.grey.shade900 
                          : Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd.MM.yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(_amountController.text) ?? 0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Введите корректную сумму')),
                              );
                              return;
                            }

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
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Добавить'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeCard(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
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
