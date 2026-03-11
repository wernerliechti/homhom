import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'meal_detail_screen.dart' show FoodItemNutrientDisplay;

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

  // Track which items are in edit mode
  Map<String, bool> _itemEditMode = {};

  @override
  void initState() {
    super.initState();
    _editableFoodItems = List.from(widget.foodItems);
    _initializeEditMode();
    _calculateTotalNutrition();
  }

  void _initializeEditMode() {
    for (var item in _editableFoodItems) {
      _itemEditMode[item.id] = false;
    }
  }

  void _calculateTotalNutrition() {
    _totalNutrition = _editableFoodItems
        .map((item) => item.nutrition)
        .fold(NutritionData.zero, (total, nutrition) => total + nutrition);
  }

  void _updateFoodItem(FoodItem updatedItem) {
    setState(() {
      final index = _editableFoodItems.indexWhere((f) => f.id == updatedItem.id);
      if (index >= 0) {
        _editableFoodItems[index] = updatedItem;
        _calculateTotalNutrition();
      }
    });
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
            'Tap to edit portions or macros',
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
                'Meal Total',
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
              Expanded(
                child: _buildReadOnlyNutrientCard(
                  'Calories',
                  _totalNutrition.calories.toInt().toString(),
                  AppTheme.calories,
                  'cal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReadOnlyNutrientCard(
                  'Protein',
                  _totalNutrition.protein.toStringAsFixed(1),
                  AppTheme.protein,
                  'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyNutrientCard(
                  'Carbs',
                  _totalNutrition.carbs.toStringAsFixed(1),
                  AppTheme.carbs,
                  'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReadOnlyNutrientCard(
                  'Fat',
                  _totalNutrition.fat.toStringAsFixed(1),
                  AppTheme.fat,
                  'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReadOnlyNutrientCard(
            'Fiber',
            (_totalNutrition.fiber ?? 0).toStringAsFixed(1),
            AppTheme.fiber,
            'g',
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNutrientCard(
    String label,
    String value,
    Color color,
    String unit, {
    bool fullWidth = false,
  }) {
    return Container(
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
                value,
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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fullWidth ? 14 : 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          ..._editableFoodItems.asMap().entries.map((entry) {
            final index = entry.key;
            final food = entry.value;
            final isEditing = _itemEditMode[food.id] ?? false;

            return Column(
              children: [
                if (isEditing)
                  _buildFoodItemEditor(food)
                else
                  _buildFoodItemDisplay(food, index),
                if (index < _editableFoodItems.length - 1) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFoodItemDisplay(FoodItem food, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: confidence dot, food info, nutrients
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(food.confidence),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.portionDescription} • ${food.confidenceText} confidence',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (food.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        food.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FoodItemNutrientDisplay(nutrition: food.nutrition),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom row: weight controls and edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Edit button (top-left)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _itemEditMode[food.id] = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Weight controls: - button, weight, + button
              Row(
                children: [
                  // Minus button (enlarged)
                  Material(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        final newWeight = (food.estimatedWeight - 10).clamp(10, 10000).toDouble();
                        _updateFoodItemWeight(food.id, newWeight);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.remove, size: 24, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Weight display
                  Text(
                    '${food.estimatedWeight.toStringAsFixed(0)} g',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Plus button (enlarged)
                  Material(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        final newWeight = (food.estimatedWeight + 10).clamp(10, 10000).toDouble();
                        _updateFoodItemWeight(food.id, newWeight);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.add, size: 24, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateFoodItemWeight(String foodId, double newWeight) {
    setState(() {
      final index = _editableFoodItems.indexWhere((f) => f.id == foodId);
      if (index >= 0) {
        final food = _editableFoodItems[index];
        // Update weight and recalculate nutrition proportionally
        final newNutrition = food.getNutritionForWeight(newWeight);
        _editableFoodItems[index] = food.copyWith(
          estimatedWeight: newWeight,
          nutrition: newNutrition,
        );
        _calculateTotalNutrition();
      }
    });
  }

  Widget _buildFoodItemEditor(FoodItem food) {
    return _FoodItemEditWidget(
      foodItem: food,
      onUpdate: (updatedItem) {
        _updateFoodItem(updatedItem);
        setState(() {
          _itemEditMode[food.id] = false;
        });
      },
      onCancel: () {
        setState(() {
          _itemEditMode[food.id] = false;
        });
      },
    );
  }

  Widget _buildLargeNutrientTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
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

  Future<void> _saveMeal() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NutritionProvider>();

      // Save meal with edited food items
      await provider.saveMealWithAnalysis(
        widget.imagePath,
        _editableFoodItems,
        plateDiameter: widget.plateDiameter,
        dishWeight: widget.dishWeight,
        analysisMetadata: {
          'analyzedAt': DateTime.now().toIso8601String(),
          'originalTotal': widget.foodItems
              .map((f) => f.nutrition)
              .fold(NutritionData.zero, (total, n) => total + n)
              .toMap(),
          'editedTotal': _totalNutrition.toMap(),
          'confidence': widget.foodItems.isNotEmpty
              ? widget.foodItems.map((f) => f.confidence).reduce((a, b) => a + b) / widget.foodItems.length
              : 0.0,
        },
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true); // Return success

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Meal saved successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
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
            duration: const Duration(seconds: 2),
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.success;
    if (confidence >= 0.6) return AppTheme.secondary;
    if (confidence >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }
}

/// Separate widget for editing individual food items
class _FoodItemEditWidget extends StatefulWidget {
  final FoodItem foodItem;
  final Function(FoodItem) onUpdate;
  final VoidCallback onCancel;

  const _FoodItemEditWidget({
    required this.foodItem,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_FoodItemEditWidget> createState() => _FoodItemEditWidgetState();
}

class _FoodItemEditWidgetState extends State<_FoodItemEditWidget> {
  late TextEditingController _weightController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.foodItem.estimatedWeight.toStringAsFixed(1));
    _caloriesController = TextEditingController(text: widget.foodItem.nutrition.calories.toStringAsFixed(0));
    _proteinController = TextEditingController(text: widget.foodItem.nutrition.protein.toStringAsFixed(1));
    _carbsController = TextEditingController(text: widget.foodItem.nutrition.carbs.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.foodItem.nutrition.fat.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit: ${widget.foodItem.name}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildEditField('Weight', _weightController, 'g'),
          const SizedBox(height: 12),
          _buildEditField('Calories', _caloriesController, 'kcal'),
          const SizedBox(height: 12),
          _buildEditField('Protein', _proteinController, 'g'),
          const SizedBox(height: 12),
          _buildEditField('Carbs', _carbsController, 'g'),
          const SizedBox(height: 12),
          _buildEditField('Fat', _fatController, 'g'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
          ],
        ),
      ],
    );
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    final calories = double.tryParse(_caloriesController.text);
    final protein = double.tryParse(_proteinController.text);
    final carbs = double.tryParse(_carbsController.text);
    final fat = double.tryParse(_fatController.text);

    if (weight == null || weight <= 0 || calories == null || protein == null || carbs == null || fat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields with valid numbers'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updatedNutrition = NutritionData(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: widget.foodItem.nutrition.fiber,
      sugar: widget.foodItem.nutrition.sugar,
      sodium: widget.foodItem.nutrition.sodium,
      vitaminC: widget.foodItem.nutrition.vitaminC,
      calcium: widget.foodItem.nutrition.calcium,
      iron: widget.foodItem.nutrition.iron,
    );

    final updatedItem = widget.foodItem.copyWith(
      estimatedWeight: weight,
      nutrition: updatedNutrition,
    );

    widget.onUpdate(updatedItem);
  }
}
