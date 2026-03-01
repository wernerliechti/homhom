import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'meal_metadata_screen.dart';

class CameraScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const CameraScreen({super.key, this.onNavigateToTab});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // AI Status Card
                _buildAIStatusCard(provider),
                const SizedBox(height: 24),

                // Capture Options
                _buildCaptureOptions(),
                const SizedBox(height: 32),

                // Instructions
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Capture Your Meal',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a photo or select from gallery to analyze nutrition',
            style: AppTheme.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatusCard(NutritionProvider provider) {
    return FutureBuilder<bool>(
      future: provider.isAIConfigured(),
      builder: (context, snapshot) {
        final isConfigured = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isConfigured 
                ? AppTheme.success.withAlpha(20) 
                : AppTheme.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConfigured ? AppTheme.success : AppTheme.warning,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConfigured ? Icons.check_circle : Icons.warning,
                color: isConfigured ? AppTheme.success : AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured ? 'AI Analysis Ready' : 'AI Setup Required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isConfigured ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConfigured 
                          ? 'Food recognition and nutrition analysis enabled'
                          : 'Configure OpenAI API key in Goals → Settings',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConfigured)
                TextButton(
                  onPressed: () {
                    widget.onNavigateToTab?.call(3); // Goals tab
                  },
                  child: const Text('Setup'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptureOptions() {
    return Column(
      children: [
        // Camera Button
        _buildOptionButton(
          icon: Icons.camera_alt,
          title: 'Take Photo',
          subtitle: 'Capture your meal with camera',
          onTap: _isProcessing ? null : _captureFromCamera,
          primary: true,
        ),
        const SizedBox(height: 16),
        
        // Gallery Button
        _buildOptionButton(
          icon: Icons.photo_library,
          title: 'Choose from Gallery',
          subtitle: 'Select existing photo',
          onTap: _isProcessing ? null : _selectFromGallery,
          primary: false,
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary 
                      ? Colors.white.withAlpha(40)
                      : AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: primary ? Colors.white : AppTheme.primary,
                  size: 28,
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
              if (_isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tips for Better Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildTipsList(),
        ],
      ),
    );
  }

  List<Widget> _buildTipsList() {
    final tips = [
      'Take photos from directly above the food',
      'Ensure good lighting and clear visibility',
      'Include the entire plate or dish in frame',
      'Separate mixed foods when possible',
      'Add plate diameter for better portion accuracy',
    ];

    return tips.map((tip) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _captureFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _selectFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Good quality while keeping file size reasonable
        maxWidth: 2048,   // Limit resolution for faster processing
        maxHeight: 2048,
      );

      if (image == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Haptic feedback for successful capture
      HapticFeedback.mediumImpact();

      // Navigate to metadata screen
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MealMetadataScreen(
              imagePath: image.path,
            ),
          ),
        );

        // If meal was successfully added, show confirmation
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🍽️ Meal added! AI is analyzing your food...'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate back to timeline to see the new meal
          widget.onNavigateToTab?.call(1);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}