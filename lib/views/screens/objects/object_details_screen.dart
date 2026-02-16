import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/construction_object.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../tools/tool_details_screen.dart';
import 'add_edit_object_screen.dart';

class ObjectDetailsScreen extends StatefulWidget {
  final ConstructionObject object;
  const ObjectDetailsScreen({super.key, required this.object});

  @override
  State<ObjectDetailsScreen> createState() => _ObjectDetailsScreenState();
}

class _ObjectDetailsScreenState extends State<ObjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final workerProvider = Provider.of<WorkerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final toolsOnObject =
        toolsProvider.tools.where((tool) => tool.currentLocation == widget.object.id).toList();
    final workersOnObject = workerProvider.workers
        .where((worker) => worker.assignedObjectIds.contains(widget.object.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.object.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ReportService.showObjectReportTypeDialog(
                context,
                widget.object,
                toolsOnObject,
                (type) => ReportService.shareObjectReport(
                    widget.object, toolsOnObject, context, type)),
          ),
          if (auth.canControlObjects)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddEditObjectScreen(object: widget.object))),
            ),
          Consumer<ObjectsProvider>(
            builder: (context, op, _) => IconButton(
              icon: Icon(widget.object.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.object.isFavorite ? Colors.red : null),
              onPressed: () => op.toggleFavorite(widget.object.id),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with object image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
            ),
            child: widget.object.displayImage != null
                ? Image(
                    image: widget.object.displayImage!.startsWith('http')
                        ? NetworkImage(widget.object.displayImage!) as ImageProvider
                        : FileImage(File(widget.object.displayImage!)),
                    fit: BoxFit.cover)
                : Center(
                    child:
                        Icon(Icons.location_city, size: 80, color: Colors.grey.shade300),
                  ),
          ),
          // Object info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.object.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (widget.object.description.isNotEmpty)
                  Text(widget.object.description,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.build,
                        label: 'Инструменты',
                        value: toolsOnObject.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.people,
                        label: 'Работники',
                        value: workersOnObject.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.calendar_today,
                        label: 'Дата',
                        value: DateFormat('dd.MM').format(widget.object.createdAt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle, size: 20),
                    const SizedBox(width: 8),
                    Text('Инструменты (${toolsOnObject.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 8),
                    Text('Работники (${workersOnObject.length})'),
                  ],
                ),
              ),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tools tab
                toolsOnObject.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.build,
                        title: 'На объекте нет инструментов',
                        subtitle: 'Переместите инструменты на этот объект',
                      )
                    : ListView.builder(
                        itemCount: toolsOnObject.length,
                        itemBuilder: (context, index) {
                          final tool = toolsOnObject[index];
                          return SelectionToolCard(
                            tool: tool,
                            selectionMode: false,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EnhancedToolDetailsScreen(tool: tool))),
                          );
                        },
                      ),
                // Workers tab
                workersOnObject.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.people,
                        title: 'На объекте нет работников',
                        subtitle: 'Назначьте работников на этот объект',
                      )
                    : ListView.builder(
                        itemCount: workersOnObject.length,
                        itemBuilder: (context, index) {
                          final worker = workersOnObject[index];
                          return _buildWorkerCard(context, worker, workerProvider);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    dynamic worker,
    WorkerProvider workerProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: worker.isFavorite
                  ? [Colors.red.shade400, Colors.red.shade300]
                  : [Colors.blue.shade400, Colors.blue.shade300],
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Text(
              worker.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(worker.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(worker.email,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: worker.role == 'brigadir'
                    ? Colors.purple.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                worker.role == 'brigadir' ? 'Бригадир' : 'Рабочий',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: worker.role == 'brigadir'
                      ? Colors.purple.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            worker.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: worker.isFavorite ? Colors.red : null,
          ),
          onPressed: () => workerProvider.toggleFavorite(worker.id),
        ),
      ),
    );
  }
}
