import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'timeline_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      TimelineScreen(onNavigateToTab: _navigateToTab),
      CameraScreen(onNavigateToTab: _navigateToTab),
      const GoalsScreen(),
    ];
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? _buildTimelineFAB() : null,
    );
  }

  Widget _buildTimelineFAB() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _currentIndex = 2; // Switch to camera tab
        });
      },
      tooltip: 'Add Meal',
      child: const Icon(Icons.add),
    );
  }
}

// Placeholder screens - we'll implement these next
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomHom'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Dashboard Screen',
              style: AppTheme.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Daily nutrition overview and progress',
              style: AppTheme.body2,
            ),
          ],
        ),
      ),
    );
  }
}





class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Goals'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Goals Screen',
              style: AppTheme.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Configure your daily nutrition targets',
              style: AppTheme.body2,
            ),
          ],
        ),
      ),
    );
  }
}