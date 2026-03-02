import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'features_dashboard.dart';
import 'health_records.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 1;

  // Made non-static to allow dynamic injection or keys if needed later
  final List<Widget> _widgetOptions = const <Widget>[
    DashboardScreen(),
    FeaturesDashboardScreen(),
    HealthRecordsScreen(),
  ];

  void _onItemTapped(int index) {
    // Standard local state update to trigger the IndexedStack to switch views
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // IndexedStack preserves the state (e.g., scroll position, form inputs)
      // of each screen when switching between tabs.
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2), // Soft shadow rising upwards
            ),
          ],
        ),
        child: BottomNavigationBar(
          // Strict theme enforcement
          backgroundColor: theme.colorScheme.primary,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps_rounded),
              label: 'Features',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_outlined),
              activeIcon: Icon(Icons.folder_copy_rounded),
              label: 'Records',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor:
              theme.colorScheme.surface, // Active items are crisp white
          unselectedItemColor:
              theme
                  .colorScheme
                  .secondary, // Inactive items use secondary C5D4E5
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
