import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'timeline_screen.dart';
import 'goals_stats_screen.dart';
import 'meal_metadata_screen.dart';
import 'manual_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TimelineScreen(onNavigateToAddMeal: _navigateToAddMeal),
      const GoalsStatsScreen(),
    ];
  }

  void _navigateToAddMeal() {
    _showAddMealOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
      floatingActionButton: _buildCenterAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timeline button (left)
          Expanded(
            child: _buildNavButton(
              icon: Icons.timeline_outlined,
              activeIcon: Icons.timeline,
              label: 'Timeline',
              isActive: _currentIndex == 0,
              onTap: () => _setIndex(0),
            ),
          ),
          
          // Spacer for center button
          const SizedBox(width: 80),
          
          // Goals button (right)
          Expanded(
            child: _buildNavButton(
              icon: Icons.flag_outlined,
              activeIcon: Icons.flag,
              label: 'Goals',
              isActive: _currentIndex == 1,
              onTap: () => _setIndex(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        onPressed: _showAddMealOptions,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  void _setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddMealOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                const Icon(Icons.restaurant, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Add Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how to add your meal',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Camera option
            _buildAddMealOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Capture your meal with camera',
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
              primary: true,
            ),
            
            const SizedBox(height: 12),
            
            // Gallery option
            _buildAddMealOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select existing photo',
              onTap: () {
                Navigator.pop(context);
                _selectFromGallery();
              },
              primary: false,
            ),
            
            const SizedBox(height: 12),
            
            // Manual entry option
            _buildAddMealOption(
              icon: Icons.edit,
              title: 'Manual Entry',
              subtitle: 'Enter nutrition manually',
              onTap: () {
                Navigator.pop(context);
                _navigateToManualEntry();
              },
              primary: false,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMealOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return Material(
      color: primary ? AppTheme.primary : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: primary ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary 
                      ? Colors.white.withAlpha(40)
                      : AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: primary ? Colors.white : AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primary ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: primary 
                            ? Colors.white.withAlpha(200)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: primary 
                    ? Colors.white.withAlpha(200)
                    : AppTheme.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _selectFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image == null) return;

      // Navigate to metadata screen
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MealMetadataScreen(
              imagePath: image.path,
            ),
          ),
        );

        // If meal was successfully added, show confirmation and switch to timeline
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🍽️ Meal added! Check the Timeline.'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            ),
          );
          
          // Switch to timeline tab
          _setIndex(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _navigateToManualEntry() async {
    if (mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const ManualEntryScreen(),
        ),
      );

      // If meal was successfully added, show confirmation and switch to timeline
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Food item added! Check the Timeline.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Switch to timeline tab
        _setIndex(0);
      }
    }
  }
}