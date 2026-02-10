import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tooler/app/providers/auth_provider.dart';
import 'package:tooler/app/providers/tool_provider.dart';
import 'package:tooler/features/export/screens/pdf_preview_screen.dart';
import 'package:tooler/features/projects/screens/projects_screen.dart';
import 'package:tooler/features/profile/screens/profile_screen.dart';
import 'package:tooler/features/tools/screens/tools_screen.dart';
import 'package:tooler/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ToolsScreen(),
    const ProjectsScreen(),
    const PdfPreviewScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: s.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.construction),
            label: s.projects,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.picture_as_pdf),
            label: s.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: s.profile,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddToolDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddToolDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).addTool),
        content: const AddToolForm(),
      ),
    );
  }
}
