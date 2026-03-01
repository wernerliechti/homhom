import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'ai_analysis_flow.dart';

class MealMetadataScreen extends StatefulWidget {
  final String imagePath;

  const MealMetadataScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<MealMetadataScreen> createState() => _MealMetadataScreenState();
}

class _MealMetadataScreenState extends State<MealMetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _weightController = TextEditingController();
  
  bool _includePlateSize = false;
  bool _includeDishWeight = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _plateController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Details'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview
              _buildPhotoPreview(),
              const SizedBox(height: 24),

              // Metadata Section
              _buildMetadataSection(),
              const SizedBox(height: 24),

              // Benefits Card
              _buildBenefitsCard(),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.photo, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Meal Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: AppTheme.error, size: 32),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Improve Accuracy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add optional details for more precise nutrition analysis',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Plate Diameter Toggle
          _buildMetadataToggle(
            title: 'Plate/Bowl Diameter',
            subtitle: 'Help estimate portion sizes',
            icon: Icons.circle_outlined,
            isEnabled: _includePlateSize,
            onChanged: (value) {
              setState(() {
                _includePlateSize = value;
                if (!value) {
                  _plateController.clear();
                }
              });
            },
          ),

          if (_includePlateSize) ...[
            const SizedBox(height: 16),
            _buildPlateInput(),
          ],

          const SizedBox(height: 16),

          // Dish Weight Toggle
          _buildMetadataToggle(
            title: 'Total Dish Weight',
            subtitle: 'More precise portion calculation',
            icon: Icons.scale_outlined,
            isEnabled: _includeDishWeight,
            onChanged: (value) {
              setState(() {
                _includeDishWeight = value;
                if (!value) {
                  _weightController.clear();
                }
              });
            },
          ),

          if (_includeDishWeight) ...[
            const SizedBox(height: 16),
            _buildWeightInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled ? AppTheme.primary.withAlpha(15) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? AppTheme.primary.withAlpha(100) : AppTheme.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEnabled ? AppTheme.primary : AppTheme.textTertiary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? AppTheme.textSecondary : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPlateInput() {
    return TextFormField(
      controller: _plateController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Plate/Bowl Diameter',
        suffixText: 'cm',
        hintText: '25',
        helperText: 'Standard dinner plate: ~25-27cm, bowl: ~15-20cm',
        prefixIcon: Icon(Icons.circle_outlined, size: 20),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$')),
      ],
      validator: (value) {
        if (_includePlateSize && (value == null || value.isEmpty)) {
          return 'Please enter plate diameter';
        }
        if (value != null && value.isNotEmpty) {
          final diameter = double.tryParse(value);
          if (diameter == null || diameter <= 0 || diameter > 100) {
            return 'Enter a valid diameter (1-100 cm)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildWeightInput() {
    return TextFormField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Total Dish Weight',
        suffixText: 'grams',
        hintText: '350',
        helperText: 'Weigh the entire dish including plate/bowl',
        prefixIcon: Icon(Icons.scale_outlined, size: 20),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$')),
      ],
      validator: (value) {
        if (_includeDishWeight && (value == null || value.isEmpty)) {
          return 'Please enter dish weight';
        }
        if (value != null && value.isNotEmpty) {
          final weight = double.tryParse(value);
          if (weight == null || weight <= 0 || weight > 5000) {
            return 'Enter a valid weight (1-5000 grams)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Analysis Benefits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildBenefitsList(),
        ],
      ),
    );
  }

  List<Widget> _buildBenefitsList() {
    final benefits = [
      'Identifies multiple foods in mixed dishes',
      'Estimates calories, protein, carbs, and fat',
      'Calculates portion sizes from visual analysis',
      'Includes micronutrients when significant',
      'Learns from your portion preferences over time',
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.success,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                benefit,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isProcessing ? null : _processMeal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Analyzing with AI...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Analyze Meal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isProcessing ? null : _skipAnalysis,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Skip AI Analysis',
            style: TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Future<void> _processMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse optional metadata
      double? plateDiameter;
      double? dishWeight;

      if (_includePlateSize && _plateController.text.isNotEmpty) {
        plateDiameter = double.tryParse(_plateController.text);
      }

      if (_includeDishWeight && _weightController.text.isNotEmpty) {
        dishWeight = double.tryParse(_weightController.text);
      }

      // Navigate to AI analysis flow
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AIAnalysisFlow(
              imagePath: widget.imagePath,
              plateDiameter: plateDiameter,
              dishWeight: dishWeight,
            ),
          ),
        );

        if (result == true && mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true); // Return success to camera screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start analysis: $e'),
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

  Future<void> _skipAnalysis() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final provider = context.read<NutritionProvider>();
      
      // Add meal without AI analysis (just the photo)
      await provider.addMealPhoto(widget.imagePath);

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Meal photo saved! Add nutrition details later.'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save meal: $e'),
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