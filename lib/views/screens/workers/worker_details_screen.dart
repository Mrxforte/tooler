// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../viewmodels/auth_provider.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final salaryProvider = Provider.of<SalaryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    
    final salaries = salaryProvider.getSalariesForWorker(_worker.id);
    final advances = salaryProvider.getAdvancesForWorker(_worker.id);
    final penalties = salaryProvider.getPenaltiesForWorker(_worker.id);

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
              title: Text(_worker.name),
              centerTitle: true,
            ),
            actions: [
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
                  _buildHistoryTabs(context, salaries, advances, penalties),
                ],
              ),
            ),
          ),
        ],
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
            Container(
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
        color: color.withOpacity(0.1),
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
}
