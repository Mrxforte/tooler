// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../viewmodels/salary_provider.dart';
import '../../../core/utils/error_handler.dart';

class AdminDailyReportsScreen extends StatelessWidget {
  const AdminDailyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salaryProvider = Provider.of<SalaryProvider>(context);
    final pendingReports = salaryProvider.getPendingDailyReports();

    return Scaffold(
      appBar: AppBar(title: Text('Ежедневные отчеты (${pendingReports.length})')),
      body: pendingReports.isEmpty
          ? const Center(child: Text('Нет отчетов'))
          : ListView.builder(
              itemCount: pendingReports.length,
              itemBuilder: (context, index) {
                final report = pendingReports[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Отчет за ${DateFormat('dd.MM.yyyy').format(report.date)}'),
                    subtitle: Text('Объект: ${report.objectId}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await salaryProvider.updateDailyReportStatus(report.id, 'approved');
                            ErrorHandler.showSuccessDialog(context, 'Отчет одобрен');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await salaryProvider.updateDailyReportStatus(report.id, 'rejected');
                            ErrorHandler.showWarningDialog(context, 'Отчет отклонен');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
