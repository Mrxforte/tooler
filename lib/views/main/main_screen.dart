import 'package:flutter/material.dart';
import 'package:tooler/views/home/home_screen.dart';
import 'package:tooler/views/list_of_projects/list_of_projects.dart';
import 'package:tooler/views/list_of_tools/list_of_tools_screen.dart';
import 'package:tooler/views/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  List<Widget> pages = [
    HomeScreen(),
    ListOfToolsScreen(),
    ListOfProjects(),
    SettingsScreen(),
    //   You can add other screens here for Projects, Settings, etc.
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' Main Screen'), centerTitle: true),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
