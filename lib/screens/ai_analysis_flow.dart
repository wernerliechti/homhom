import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../providers/nutrition_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'ai_loading_screen.dart';
import 'ai_results_screen.dart';

class AIAnalysisFlow extends StatefulWidget {
  final String imagePath;
  final String? dishName;
  final double? plateDiameter;
  final double? dishWeight;

  const AIAnalysisFlow({
    super.key,
    required this.imagePath,
    this.dishName,
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
      
      // Try to analyze meal with fallback mechanism:
      // 1. First try local OpenAI key if configured
      // 2. Fall back to Firebase Cloud Function (uses server-side key)
      // 3. Only fail if both methods unavailable
      
      List<FoodItem>? foodItems;
      
      // Attempt 1: Use local OpenAI API key if available
      try {
        if (await provider.aiService.isConfigured()) {
          print('🔑 Using local OpenAI API key for analysis...');
          foodItems = await provider.aiService.analyzeMealPhoto(
            widget.imagePath,
            dishName: widget.dishName,
            plateDiameter: widget.plateDiameter,
            dishWeight: widget.dishWeight,
          );
          print('✅ Analysis completed via local OpenAI');
        }
      } catch (localError) {
        print('⚠️ Local analysis failed ($localError), attempting Firebase fallback...');
        foodItems = null; // Reset to null to trigger fallback
      }
      
      // Attempt 2: Fall back to Firebase Cloud Function
      if (foodItems == null) {
        try {
          print('☁️ Attempting Firebase Cloud Function analysis...');
          final firebaseService = FirebaseService();
          
          // Check if Firebase is properly initialized
          if (firebaseService.currentUser == null) {
            print('⚠️ User not authenticated, attempting anonymous sign-in...');
            try {
              await firebaseService.signInAnonymously();
              print('✅ Anonymous sign-in successful');
            } catch (authError) {
              throw Exception('User authentication required: $authError');
            }
          }
          
          if (!firebaseService.isAuthenticated) {
            throw Exception('User must be authenticated to use meal analysis');
          }
          
          // Convert image to base64
          final imageFile = File(widget.imagePath);
          final imageBytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          
          // Call Cloud Function
          final response = await firebaseService.processMeal(
            imageBase64: base64Image,
            userPreferences: widget.dishName != null 
              ? {'dishName': widget.dishName}
              : null,
          );
          
          // Parse response and convert to FoodItem objects
          if (response['analysis'] != null) {
            final analysisData = response['analysis'] as Map<String, dynamic>;
            foodItems = _parseFoodItemsFromAnalysis(analysisData);
            
            print('✅ Analysis completed via Firebase Cloud Function');
            print('📊 Remaining HOMs: ${response['remainingHoms']}');
          } else {
            throw Exception('No analysis data received from server');
          }
        } catch (firebaseError) {
          print('❌ Firebase analysis failed: $firebaseError');
          // Both methods failed, will handle error below
          if (mounted) {
            setState(() {
              _errorMessage = 'Analysis failed: ${_getReadableError(firebaseError.toString())}';
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      if (mounted) {
        if (foodItems == null || foodItems.isEmpty) {
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

  /// Parse food items from Firebase Cloud Function response
  List<FoodItem> _parseFoodItemsFromAnalysis(Map<String, dynamic> analysisData) {
    final foodItems = <FoodItem>[];
    
    // Handle response from Cloud Function
    if (analysisData['foods'] is List) {
      final foods = analysisData['foods'] as List<dynamic>;
      
      for (int i = 0; i < foods.length; i++) {
        final foodData = foods[i] as Map<String, dynamic>;
        
        // Extract nutrition data
        NutritionData nutrition;
        if (foodData['nutrition'] != null) {
          nutrition = NutritionData.fromMap(foodData['nutrition'] as Map<String, dynamic>);
        } else if (foodData['macros'] != null) {
          // Handle alternative format from Cloud Function
          final macros = foodData['macros'] as Map<String, dynamic>;
          nutrition = NutritionData(
            calories: (foodData['calories'] as num?)?.toDouble() ?? 0.0,
            protein: (macros['protein'] as num?)?.toDouble() ?? 0.0,
            carbs: (macros['carbs'] as num?)?.toDouble() ?? 0.0,
            fat: (macros['fats'] as num?)?.toDouble() ?? 0.0,
          );
        } else {
          nutrition = NutritionData.zero;
        }
        
        foodItems.add(
          FoodItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: foodData['name'] as String? ?? 'Unknown Food',
            description: foodData['description'] as String? ?? '',
            estimatedWeight: (foodData['estimatedWeight'] as num?)?.toDouble() ?? 100.0,
            confidence: (foodData['confidence'] as num?)?.toDouble() ?? 0.7,
            portionMethod: foodData['portionMethod'] as String?,
            nutrition: nutrition,
            metadata: {
              'timestamp': DateTime.now().toIso8601String(),
              'source': 'firebase_cloud_function',
            },
          ),
        );
      }
    }
    
    return foodItems;
  }

  String _getReadableError(String error) {
    // Translate server errors to user-friendly messages
    if (error.contains('401') || error.contains('unauthorized')) {
      return 'Authorization failed. Please make sure you\'re signed in.';
    } else if (error.contains('429') || error.contains('quota')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    } else if (error.contains('network') || error.contains('connection') || error.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('timeout') || error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('Unable to identify') || error.contains('failed to analyze')) {
      return 'Could not analyze this image. Please try a clearer photo of your meal.';
    } else if (error.contains('not authenticated')) {
      return 'Please sign in to use meal analysis.';
    }
    
    // Generic fallback (don't expose server errors to users)
    return 'Analysis failed. Please try again.';
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