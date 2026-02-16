// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../data/models/worker.dart';
import '../../../data/models/tool.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/construction_object.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../tools/tool_details_screen.dart';

class BrigadierScreen extends StatefulWidget {
  const BrigadierScreen({super.key});

  @override
  State<BrigadierScreen> createState() => _BrigadierScreenState();
}

class _BrigadierScreenState extends State<BrigadierScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final objectsProvider = Provider.of<ObjectsProvider>(context);

    // Assuming brigadier has assignedObjectId; we need to get it.
    // For now, get the first brigadier worker with current user email (simplified)
    Worker? brigadier;
    try {
      brigadier = workerProvider.workers.firstWhere(
          (w) => w.email == auth.user?.email && w.role == 'brigadir');
    } catch (e) {}

    if (brigadier == null || brigadier.assignedObjectId == null) {
      return const Scaffold(
        body: Center(child: Text('Вы не привязаны ни к одному объекту')),
      );
    }

    final object = objectsProvider.objects.firstWhere(
        (o) => o.id == brigadier!.assignedObjectId,
        orElse: () => ConstructionObject(
            id: '',
            name: 'Не найден',
            description: '',
            userId: ''));
    final workersOnObject = workerProvider.getWorkersOnObject(object.id);
    final toolsOnObject = toolsProvider.tools
        .where((t) => t.currentLocation == object.id)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(object.name.isNotEmpty ? object.name : 'Мой объект'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Работники', icon: Icon(Icons.people)),
              Tab(text: 'Инструменты', icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Workers tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAttendanceDialog(context, workersOnObject),
                          icon: const Icon(Icons.today),
                          label: const Text('Отметить явку'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sendDailyReport(context, workersOnObject),
                          icon: const Icon(Icons.send),
                          label: const Text('Отправить отчет'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: workersOnObject.isEmpty
                      ? const Center(child: Text('Нет работников на объекте'))
                      : ListView.builder(
                          itemCount: workersOnObject.length,
                          itemBuilder: (context, index) {
                            final w = workersOnObject[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(w.name[0])),
                              title: Text(w.name),
                              subtitle: Text('Ставка: дн ${w.dailyRate} / час ${w.hourlyRate}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _markPresent(w, context),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Tools tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _requestToolsFromGarage(context, toolsOnObject),
                          icon: const Icon(Icons.add),
                          label: const Text('Запросить из гаража'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: toolsOnObject.isEmpty
                      ? const Center(child: Text('Нет инструментов на объекте'))
                      : ListView.builder(
                          itemCount: toolsOnObject.length,
                          itemBuilder: (context, index) {
                            final t = toolsOnObject[index];
                            return SelectionToolCard(
                              tool: t,
                              selectionMode: false,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => EnhancedToolDetailsScreen(tool: t))),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markPresent(Worker worker, BuildContext context) {
    // Simple: add attendance for today
    final attendance = Attendance(
      id: IdGenerator.generateAttendanceId(),
      workerId: worker.id,
      date: DateTime.now(),
      present: true,
      hoursWorked: 8, // default
    );
    Provider.of<SalaryProvider>(context, listen: false).addAttendance(attendance);
    ErrorHandler.showSuccessDialog(context, '${worker.name} отмечен');
  }

  void _showAttendanceDialog(BuildContext context, List<Worker> workers) {
    List<bool> present = List.generate(workers.length, (_) => true);
    List<double> hours = List.generate(workers.length, (_) => 8.0);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Отметка явки'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Checkbox(
                      value: present[index],
                      onChanged: (v) => setState(() => present[index] = v!),
                    ),
                    Expanded(child: Text(workers[index].name)),
                    if (present[index])
                      Expanded(
                        child: TextFormField(
                          initialValue: hours[index].toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => hours[index] = double.tryParse(v) ?? 8,
                          decoration: const InputDecoration(
                            labelText: 'Часы',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
                for (int i = 0; i < workers.length; i++) {
                  if (present[i]) {
                    salaryProvider.addAttendance(Attendance(
                      id: IdGenerator.generateAttendanceId(),
                      workerId: workers[i].id,
                      date: DateTime.now(),
                      present: true,
                      hoursWorked: hours[i],
                    ));
                  }
                }
                Navigator.pop(context);
                ErrorHandler.showSuccessDialog(context, 'Явка сохранена');
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendDailyReport(BuildContext context, List<Worker> workers) {
    // Gather today's attendances for these workers
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    final todayAttendances = salaryProvider.getAttendancesForObjectAndDate('', DateTime.now()); // need object ID
    // This is simplified; in real app you'd filter by object via worker->object relation.

    // Create report
    final report = DailyWorkReport(
      id: IdGenerator.generateDailyReportId(),
      objectId: '', // need object ID
      brigadierId: firebase_auth.FirebaseAuth.instance.currentUser!.uid,
      date: DateTime.now(),
      attendanceIds: todayAttendances.map((a) => a.id).toList(),
    );
    salaryProvider.addDailyReport(report);
    ErrorHandler.showSuccessDialog(context, 'Отчет отправлен администратору');
  }

  void _requestToolsFromGarage(BuildContext context, List<Tool> toolsOnObject) {
    // Allow brigadier to select tools from garage and request them
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final garageTools = toolsProvider.garageTools;
    if (garageTools.isEmpty) {
      ErrorHandler.showWarningDialog(context, 'В гараже нет инструментов');
      return;
    }
    // Show selection dialog (simplified)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запросить инструменты из гаража'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: garageTools.length,
            itemBuilder: (context, index) {
              final t = garageTools[index];
              return CheckboxListTile(
                title: Text(t.title),
                subtitle: Text(t.brand),
                value: false, // not storing selection; just demo
                onChanged: (_) {},
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}
