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
          
          // Ensure user is authenticated
          if (firebaseService.currentUser == null) {
            print('⚠️ User not authenticated, attempting anonymous sign-in...');
            try {
              await firebaseService.signInAnonymously();
              print('✅ Anonymous sign-in successful: ${firebaseService.currentUser?.uid}');
            } catch (authError) {
              print('❌ Anonymous sign-in error: $authError');
              print('   Error type: ${authError.runtimeType}');
              
              // Pigeon deserialization bug: auth may have succeeded despite error
              if (authError.toString().contains('PigeonUserDetails')) {
                print('⚠️ Pigeon deserialization error detected');
                print('   Waiting for auth state to settle...');
                // Wait longer to allow ID token to be generated
                await Future.delayed(Duration(seconds: 2));
                
                if (firebaseService.currentUser != null) {
                  print('✅ User IS authenticated despite error: ${firebaseService.currentUser?.uid}');
                  print('   (Known Pigeon bug - auth succeeded)');
                  print('   Waiting additional time for ID token generation...');
                  await Future.delayed(Duration(seconds: 1));
                  // Continue - auth succeeded despite the error
                } else {
                  print('❌ Real authentication failure');
                  throw authError;
                }
              } else {
                print('   Error toString: ${authError.toString()}');
                print('   Troubleshooting: Try these steps:');
                print('   1. Go to Firebase Console → Authentication → Sign-in method');
                print('   2. Verify Anonymous is enabled');
                print('   3. Go to Project Settings → Android app');
                print('   4. Verify your SHA-1 fingerprint is listed');
                print('   5. Verify package name is: com.saynode.homhom');
                print('   6. Try: flutter clean && flutter run');
                throw authError;
              }
            }
          }
          
          if (!firebaseService.isAuthenticated) {
            throw Exception('User must be authenticated to use meal analysis');
          }
          
          print('🔐 User authenticated as: ${firebaseService.currentUser?.uid}');
          
          // Convert image to base64
          final imageFile = File(widget.imagePath);
          final imageBytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          
          print('📸 Image converted to base64 (${base64Image.length} bytes)');
          
          // Call Cloud Function
          try {
            final response = await firebaseService.processMeal(
              imageBase64: base64Image,
              userPreferences: widget.dishName != null 
                ? {'dishName': widget.dishName}
                : null,
            );
            
            // Parse response and convert to FoodItem objects
            print('📋 Cloud Function response: $response');
            
            if (response['analysis'] != null) {
              final analysisData = response['analysis'] as Map<String, dynamic>;
              foodItems = _parseFoodItemsFromAnalysis(analysisData);
              
              print('✅ Analysis completed via Firebase Cloud Function');
              print('📊 Remaining HOMs: ${response['remainingHoms']}');
              print('🍽️ Food items identified: ${foodItems?.length ?? 0}');
            } else {
              print('⚠️ No analysis in response. Response keys: ${response.keys.toList()}');
              throw Exception('No analysis data received from server');
            }
          } catch (cloudFunctionError) {
            // Cloud Functions returned "unauthenticated" - ID token was not sent
            if (cloudFunctionError.toString().contains('unauthenticated')) {
              print('⚠️ Cloud Function rejected auth - ID token may not be cached');
              print('   Attempting to recover: sign out and sign in again...');
              
              try {
                // Sign out to clear any corrupted auth state
                await firebaseService.signOut();
                print('✅ Signed out');
                
                // Sign in again to get a fresh ID token
                // This may trigger Pigeon error again
                try {
                  await firebaseService.signInAnonymously();
                  print('✅ Signed in again');
                } catch (signInError) {
                  // Even if Pigeon error occurs, check if auth succeeded
                  if (signInError.toString().contains('PigeonUserDetails')) {
                    print('⚠️ Pigeon error during recovery sign-in');
                    await Future.delayed(Duration(seconds: 2));
                    if (firebaseService.currentUser != null) {
                      print('✅ User authenticated despite error: ${firebaseService.currentUser?.uid}');
                      // Continue with retry - don't throw
                    } else {
                      throw signInError;
                    }
                  } else {
                    throw signInError;
                  }
                }
                
                // Retry the Cloud Function call
                print('🔄 Retrying Cloud Function call...');
                final retryResponse = await firebaseService.processMeal(
                  imageBase64: base64Image,
                  userPreferences: widget.dishName != null 
                    ? {'dishName': widget.dishName}
                    : null,
                );
                
                if (retryResponse['analysis'] != null) {
                  final analysisData = retryResponse['analysis'] as Map<String, dynamic>;
                  foodItems = _parseFoodItemsFromAnalysis(analysisData);
                  print('✅ Analysis completed via Firebase Cloud Function (retry)');
                  print('📊 Remaining HOMs: ${retryResponse['remainingHoms']}');
                } else {
                  throw Exception('No analysis data received from server');
                }
              } catch (recoveryError) {
                print('❌ Recovery failed: $recoveryError');
                rethrow;
              }
            } else {
              rethrow;
            }
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
    
    // Handle rawAnalysis (stringified JSON from Cloud Function)
    Map<String, dynamic> actualAnalysis = analysisData;
    if (analysisData['rawAnalysis'] is String) {
      try {
        final parsed = jsonDecode(analysisData['rawAnalysis'] as String);
        if (parsed is Map<String, dynamic>) {
          actualAnalysis = parsed;
          print('✅ Parsed rawAnalysis from string');
        }
      } catch (e) {
        print('⚠️ Failed to parse rawAnalysis: $e');
      }
    }
    
    // Handle response from Cloud Function
    if (actualAnalysis['foods'] is List) {
      final foods = actualAnalysis['foods'] as List<dynamic>;
      
      for (int i = 0; i < foods.length; i++) {
        // Foods can be strings or objects
        Map<String, dynamic> foodData;
        if (foods[i] is String) {
          // Simple string food name - create basic food item
          foodData = {
            'name': foods[i] as String,
            'description': '',
            'estimatedWeight': 100.0,
            'confidence': 0.7,
          };
        } else {
          foodData = foods[i] as Map<String, dynamic>;
        }
        
        // Extract nutrition data
        NutritionData nutrition;
        if (foodData['nutrition'] != null) {
          nutrition = NutritionData.fromMap(foodData['nutrition'] as Map<String, dynamic>);
        } else {
          // Use macros from top-level response (shared across all foods) or from food item
          Map<String, dynamic>? macrosData;
          double? totalCalories;
          
          if (foodData['macros'] != null) {
            macrosData = foodData['macros'] as Map<String, dynamic>;
            totalCalories = (foodData['calories'] as num?)?.toDouble();
          } else if (actualAnalysis['macros'] != null) {
            // Use top-level macros - divide by number of foods
            macrosData = actualAnalysis['macros'] as Map<String, dynamic>;
            final foodCount = foods.length;
            final topCalories = (actualAnalysis['calories'] as num?)?.toDouble() ?? 0.0;
            totalCalories = topCalories / foodCount;
          }
          
          if (macrosData != null) {
            nutrition = NutritionData(
              calories: totalCalories ?? 0.0,
              protein: (macrosData['protein'] as num?)?.toDouble() ?? 0.0,
              carbs: (macrosData['carbs'] as num?)?.toDouble() ?? 0.0,
              fat: (macrosData['fats'] as num?)?.toDouble() ?? 0.0,
            );
          } else {
            nutrition = NutritionData.zero;
          }
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
    print('📋 Error translation for: $error');
    
    if (error.contains('operation-not-allowed')) {
      return 'Anonymous sign-in is not enabled. Please contact support to set up authentication.';
    } else if (error.contains('401') || error.contains('unauthorized') || error.contains('Unauthorized')) {
      return 'Authorization failed. Please make sure you\'re signed in.';
    } else if (error.contains('429') || error.contains('quota')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    } else if (error.contains('network') || error.contains('connection') || error.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('timeout') || error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('Unable to identify') || error.contains('failed to analyze')) {
      return 'Could not analyze this image. Please try a clearer photo of your meal.';
    } else if (error.contains('not authenticated') || error.contains('sign in') || error.contains('Sign in')) {
      return 'Please sign in to use meal analysis.';
    } else if (error.contains('Anonymous') || error.contains('administrators only')) {
      return 'Sign-in is required. Please enable authentication in settings or contact support.';
    }
    
    // For unhandled errors, show generic message but log the actual error
    print('⚠️ Unhandled error in analysis: $error');
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