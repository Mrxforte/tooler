// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/services/report_service.dart';
import 'add_edit_tool_screen.dart';

class EnhancedToolDetailsScreen extends StatefulWidget {
  final Tool tool;
  const EnhancedToolDetailsScreen({super.key, required this.tool});

  @override
  State<EnhancedToolDetailsScreen> createState() =>
      _EnhancedToolDetailsScreenState();
}

class _EnhancedToolDetailsScreenState extends State<EnhancedToolDetailsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final toolsProvider = Provider.of<ToolsProvider>(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => toolsProvider.loadTools(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'tool-${tool.id}',
                  child: tool.displayImage != null
                      ? Image(
                          image: tool.displayImage!.startsWith('http')
                              ? NetworkImage(tool.displayImage!)
                                    as ImageProvider
                              : FileImage(File(tool.displayImage!)),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildToolImagePlaceholder(theme),
                        )
                      : _buildToolImagePlaceholder(theme),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                  tooltip: 'Создать отчет',
                  onPressed: () => _showReportDialog(context, tool),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Поделиться',
                  onPressed: () => _showShareDialog(context, tool),
                ),
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Печать',
                  onPressed: () => _printReport(context, tool),
                ),
                PopupMenuButton(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        if (auth.isAdmin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditToolScreen(tool: tool),
                            ),
                          );
                        }
                        break;
                      case 'delete':
                        if (auth.isAdmin) {
                          _showDeleteConfirmation(context);
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuItem> items = [];
                    if (auth.isAdmin) {
                      items.add(
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Редактировать'),
                        ),
                      );
                    }
                    if (auth.isAdmin) {
                      items.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tool.currentLocationName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Consumer<ToolsProvider>(
                          builder: (context, tp, _) {
                            final updatedTool = tp.tools.firstWhere(
                              (t) => t.id == tool.id,
                              orElse: () => tool,
                            );
                            return IconButton(
                              icon: Icon(
                                updatedTool.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: updatedTool.isFavorite
                                    ? Colors.red
                                    : null,
                                size: 30,
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                tp.toggleFavorite(tool.id);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tool.brand,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          tool.uniqueId,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (tool.description.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.02,
                                ),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isDescriptionExpanded =
                                        !_isDescriptionExpanded;
                                  });
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        color: theme.colorScheme.primary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Описание',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        _isDescriptionExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      tool.description,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Colors.grey[800],
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                crossFadeState: _isDescriptionExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildDetailCard(
                          icon: Icons.location_on,
                          title: 'Местоположение',
                          value: tool.currentLocationName,
                          color: Colors.blue,
                        ),
                        _buildDetailCard(
                          icon: Icons.calendar_today,
                          title: 'Добавлен',
                          value: DateFormat(
                            'dd.MM.yyyy',
                          ).format(tool.createdAt),
                          color: Colors.green,
                        ),
                        _buildDetailCard(
                          icon: Icons.update,
                          title: 'Обновлен',
                          value: DateFormat(
                            'dd.MM.yyyy',
                          ).format(tool.updatedAt),
                          color: Colors.orange,
                        ),
                        _buildDetailCard(
                          icon: Icons.favorite,
                          title: 'Статус',
                          value: tool.isFavorite ? 'Избранный' : 'Обычный',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (tool.locationHistory.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'История перемещений',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...tool.locationHistory.map(
                                (history) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              history.locationName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat(
                                                'dd.MM.yyyy HH:mm',
                                              ).format(history.date),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Consumer2<ToolsProvider, AuthProvider>(
            builder: (context, tp, auth, _) => ElevatedButton.icon(
              onPressed: () => _showMoveDialog(context, tool, auth),
              icon: const Icon(Icons.move_to_inbox),
              label: Text(
                auth.canMoveTools
                    ? 'Переместить инструмент'
                    : 'Запросить перемещение',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolImagePlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.secondary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.build,
          size: 100,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
  void _showDeleteConfirmation(BuildContext context) {
    final outerContext = context;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) {
      ErrorHandler.showErrorDialog(
        context,
        'Только администратор может удалять',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить "${widget.tool.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Provider.of<ToolsProvider>(
                outerContext,
                listen: false,
              ).deleteTool(widget.tool.id, context: outerContext);
              if (!outerContext.mounted) return;
              await Future.delayed(const Duration(milliseconds: 2000));
              if (outerContext.mounted) {
                Navigator.pop(outerContext);
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Tool tool, AuthProvider auth) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    String? selectedId = tool.currentLocation;
    String? selectedName = tool.currentLocationName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              bottom: true,
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            auth.canMoveTools
                                ? 'Переместить инструмент'
                                : 'Запросить перемещение',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.garage,
                                  color: Colors.blue,
                                ),
                                title: const Text('Гараж'),
                                trailing: selectedId == 'garage'
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedId = 'garage';
                                    selectedName = 'Гараж';
                                  });
                                },
                              ),
                              const Divider(),
                              ...objectsProvider.objects.map(
                                (obj) {
                                  // Calculate updated count after move
                                  final isToolCurrentlyHere = tool.currentLocation == obj.id;
                                  final updatedCount = isToolCurrentlyHere
                                      ? obj.toolIds.length - 1  // Removing tool from this object
                                      : obj.toolIds.length + 1; // Adding tool to this object
                                  
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.location_city,
                                      color: Colors.orange,
                                    ),
                                    title: Text(obj.name),
                                    subtitle: Text(
                                      selectedId == obj.id && selectedId != tool.currentLocation
                                          ? 'Инструментов: ${obj.toolIds.length} → ${updatedCount.clamp(0, updatedCount)}'
                                          : 'Инструментов: ${obj.toolIds.length}',
                                    ),
                                    trailing: selectedId == obj.id
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        selectedId = obj.id;
                                        selectedName = obj.name;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Отмена'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (selectedId != null &&
                                        selectedName != null &&
                                        selectedId != tool.currentLocation) {
                                      if (auth.canMoveTools) {
                                        await toolsProvider.moveTool(
                                          tool.id,
                                          selectedId!,
                                          selectedName!,
                                        );
                                      } else {
                                        await toolsProvider.requestMoveTool(
                                          tool.id,
                                          selectedId!,
                                          selectedName!,
                                        );
                                      }
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text(
                                    auth.canMoveTools
                                        ? 'Переместить'
                                        : 'Отправить запрос',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, Tool tool) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите формат отчета',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('PDF отчет'),
                  subtitle: const Text('Красиво оформленный отчет'),
                  onTap: () {
                    Navigator.pop(context);
                    _generateAndShareReport(context, tool, ReportType.pdf);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.text_fields, color: Colors.blue),
                  title: const Text('Текстовый отчет'),
                  subtitle: const Text('Простой текстовый формат'),
                  onTap: () {
                    Navigator.pop(context);
                    _generateAndShareReport(context, tool, ReportType.text);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareDialog(BuildContext context, Tool tool) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Поделиться отчетом',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Поделиться PDF'),
                  subtitle: const Text('PDF отчет через мессенджеры'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareReport(context, tool, ReportType.pdf);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.text_fields, color: Colors.blue),
                  title: const Text('Поделиться текстом'),
                  subtitle: const Text('Текстовый отчет'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareReport(context, tool, ReportType.text);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShareReport(
    BuildContext context,
    Tool tool,
    ReportType reportType,
  ) async {
    if (!context.mounted) return;

    try {
      // Show progress dialog with proper context handling
      final dialogContext = context;
      bool dialogShown = false;

      showDialog(
        context: context,
        barrierDismissible: true, // Allow back button to dismiss
        builder: (dialogCtx) {
          dialogShown = true;
          return PopScope(
            canPop: true, // Allow back button
            onPopInvoked: (didPop) {
              if (didPop) {
                // User pressed back button
              }
            },
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    reportType == ReportType.pdf
                        ? 'Создание PDF отчета...'
                        : 'Создание текстового отчета...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Generate and share the report
      await ReportService.shareToolReport(
        tool,
        dialogContext,
        reportType,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло. Повторите попытку.');
        },
      );

      // Close progress dialog if it's still showing
      if (dialogShown && dialogContext.mounted) {
        try {
          Navigator.of(dialogContext).pop();
        } catch (e) {
          // Dialog might already be closed
        }
      }

      // Show success message
      if (dialogContext.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (dialogContext.mounted) {
            ErrorHandler.showSuccessDialog(
              dialogContext,
              reportType == ReportType.pdf
                  ? 'PDF отчет готов!'
                  : 'Текстовый отчет готов!',
            );
          }
        });
      }
    } catch (e) {
      // Handle error while preserving context
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ErrorHandler.showErrorDialog(
              context,
              'Ошибка при создании отчета: $e',
            );
          }
        });
      }
    }
  }

  Future<void> _shareReport(
    BuildContext context,
    Tool tool,
    ReportType reportType,
  ) async {
    if (!context.mounted) return;

    try {
      final dialogContext = context;
      bool dialogShown = false;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: true, // Allow back button
        builder: (dialogCtx) {
          dialogShown = true;
          return PopScope(
            canPop: true, // Allow back button
            onPopInvoked: (didPop) {
              if (didPop) {
                // User pressed back button
              }
            },
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Подготовка к отправке...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await ReportService.shareToolReport(
        tool,
        dialogContext,
        reportType,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло. Повторите попытку.');
        },
      );

      // Close progress dialog safely
      if (dialogShown && dialogContext.mounted) {
        try {
          Navigator.of(dialogContext).pop();
        } catch (e) {
          // Dialog might already be closed
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Try to close any open dialogs
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ErrorHandler.showErrorDialog(
              context,
              'Ошибка при отправке отчета: $e',
            );
          }
        });
      }
    }
  }

  Future<void> _printReport(BuildContext context, Tool tool) async {
    if (!context.mounted) return;

    try {
      final dialogContext = context;
      bool dialogShown = false;

      showDialog(
        context: context,
        barrierDismissible: true, // Allow back button
        builder: (dialogCtx) {
          dialogShown = true;
          return PopScope(
            canPop: true, // Allow back button
            onPopInvoked: (didPop) {
              if (didPop) {
                // User pressed back button
              }
            },
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Подготовка к печати...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await ReportService.printToolReport(tool, dialogContext).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло. Повторите попытку.');
        },
      );

      // Close progress dialog safely
      if (dialogShown && dialogContext.mounted) {
        try {
          Navigator.of(dialogContext).pop();
        } catch (e) {
          // Dialog might already be closed
        }
      }

      // Show success message
      if (dialogContext.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (dialogContext.mounted) {
            ErrorHandler.showSuccessDialog(
              dialogContext,
              'Отчет отправлен на печать',
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        // Try to close any open dialogs
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ErrorHandler.showErrorDialog(context, 'Ошибка при печати: $e');
          }
        });
      }
    }
  }
}
