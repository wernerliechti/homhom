import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TimelineScreen(),
    const CameraScreen(),
    const GoalsScreen(),
  ];

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

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Timeline Screen',
              style: AppTheme.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Chronological view of all your meals',
              style: AppTheme.body2,
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Camera Screen',
              style: AppTheme.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Capture meals and get AI nutrition analysis',
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