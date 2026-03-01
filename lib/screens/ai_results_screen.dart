import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';

class AIResultsScreen extends StatefulWidget {
  final String imagePath;
  final List<FoodItem> foodItems;
  final double? plateDiameter;
  final double? dishWeight;

  const AIResultsScreen({
    super.key,
    required this.imagePath,
    required this.foodItems,
    this.plateDiameter,
    this.dishWeight,
  });

  @override
  State<AIResultsScreen> createState() => _AIResultsScreenState();
}

class _AIResultsScreenState extends State<AIResultsScreen> {
  late List<FoodItem> _editableFoodItems;
  late NutritionData _totalNutrition;
  bool _isSaving = false;

  // Controllers for nutrition editing
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;

  @override
  void initState() {
    super.initState();
    _editableFoodItems = List.from(widget.foodItems);
    _calculateTotalNutrition();
    _initializeControllers();
  }

  void _calculateTotalNutrition() {
    _totalNutrition = _editableFoodItems
        .map((item) => item.nutrition)
        .fold(NutritionData.zero, (total, nutrition) => total + nutrition);
  }

  void _initializeControllers() {
    _caloriesController = TextEditingController(text: _totalNutrition.calories.toStringAsFixed(0));
    _proteinController = TextEditingController(text: _totalNutrition.protein.toStringAsFixed(1));
    _carbsController = TextEditingController(text: _totalNutrition.carbs.toStringAsFixed(1));
    _fatController = TextEditingController(text: _totalNutrition.fat.toStringAsFixed(1));
    _fiberController = TextEditingController(text: (_totalNutrition.fiber ?? 0).toStringAsFixed(1));

    // Listen for changes to update total
    _caloriesController.addListener(_onNutritionChanged);
    _proteinController.addListener(_onNutritionChanged);
    _carbsController.addListener(_onNutritionChanged);
    _fatController.addListener(_onNutritionChanged);
    _fiberController.addListener(_onNutritionChanged);
  }

  void _onNutritionChanged() {
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final fiber = double.tryParse(_fiberController.text) ?? 0;

    setState(() {
      _totalNutrition = NutritionData(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
      );
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildPhotoPreview(),
            const SizedBox(height: 24),
            _buildNutritionSummary(),
            const SizedBox(height: 24),
            _buildIdentifiedFoods(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppTheme.success,
          ),
          const SizedBox(height: 12),
          const Text(
            'Analysis Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${_editableFoodItems.length} food item${_editableFoodItems.length == 1 ? '' : 's'} • '
            'Tap any value to edit',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Your Meal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                      child: Icon(Icons.error, color: AppTheme.error, size: 32),
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

  Widget _buildNutritionSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Nutrition Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main macros in a grid
          Row(
            children: [
              Expanded(child: _buildEditableNutrientCard(
                'Calories',
                _caloriesController,
                AppTheme.calories,
                'cal',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildEditableNutrientCard(
                'Protein',
                _proteinController,
                AppTheme.protein,
                'g',
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildEditableNutrientCard(
                'Carbs',
                _carbsController,
                AppTheme.carbs,
                'g',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildEditableNutrientCard(
                'Fat',
                _fatController,
                AppTheme.fat,
                'g',
              )),
            ],
          ),
          const SizedBox(height: 12),
          _buildEditableNutrientCard(
            'Fiber',
            _fiberController,
            AppTheme.fiber,
            'g',
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableNutrientCard(
    String label,
    TextEditingController controller,
    Color color,
    String unit, {
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: () => _showEditDialog(label, controller, unit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Text(
                  controller.text,
                  style: TextStyle(
                    fontSize: fullWidth ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: fullWidth ? 12 : 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                if (!fullWidth) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: color.withAlpha(150),
                  ),
                ],
              ],
            ),
            if (!fullWidth) const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: fullWidth ? 14 : 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (fullWidth) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.edit,
                size: 16,
                color: color.withAlpha(150),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifiedFoods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Identified Foods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._editableFoodItems.map((food) {
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(food.confidence),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${food.portionDescription} • ${food.confidenceText} confidence',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (food.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            food.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${food.nutrition.calories.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.calories,
                        ),
                      ),
                      const Text(
                        'cal',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveMeal,
          icon: _isSaving 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, size: 20),
          label: Text(_isSaving ? 'Saving Meal...' : 'Save to Timeline'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Discard Results'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String label, TextEditingController controller, String unit) {
    final tempController = TextEditingController(text: controller.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tempController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                suffixText: unit,
                border: const OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.text = tempController.text;
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NutritionProvider>();
      
      // Create updated food items with adjusted nutrition
      final adjustedFoodItems = _adjustFoodItemNutrition();
      
      // Create meal with the analysis
      final mealType = Meal.getMealTypeFromTime(DateTime.now());
      final meal = Meal(
        timestamp: DateTime.now(),
        type: mealType,
        imagePath: widget.imagePath,
        foodItems: adjustedFoodItems,
        plateDiameter: widget.plateDiameter,
        dishWeight: widget.dishWeight,
        analysisMetadata: {
          'analyzedAt': DateTime.now().toIso8601String(),
          'originalTotal': widget.foodItems
              .map((f) => f.nutrition)
              .fold(NutritionData.zero, (total, n) => total + n)
              .toMap(),
          'editedTotal': _totalNutrition.toMap(),
        },
      );

      await provider.updateMeal(meal);
      await provider.refresh();

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true); // Return success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Meal saved successfully!'),
            backgroundColor: AppTheme.success,
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
          _isSaving = false;
        });
      }
    }
  }

  List<FoodItem> _adjustFoodItemNutrition() {
    // If user edited the total nutrition, proportionally adjust each food item
    final originalTotal = _editableFoodItems
        .map((f) => f.nutrition)
        .fold(NutritionData.zero, (total, n) => total + n);
    
    if (originalTotal.calories == 0) return _editableFoodItems;
    
    final calorieRatio = _totalNutrition.calories / originalTotal.calories;
    final proteinRatio = originalTotal.protein > 0 ? _totalNutrition.protein / originalTotal.protein : 1.0;
    final carbsRatio = originalTotal.carbs > 0 ? _totalNutrition.carbs / originalTotal.carbs : 1.0;
    final fatRatio = originalTotal.fat > 0 ? _totalNutrition.fat / originalTotal.fat : 1.0;
    
    return _editableFoodItems.map((food) {
      final adjustedNutrition = NutritionData(
        calories: food.nutrition.calories * calorieRatio,
        protein: food.nutrition.protein * proteinRatio,
        carbs: food.nutrition.carbs * carbsRatio,
        fat: food.nutrition.fat * fatRatio,
        fiber: food.nutrition.fiber,
      );
      
      return food.copyWith(nutrition: adjustedNutrition);
    }).toList();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.success;
    if (confidence >= 0.6) return AppTheme.secondary;
    if (confidence >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }
}