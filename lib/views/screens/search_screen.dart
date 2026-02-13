import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../controllers/tools_provider.dart';
import '../widgets/selection_tool_card.dart';
import 'tool_details_screen.dart';

// ========== SEARCH SCREEN ==========
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Tool> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
    final results = toolsProvider.tools.where((tool) {
      return tool.title.toLowerCase().contains(query) ||
          tool.brand.toLowerCase().contains(query) ||
          tool.uniqueId.toLowerCase().contains(query) ||
          tool.description.toLowerCase().contains(query) ||
          tool.currentLocationName.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              setState(() {
                _searchResults = [];
              });
            },
          ),
        ],
      ),
      body: _searchResults.isEmpty
          ? _buildEmptySearchScreen()
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final tool = _searchResults[index];
                return SelectionToolCard(
                  tool: tool,
                  selectionMode: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnhancedToolDetailsScreen(tool: tool),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptySearchScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'Начните вводить для поиска'
                : 'Ничего не найдено',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
