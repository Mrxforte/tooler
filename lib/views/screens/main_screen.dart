import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../controllers/tools_provider.dart';
import '../../controllers/objects_provider.dart';
import '../../services/report_service.dart';
import '../../services/error_handler.dart';
import 'garage_screen.dart';
import 'tools_list_screen.dart';
import 'objects_list_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

// ========== MAIN SCREEN ==========
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EnhancedGarageScreen(),
    const ToolsListScreen(),
    const EnhancedObjectsListScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Гараж',
    'Инструменты',
    'Объекты',
    'Избранное',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 0 || _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _generateInventoryReport(context),
                ),
              ]
            : null,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.garage), label: 'Гараж'),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Инструменты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Объекты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Future<void> _generateInventoryReport(BuildContext context) async {
    try {
      final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
      final objectsProvider = Provider.of<ObjectsProvider>(
        context,
        listen: false,
      );

      ReportService.showReportTypeDialog(
        context,
        Tool(
          id: 'inventory',
          title: 'Инвентаризация',
          description: '',
          brand: '',
          uniqueId: '',
          currentLocation: '',
          currentLocationName: '',
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'local',
        ),
        (type) async {
          await ReportService.shareInventoryReport(
            toolsProvider.tools,
            objectsProvider.objects,
            context,
            type,
          );
        },
      );
    } catch (e) {
      ErrorHandler.showErrorDialog(context, 'Ошибка при создании отчета: $e');
    }
  }
}
