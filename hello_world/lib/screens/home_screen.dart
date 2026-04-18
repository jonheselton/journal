import 'package:flutter/material.dart';
import 'day_list_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell with bottom tab bar.
/// Tab 0: Journal (notes & data list)
/// Tab 1: Insights (statistics, trends, tag cloud)
/// Tab 2: Settings (app config, security, export)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // GlobalKey to access DayListScreen's public methods (FAB action)
  final GlobalKey<DayListScreenState> _journalKey = GlobalKey();

  // Use keys to preserve state across tab switches
  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabs.addAll([
      DayListScreen(key: _journalKey),
      const InsightsScreen(),
      const SettingsScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // FAB only visible on the Journal tab
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _journalKey.currentState?.createOrEditToday(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
