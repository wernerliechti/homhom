import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'ai_loading_screen.dart';
import 'ai_results_screen.dart';

class AIAnalysisFlow extends StatefulWidget {
  final String imagePath;
  final double? plateDiameter;
  final double? dishWeight;

  const AIAnalysisFlow({
    super.key,
    required this.imagePath,
    this.plateDiameter,
    this.dishWeight,
  });

  @override
  State<AIAnalysisFlow> createState() => _AIAnalysisFlowState();
}

class _AIAnalysisFlowState extends State<AIAnalysisFlow> {
  bool _isLoading = true;
  List<FoodItem>? _analysisResults;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      final provider = context.read<NutritionProvider>();
      
      // Check if AI is configured
      if (!await provider.isAIConfigured()) {
        setState(() {
          _errorMessage = 'OpenAI API key not configured. Please set up your API key in Settings.';
          _isLoading = false;
        });
        return;
      }

      // Start AI analysis
      final foodItems = await provider.aiService.analyzeMealPhoto(
        widget.imagePath,
        plateDiameter: widget.plateDiameter,
        dishWeight: widget.dishWeight,
      );

      if (mounted) {
        if (foodItems.isEmpty) {
          setState(() {
            _errorMessage = 'Could not identify any food in the image. Try taking a clearer photo.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _analysisResults = foodItems;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Analysis failed: ${_getReadableError(e.toString())}';
          _isLoading = false;
        });
      }
    }
  }

  String _getReadableError(String error) {
    // Show the actual error for debugging, but with user-friendly context
    if (error.contains('401') || error.contains('unauthorized')) {
      return 'Invalid API key. Please check your OpenAI API key in Settings.\n\nTechnical details: $error';
    } else if (error.contains('429') || error.contains('quota')) {
      return 'API quota exceeded. Please check your OpenAI billing and usage.\n\nTechnical details: $error';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your internet connection.\n\nTechnical details: $error';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.\n\nTechnical details: $error';
    }
    
    // For debugging: always show the full error
    return 'Analysis failed. Please try again or check your settings.\n\nTechnical details: $error';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AILoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_analysisResults != null) {
      return AIResultsScreen(
        imagePath: widget.imagePath,
        foodItems: _analysisResults!,
        plateDiameter: widget.plateDiameter,
        dishWeight: widget.dishWeight,
      );
    }

    // This shouldn't happen, but fallback to error
    return _buildErrorScreen();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Failed'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryAnalysis,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _savePhotoOnly,
                  icon: const Icon(Icons.photo, size: 20),
                  label: const Text('Save Photo Only'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analysisResults = null;
    });
    await _startAnalysis();
  }

  Future<void> _savePhotoOnly() async {
    try {
      final provider = context.read<NutritionProvider>();
      
      await provider.addMealPhoto(
        widget.imagePath,
        plateDiameter: widget.plateDiameter,
        dishWeight: widget.dishWeight,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo saved! Add nutrition details later.'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photo: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}