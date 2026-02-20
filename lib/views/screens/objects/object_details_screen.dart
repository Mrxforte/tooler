import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/construction_object.dart';
import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../core/utils/error_handler.dart';
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

class _ObjectDetailsScreenState extends State<ObjectDetailsScreen> {
  // Tools filters
  final TextEditingController _toolsSearchController = TextEditingController();
  String _toolsSortBy = 'name';
  bool _toolsShowFavoritesOnly = false;

  // Multi-select state
  bool _toolsSelectionMode = false;
  final Set<String> _selectedToolIds = {};

  @override
  void dispose() {
    _toolsSearchController.dispose();
    _selectedToolIds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    var toolsOnObject = toolsProvider.tools
        .where((tool) => tool.currentLocation == widget.object.id)
        .toList();

    // Apply tools filters
    if (_toolsShowFavoritesOnly) {
      toolsOnObject = toolsOnObject.where((t) => t.isFavorite).toList();
    }
    if (_toolsSearchController.text.isNotEmpty) {
      final q = _toolsSearchController.text.toLowerCase();
      toolsOnObject = toolsOnObject
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.brand.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q),
          )
          .toList();
    }
    // Apply tools sorting
    switch (_toolsSortBy) {
      case 'date':
        toolsOnObject.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'brand':
        toolsOnObject.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'name':
      default:
        toolsOnObject.sort((a, b) => a.title.compareTo(b.title));
    }

    final selectedTools = toolsOnObject
        .where((t) => _selectedToolIds.contains(t.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: _toolsSelectionMode
            ? Text('${_selectedToolIds.length} выбранных')
            : Text(widget.object.name),
        centerTitle: false,
        leading: _toolsSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _toolsSelectionMode = false;
                    _selectedToolIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_toolsSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () => ReportService.showObjectReportTypeDialog(
                context,
                widget.object,
                toolsOnObject,
                (type) => ReportService.shareObjectReport(
                  widget.object,
                  toolsOnObject,
                  context,
                  type,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              onPressed: () => ReportService.printObjectReport(
                widget.object,
                toolsOnObject,
                context,
              ),
            ),
            if (auth.canControlObjects)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditObjectScreen(object: widget.object),
                  ),
                ),
              ),
            if (auth.canControlObjects)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _showDeleteObjectConfirmation(context),
              ),
            Consumer<ObjectsProvider>(
              builder: (context, op, _) {
                final updatedObject = op.objects.firstWhere(
                  (o) => o.id == widget.object.id,
                  orElse: () => widget.object,
                );
                return IconButton(
                  icon: Icon(
                    updatedObject.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: updatedObject.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    op.toggleFavorite(widget.object.id);
                  },
                );
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<ToolsProvider>(
            context,
            listen: false,
          ).loadTools(forceRefresh: true);
          await Provider.of<ObjectsProvider>(
            context,
            listen: false,
          ).loadObjects(forceRefresh: true);
        },
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Compact header with image
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image or gradient
                        widget.object.displayImage != null
                            ? Image(
                                image:
                                    widget.object.displayImage!.startsWith(
                                      'http',
                                    )
                                    ? NetworkImage(widget.object.displayImage!)
                                          as ImageProvider
                                    : FileImage(
                                        File(widget.object.displayImage!),
                                      ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildObjectImagePlaceholder(),
                              )
                            : _buildObjectImagePlaceholder(),
                        // Overlay gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.object.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (widget.object.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.object.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Stats bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactStat(
                            icon: Icons.build_circle_outlined,
                            label: 'Инструменты',
                            value: toolsOnObject.length.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: _buildCompactStat(
                            icon: Icons.calendar_today,
                            label: 'Начало',
                            value: DateFormat(
                              'd MMM',
                            ).format(widget.object.createdAt),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Инструменты на объекте',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${toolsOnObject.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Search and filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _toolsSearchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск инструментов...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 22,
                          color: Colors.grey.shade600,
                        ),
                        suffixIcon: _toolsSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _toolsSearchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Все'),
                            selected: !_toolsShowFavoritesOnly,
                            onSelected: (_) =>
                                setState(() => _toolsShowFavoritesOnly = false),
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            checkmarkColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Избранные'),
                            selected: _toolsShowFavoritesOnly,
                            onSelected: (_) => setState(
                              () => _toolsShowFavoritesOnly =
                                  !_toolsShowFavoritesOnly,
                            ),
                            selectedColor: Colors.red.withValues(alpha: 0.1),
                            checkmarkColor: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.checklist, size: 18),
                            label: Text(
                              _toolsSelectionMode ? 'Отменить' : 'Выбрать',
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _toolsSelectionMode = !_toolsSelectionMode;
                                if (!_toolsSelectionMode) {
                                  _selectedToolIds.clear();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: _toolsSelectionMode
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              foregroundColor: _toolsSelectionMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButton<String>(
                              value: _toolsSortBy,
                              underline: const SizedBox(),
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade700,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text('По названию'),
                                ),
                                DropdownMenuItem(
                                  value: 'date',
                                  child: Text('По дате'),
                                ),
                                DropdownMenuItem(
                                  value: 'brand',
                                  child: Text('По бренду'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _toolsSortBy = v ?? 'name'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_toolsSelectionMode)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedToolIds.isEmpty
                                  ? 'Режим выбора включен'
                                  : 'Выбрано: ${_selectedToolIds.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: toolsOnObject.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      if (_selectedToolIds.length ==
                                          toolsOnObject.length) {
                                        _selectedToolIds.clear();
                                      } else {
                                        _selectedToolIds
                                          ..clear()
                                          ..addAll(
                                            toolsOnObject.map((t) => t.id),
                                          );
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.select_all, size: 18),
                            label: Text(
                              _selectedToolIds.length == toolsOnObject.length
                                  ? 'Снять всё'
                                  : 'Выбрать всё',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                toolsOnObject.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(
                          icon: Icons.build_circle_outlined,
                          title: 'На объекте нет инструментов',
                          subtitle: 'Переместите инструменты на этот объект',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final tool = toolsOnObject[index];
                            final isSelected = _selectedToolIds.contains(
                              tool.id,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _toolsSelectionMode = true;
                                    _selectedToolIds.add(tool.id);
                                  });
                                },
                                child: _toolsSelectionMode
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue.shade50
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.grey.shade200,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          leading: Checkbox(
                                            value: isSelected,
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedToolIds.add(tool.id);
                                                } else {
                                                  _selectedToolIds.remove(
                                                    tool.id,
                                                  );
                                                  if (_selectedToolIds
                                                      .isEmpty) {
                                                    _toolsSelectionMode = false;
                                                  }
                                                }
                                              });
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          title: Text(
                                            tool.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tool.brand,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  tool.currentLocationName,
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedToolIds.remove(
                                                  tool.id,
                                                );
                                                if (_selectedToolIds.isEmpty) {
                                                  _toolsSelectionMode = false;
                                                }
                                              } else {
                                                _selectedToolIds.add(tool.id);
                                              }
                                            });
                                          },
                                        ),
                                      )
                                    : SelectionToolCard(
                                        tool: tool,
                                        selectionMode: false,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EnhancedToolDetailsScreen(
                                                  tool: tool,
                                                ),
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }, childCount: toolsOnObject.length),
                        ),
                      ),
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 160)),
              ],
            ),
            if (_toolsSelectionMode)
              Positioned.fill(
                child: _buildSelectionFullScreenOverlay(
                  context: context,
                  auth: auth,
                  toolsOnObject: toolsOnObject,
                  selectedTools: selectedTools,
                ),
              ),
            if (!_toolsSelectionMode && _selectedToolIds.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _buildSelectionActionBar(
                  context: context,
                  auth: auth,
                  toolsOnObject: toolsOnObject,
                  selectedTools: selectedTools,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
      ),
      child: Center(
        child: Icon(Icons.location_city, size: 100, color: Colors.white24),
      ),
    );
  }

  Widget _buildSelectionFullScreenOverlay({
    required BuildContext context,
    required AuthProvider auth,
    required List<Tool> toolsOnObject,
    required List<Tool> selectedTools,
  }) {
    return Container(
      color: Colors.grey.shade50,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Выбрано: ${_selectedToolIds.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedToolIds.length == toolsOnObject.length) {
                          _selectedToolIds.clear();
                        } else {
                          _selectedToolIds
                            ..clear()
                            ..addAll(toolsOnObject.map((t) => t.id));
                        }
                      });
                    },
                    icon: const Icon(Icons.select_all, size: 18),
                    label: Text(
                      _selectedToolIds.length == toolsOnObject.length
                          ? 'Снять всё'
                          : 'Выбрать всё',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 170),
                itemCount: toolsOnObject.length,
                itemBuilder: (context, index) {
                  final tool = toolsOnObject[index];
                  final isSelected = _selectedToolIds.contains(tool.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedToolIds.add(tool.id);
                            } else {
                              _selectedToolIds.remove(tool.id);
                              if (_selectedToolIds.isEmpty) {
                                _toolsSelectionMode = false;
                              }
                            }
                          });
                        },
                        title: Text(
                          tool.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(tool.brand),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: false,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedToolIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildSelectionActionBar(
                  context: context,
                  auth: auth,
                  toolsOnObject: toolsOnObject,
                  selectedTools: selectedTools,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar({
    required BuildContext context,
    required AuthProvider auth,
    required List<Tool> toolsOnObject,
    required List<Tool> selectedTools,
  }) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Выбрано ${selectedTools.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedToolIds.length == toolsOnObject.length) {
                          _selectedToolIds.clear();
                        } else {
                          _selectedToolIds
                            ..clear()
                            ..addAll(toolsOnObject.map((t) => t.id));
                        }
                      });
                    },
                    icon: const Icon(Icons.select_all, size: 18),
                    label: Text(
                      _selectedToolIds.length == toolsOnObject.length
                          ? 'Снять всё'
                          : 'Все',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _toolsSelectionMode = false;
                        _selectedToolIds.clear();
                      });
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Закрыть выбор',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showMoveOptionsDialog(
                        context,
                        toolIds: selectedTools.map((t) => t.id).toList(),
                      ),
                      icon: const Icon(Icons.move_to_inbox_outlined),
                      label: const Text('Переместить'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final toolsProvider = Provider.of<ToolsProvider>(
                          context,
                          listen: false,
                        );
                        final toolsToFavorite = selectedTools
                            .where((tool) => !tool.isFavorite)
                            .toList();

                        if (toolsToFavorite.isEmpty) {
                          ErrorHandler.showInfoDialog(
                            context,
                            'Все выбранные инструменты уже в избранном',
                          );
                          return;
                        }

                        for (final tool in toolsToFavorite) {
                          await toolsProvider.toggleFavorite(tool.id);
                        }
                        if (!mounted) return;
                        setState(() {
                          _toolsSelectionMode = false;
                          _selectedToolIds.clear();
                        });
                        ErrorHandler.showSuccessDialog(
                          context,
                          'Добавлено в избранное: ${toolsToFavorite.length}',
                        );
                      },
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('В избранное'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _showMultipleItemsReportDialog(
                        context,
                        selectedTools: selectedTools,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Отчет'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: auth.isAdmin
                          ? () => _confirmDeleteSelectedTools(
                              context,
                              selectedTools,
                            )
                          : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showMoveOptionsDialog(
    BuildContext context, {
    required List<String> toolIds,
  }) {
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );
    final otherObjects = objectsProvider.objects
        .where((o) => o.id != widget.object.id)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.green),
              title: const Text('В гараж'),
              subtitle: const Text('Переместить выбранные инструменты в гараж'),
              onTap: () {
                Navigator.pop(sheetContext);
                _moveSelectedToolsToLocation(
                  context,
                  toolIds: toolIds,
                  targetLocationId: 'garage',
                  targetLocationName: 'Гараж',
                );
              },
            ),
            if (otherObjects.isNotEmpty) ...[
              const Divider(height: 1),
              ...otherObjects.map(
                (obj) => ListTile(
                  leading: const Icon(Icons.location_city, color: Colors.blue),
                  title: Text(obj.name),
                  subtitle: Text(obj.description),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _moveSelectedToolsToLocation(
                      context,
                      toolIds: toolIds,
                      targetLocationId: obj.id,
                      targetLocationName: obj.name,
                    );
                  },
                ),
              ),
            ] else
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Нет других объектов для перемещения'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _moveSelectedToolsToLocation(
    BuildContext context, {
    required List<String> toolIds,
    required String targetLocationId,
    required String targetLocationName,
  }) async {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final objectsProvider = Provider.of<ObjectsProvider>(
      context,
      listen: false,
    );

    final uniqueIds = toolIds.toSet().toList();
    final movableIds = uniqueIds
        .where(
          (id) =>
              toolsProvider.getToolById(id)?.currentLocation !=
              targetLocationId,
        )
        .toList();

    if (movableIds.isEmpty) {
      if (mounted) {
        ErrorHandler.showInfoDialog(
          context,
          'Выбранные инструменты уже находятся в "$targetLocationName"',
        );
      }
      return;
    }

    try {
      toolsProvider.selectToolsByIds(movableIds);
      await toolsProvider.moveSelectedToolsWithProvider(
        targetLocationId,
        targetLocationName,
        objectsProvider,
      );

      if (!mounted) return;
      setState(() {
        _toolsSelectionMode = false;
        _selectedToolIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorDialog(context, 'Ошибка перемещения: $e');
    } finally {
      toolsProvider.clearAllSelections();
    }
  }

  void _showMultipleItemsReportDialog(
    BuildContext context, {
    required List<Tool> selectedTools,
  }) {
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
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.assessment,
                      size: 28,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Создать отчет',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Выбрано: ${selectedTools.length} инструмент(ов)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: const Text('PDF отчет'),
                  subtitle: const Text('Полный отчет в формате PDF'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(context);
                    await _generateMultipleToolsReport(
                      context,
                      selectedTools,
                      ReportType.pdf,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.text_fields, color: Colors.blue),
                  ),
                  title: const Text('Текстовый отчет'),
                  subtitle: const Text('Простой текстовый формат'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(context);
                    await _generateMultipleToolsReport(
                      context,
                      selectedTools,
                      ReportType.text,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Generate and share multiple tools report with progress dialog
  Future<void> _generateMultipleToolsReport(
    BuildContext context,
    List<Tool> selectedTools,
    ReportType reportType,
  ) async {
    if (!context.mounted) return;

    try {
      final dialogContext = context;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => PopScope(
          canPop: true,
          onPopInvoked: (didPop) {},
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
        ),
      );

      // Generate report
      await ReportService.shareMultipleToolsReport(
        selectedTools,
        dialogContext,
        reportType,
      );

      // Close progress dialog
      if (dialogContext.mounted) {
        try {
          Navigator.of(dialogContext).pop();
        } catch (e) {}
      }

      // Show success and clear selection
      if (dialogContext.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (dialogContext.mounted) {
            setState(() {
              _toolsSelectionMode = false;
              _selectedToolIds.clear();
            });
            ScaffoldMessenger.of(dialogContext).hideCurrentSnackBar();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text(
                  reportType == ReportType.pdf
                      ? 'Отчет готов! ${selectedTools.length} инструмент(ов)'
                      : 'Отчет на клипборде ${selectedTools.length} инструмент(ов)',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            // fix it
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при создании отчета: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  void _showDeleteObjectConfirmation(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.canControlObjects) {
      ErrorHandler.showErrorDialog(
        context,
        'Только администратор может удалять объекты',
      );
      return;
    }

    final outerContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить "${widget.object.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Provider.of<ObjectsProvider>(
                outerContext,
                listen: false,
              ).deleteObject(widget.object.id, context: outerContext);
              if (!outerContext.mounted) return;
              await Future.delayed(const Duration(milliseconds: 500));
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

  void _confirmDeleteSelectedTools(
    BuildContext context,
    List<Tool> selectedTools,
  ) {
    if (selectedTools.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить инструменты?'),
        content: Text(
          'Будут удалены ${selectedTools.length} инструмент(ов).\n'
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedTools(selectedTools);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedTools(List<Tool> selectedTools) async {
    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    try {
      for (final tool in selectedTools) {
        await toolsProvider.deleteTool(tool.id, context: context);
      }
      if (!mounted) return;
      setState(() {
        _toolsSelectionMode = false;
        _selectedToolIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Удалено ${selectedTools.length} инструмент(ов)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
