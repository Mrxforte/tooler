// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tool.dart';
import '../../../viewmodels/tools_provider.dart';
import '../../../views/widgets/selection_tool_card.dart';
import '../tools/tool_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  _SearchScreenState createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Tool> _searchResults = [];
  ToolsProvider? _toolsProvider;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted || _toolsProvider == null) return;
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final toolsProvider = _toolsProvider!;
    setState(() => _searchResults = toolsProvider.tools
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.brand.toLowerCase().contains(q) ||
            t.uniqueId.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.currentLocationName.toLowerCase().contains(q))
        .toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Поиск инструментов...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() => _searchResults = []);
          },
        )
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => Provider.of<ToolsProvider>(context, listen: false)
          .loadTools(forceRefresh: true),
      child: _searchResults.isEmpty
          ? _buildEmptySearchScreen()
          : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final tool = _searchResults[index];
              return SelectionToolCard(
                tool: tool,
                selectionMode: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedToolDetailsScreen(tool: tool),
                  ),
                ),
              );
            },
          ),
    ),
  );

  Widget _buildEmptySearchScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty ? 'Начните вводить для поиска' : 'Ничего не найдено',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
     ); 




}
