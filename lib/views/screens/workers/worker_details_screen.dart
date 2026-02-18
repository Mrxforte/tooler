// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/bonus_model.dart';
import '../../../data/models/vaxta.dart';
import '../../../data/services/report_service.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/worker_provider.dart';

import 'add_edit_worker_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final Worker worker;

  const WorkerDetailsScreen({super.key, required this.worker});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  late Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
    Provider.of<SalaryProvider>(context, listen: false).loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObjectsProvider>(context, listen: false).loadObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final salaryProvider = Provider.of<SalaryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    
    final salaries = salaryProvider.getSalariesForWorker(_worker.id);
    final advances = salaryProvider.getAdvancesForWorker(_worker.id);
    final penalties = salaryProvider.getPenaltiesForWorker(_worker.id);
    final bonuses = salaryProvider.getBonusesForWorker(_worker.id);
    final attendances = salaryProvider.getAttendancesForWorker(_worker.id);

    final totalSalary = salaries.fold(0.0, (sum, e) => sum + e.amount);
    final totalAdvances = advances.fold(0.0, (sum, e) => sum + (e.repaid ? 0 : e.amount));
    final totalPenalties = penalties.fold(0.0, (sum, e) => sum + e.amount);
    final balance = totalSalary - totalAdvances - totalPenalties;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white24,
                        child: Text(
                          _worker.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _worker.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _worker.role,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Отчет',
                onPressed: () => _showWorkerReportTypeDialog(
                  context,
                  salaries,
                  advances,
                  penalties,
                  bonuses,
                  attendances,
                ),
              ),
              if (auth.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditWorkerScreen(worker: _worker),
                    ),
                  ).then((_) => setState(() {})),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(context),
                  const SizedBox(height: 24),
                  _buildFinancialSection(context, totalSalary, totalAdvances, totalPenalties, balance),
                  const SizedBox(height: 24),
                  _buildWorkDaysSection(context, attendances, objectsProvider),
                  const SizedBox(height: 24),
                  _buildBonusSection(context, bonuses),
                  const SizedBox(height: 24),
                  if (_worker.vaxtas.isNotEmpty) ...[
                    _buildVaxtasSection(context),
                    const SizedBox(height: 24),
                  ],
                  _buildHistoryTabs(context, salaries, advances, penalties),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkerReportTypeDialog(
    BuildContext context,
    List<SalaryEntry> salaries,
    List<Advance> advances,
    List<Penalty> penalties,
    List<BonusEntry> bonuses,
    List<Attendance> attendances,
  ) {
    final outerContext = context;
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Выберите тип отчета', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF отчет'),
              onTap: () {
                Navigator.pop(context);
                ReportService.shareWorkerReport(
                  _worker,
                  salaries,
                  advances,
                  penalties,
                  outerContext,
                  ReportType.pdf,
                  bonuses: bonuses,
                  attendances: attendances,
                  objects: objectsProvider.objects,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('Текстовый отчет'),
              onTap: () {
                Navigator.pop(context);
                ReportService.shareWorkerReport(
                  _worker,
                  salaries,
                  advances,
                  penalties,
                  outerContext,
                  ReportType.text,
                  bonuses: bonuses,
                  attendances: attendances,
                  objects: objectsProvider.objects,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', _worker.email),
            if (_worker.phone != null && _worker.phone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'Телефон', _worker.phone!),
            ],
            if (_worker.nickname != null && _worker.nickname!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person, 'Отчество', _worker.nickname!),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(Icons.payments, 'Почасовая ставка', '${_worker.hourlyRate.toStringAsFixed(2)} ₽'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.today, 'Дневная ставка', '${_worker.dailyRate.toStringAsFixed(2)} ₽'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSection(BuildContext context, double total, double advances, double penalties, double balance) {
    final auth = Provider.of<AuthProvider>(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Финансы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    label: 'Зарплата',
                    value: total.toStringAsFixed(2),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_down,
                    label: 'Авансы',
                    value: advances.toStringAsFixed(2),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.warning,
                    label: 'Штрафы',
                    value: penalties.toStringAsFixed(2),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: balance > 0 && auth.isAdmin ? () => _showPaymentConfirmDialog(context, balance, advances, penalties) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: balance >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого к выплате:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${balance.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (balance > 0 && auth.isAdmin) ...[const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Выплатить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showPaymentConfirmDialog(context, balance, advances, penalties),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentConfirmDialog(BuildContext context, double balance, double advances, double penalties) {
    final deductions = advances + penalties;
    final hasLoan = deductions > balance;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение выплаты'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Работник: ${_worker.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Сумма к выплате:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${balance.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (advances > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Авансы:', style: TextStyle(fontSize: 12)),
                    Text('-${advances.toStringAsFixed(2)} ₽', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ],
              if (penalties > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Штрафы:', style: TextStyle(fontSize: 12)),
                    Text('-${penalties.toStringAsFixed(2)} ₽', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ],
              if (hasLoan) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💳 Авансы и штрафы превышают зарплату',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Долг: ${(deductions - balance).toStringAsFixed(2)} ₽',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Вы уверены что хотите выплатить зарплату?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processPayment(context, balance);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Выплатить'),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, double balance) async {
    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
      
      // Get current financial records
      final salaries = salaryProvider.getSalariesForWorker(_worker.id);
      final attendances = salaryProvider.getAttendancesForWorker(_worker.id);
      final advances = salaryProvider.getAdvancesForWorker(_worker.id);
      final penalties = salaryProvider.getPenaltiesForWorker(_worker.id);
      
      final totalAdvances = advances.fold(0.0, (sum, e) => sum + e.amount);
      final totalPenalties = penalties.fold(0.0, (sum, e) => sum + e.amount);
      final totalDeductions = totalAdvances + totalPenalties;
      
      // Create vaxta record with all payment details
      final vaxta = {
        'id': const Uuid().v4(),
        'workerId': _worker.id,
        'workDays': attendances.map((a) => a.toJson()).toList(),
        'totalPaid': balance,
        'paymentDate': DateTime.now().toIso8601String(),
        'loanAmount': totalDeductions > balance ? totalDeductions - balance : null,
        'loanReason': totalDeductions > balance ? 'Превышение авансов и штрафов над зарплатой' : null,
      };
      
      // Update worker with new vaxta
      final updatedVaxtas = [..._worker.vaxtas, vaxta];
      final updatedWorker = _worker.copyWith(vaxtas: updatedVaxtas);
      
      // Clear all payment-related records
      for (var salary in salaries) {
        await salaryProvider.deleteSalary(salary.id);
      }
      for (var advance in advances) {
        await salaryProvider.deleteAdvance(advance.id);
      }
      for (var penalty in penalties) {
        await salaryProvider.deletePenalty(penalty.id);
      }
      await salaryProvider.clearAttendancesForWorker(_worker.id);
      
      // Update worker
      await workerProvider.updateWorker(updatedWorker);
      
      // Update local worker state
      setState(() {
        _worker = updatedWorker;
      });
      
      // Show success message
      if (context.mounted) {
        String message = '✓ Выплачено ${balance.toStringAsFixed(2)} ₽ работнику ${_worker.name}\n✓ Счетчик обнулен';
        if (totalDeductions > balance) {
          message += '\n💳 Долг: ${(totalDeductions - balance).toStringAsFixed(2)} ₽';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выплате: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWorkDaysSection(
    BuildContext context,
    List<Attendance> attendances,
    ObjectsProvider objectsProvider,
  ) {
    final sorted = List<Attendance>.from(attendances)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Calculate total working days and hours
    double totalDays = 0;
    double totalExtraHours = 0;
    for (final entry in sorted) {
      totalDays += entry.dayFraction > 0 ? entry.dayFraction : (entry.hoursWorked / 10);
      totalExtraHours += entry.extraHours;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Рабочие дни', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Всего: ${totalDays.toStringAsFixed(1)} дн + ${totalExtraHours.toStringAsFixed(0)} ч',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Нет записей о рабочих днях', style: TextStyle(color: Colors.grey))),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sorted.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attendance = entry.value;
                    var objectName = 'Без объекта';
                    if (attendance.objectId != null) {
                      final matches = objectsProvider.objects
                          .where((o) => o.id == attendance.objectId)
                          .toList();
                      objectName = matches.isNotEmpty ? matches.first.name : 'Объект';
                    }
                    final dayType = attendance.dayFraction == 0.5 ? 'Полдня' : 
                                   attendance.dayFraction == 1.0 ? 'Полный день' : 'Часы';
                    final baseDays = attendance.dayFraction > 0
                        ? attendance.dayFraction
                        : (attendance.hoursWorked / 10);
                    final extraHours = attendance.extraHours;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${attendance.date.day.toString().padLeft(2, '0')}.${attendance.date.month.toString().padLeft(2, '0')}.${attendance.date.year}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '✓ Работал',
                                          style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$objectName • $dayType',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  if (baseDays > 0 || extraHours > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${baseDays.toStringAsFixed(1)} дн${extraHours > 0 ? ' + ${extraHours.toStringAsFixed(0)} ч' : ''}',
                                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Добавить запись', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddFullDayDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Полный день'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddHalfDayDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Полдня'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddHoursDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Часы'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusSection(BuildContext context, List<BonusEntry> bonuses) {
    if (bonuses.isEmpty) {
      return const SizedBox.shrink();
    }
    final sorted = List<BonusEntry>.from(bonuses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Бонусы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sorted.take(10).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.amount.toStringAsFixed(2)} ₽ • ${entry.reason}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year} • ${entry.givenBy}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (sorted.length > 10)
              const Text('Показаны последние 10 записей', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildHistoryTabs(BuildContext context, List<SalaryEntry> salaries, List<Advance> advances, List<Penalty> penalties) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Зарплата (${salaries.length})'),
              Tab(text: 'Авансы (${advances.length})'),
              Tab(text: 'Штрафы (${penalties.length})'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
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
    );
  }

  Widget _buildSalaryList(List<SalaryEntry> salaries) {
    if (salaries.isEmpty) {
      return const Center(child: Text('Нет записей о зарплате'));
    }
    return ListView.builder(
      itemCount: salaries.length,
      itemBuilder: (context, index) {
        final entry = salaries[index];
        return ListTile(
          leading: const Icon(Icons.money, color: Colors.green),
          title: Text('${entry.amount.toStringAsFixed(2)} ₽'),
          subtitle: Text('Зарплата'),
          trailing: Text(
            '${entry.date.day}.${entry.date.month}.${entry.date.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildAdvancesList(List<Advance> advances) {
    if (advances.isEmpty) {
      return const Center(child: Text('Нет авансов'));
    }
    return ListView.builder(
      itemCount: advances.length,
      itemBuilder: (context, index) {
        final advance = advances[index];
        return ListTile(
          leading: Icon(
            advance.repaid ? Icons.check_circle : Icons.hourglass_empty,
            color: advance.repaid ? Colors.green : Colors.orange,
          ),
          title: Text('${advance.amount.toStringAsFixed(2)} ₽'),
          subtitle: Text(advance.repaid ? 'Погашено' : 'Не погашено'),
          trailing: Text(
            '${advance.date.day}.${advance.date.month}.${advance.date.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildPenaltiesList(List<Penalty> penalties) {
    if (penalties.isEmpty) {
      return const Center(child: Text('Нет штрафов'));
    }
    return ListView.builder(
      itemCount: penalties.length,
      itemBuilder: (context, index) {
        final penalty = penalties[index];
        return ListTile(
          leading: const Icon(Icons.warning, color: Colors.red),
          title: Text('${penalty.amount.toStringAsFixed(2)} ₽'),
          subtitle: Text(penalty.reason ?? 'Штраф'),
          trailing: Text(
            '${penalty.date.day}.${penalty.date.month}.${penalty.date.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildVaxtasSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'История выплат',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _worker.vaxtas.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final vaxta = _worker.vaxtas[_worker.vaxtas.length - 1 - index]; // Reverse order (newest first)
            final paymentDate = DateTime.parse(vaxta['paymentDate'] as String);
            final totalPaid = vaxta['totalPaid'] as double;
            final loanAmount = vaxta['loanAmount'] as double?;
            final workDays = vaxta['workDays'] as List? ?? [];
            
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Выплата: ${paymentDate.day}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${totalPaid.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дни работы: ${workDays.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (loanAmount != null && loanAmount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '💳 Долг: ${loanAmount.toStringAsFixed(2)} ₽',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddFullDayDialog(BuildContext context) {
    final now = DateTime.now();
    
    // Check if full day already added today
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    final attendances = salaryProvider.getAttendancesForWorker(_worker.id);
    final todayFullDay = attendances.any((a) => 
      _isSameDay(a.date, now) && a.dayFraction == 1.0);
    
    if (todayFullDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Полный день уже добавлен сегодня'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить полный день'),
        content: const Text('Вы добавляете полный рабочий день. Это действие можно выполнить только один раз в день.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addAttendance(1.0);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Да, добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddHalfDayDialog(BuildContext context) {
    final now = DateTime.now();
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    final attendances = salaryProvider.getAttendancesForWorker(_worker.id);
    
    // Count half days today
    final todayHalfDays = attendances.where((a) => 
      _isSameDay(a.date, now) && a.dayFraction == 0.5).length;
    
    if (todayHalfDays >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Максимум 2 полдня в день'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить полдня'),
        content: Text('Вы добавляете полдня (${todayHalfDays + 1}/2 за сегодня).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addAttendance(0.5);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddHoursDialog(BuildContext context) {
    int hours = 1;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить часы'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Количество часов:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => hours = (hours - 1).clamp(1, 12)),
                    child: const Text('-'),
                  ),
                  const SizedBox(width: 24),
                  Text('$hours ч', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => hours = (hours + 1).clamp(1, 12)),
                    child: const Text('+'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _addHours(hours.toDouble());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttendance(double dayFraction) async {
    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
      
      // Get first assigned object or default to first available
      String objectId = _worker.assignedObjectIds.isNotEmpty 
          ? _worker.assignedObjectIds.first 
          : (objectsProvider.objects.isNotEmpty ? objectsProvider.objects.first.id : 'unknown');
      
      final attendance = Attendance(
        id: const Uuid().v4(),
        workerId: _worker.id,
        objectId: objectId,
        date: DateTime.now(),
        dayFraction: dayFraction,
        hoursWorked: 0,
        extraHours: 0,
      );
      
      await salaryProvider.addAttendance(attendance);
      
      setState(() {
        _worker = _worker.copyWith();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Добавлено: ${dayFraction == 1.0 ? 'полный день' : 'полдня'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addHours(double hours) async {
    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
      
      String objectId = _worker.assignedObjectIds.isNotEmpty 
          ? _worker.assignedObjectIds.first 
          : (objectsProvider.objects.isNotEmpty ? objectsProvider.objects.first.id : 'unknown');
      
      final attendance = Attendance(
        id: const Uuid().v4(),
        workerId: _worker.id,
        objectId: objectId,
        date: DateTime.now(),
        dayFraction: 0,
        hoursWorked: hours * 10, // Store as day units (10 hours = 1 day)
        extraHours: hours,
      );
      
      await salaryProvider.addAttendance(attendance);
      
      setState(() {
        _worker = _worker.copyWith();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Добавлено: $hours ч'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
