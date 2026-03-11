import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;

  const MealDetailScreen({
    super.key,
    required this.meal,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late Meal _currentMeal;
  late NutritionData _totalNutrition;
  bool _isEditing = false;
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
    _currentMeal = widget.meal;
    _calculateTotalNutrition();
    _initializeControllers();
  }

  void _calculateTotalNutrition() {
    _totalNutrition = _currentMeal.totalNutrition;
  }

  void _initializeControllers() {
    _caloriesController = TextEditingController(text: _totalNutrition.calories.toStringAsFixed(0));
    _proteinController = TextEditingController(text: _totalNutrition.protein.toStringAsFixed(1));
    _carbsController = TextEditingController(text: _totalNutrition.carbs.toStringAsFixed(1));
    _fatController = TextEditingController(text: _totalNutrition.fat.toStringAsFixed(1));
    _fiberController = TextEditingController(text: (_totalNutrition.fiber ?? 0).toStringAsFixed(1));

    // Listen for changes
    _caloriesController.addListener(_onNutritionChanged);
    _proteinController.addListener(_onNutritionChanged);
    _carbsController.addListener(_onNutritionChanged);
    _fatController.addListener(_onNutritionChanged);
    _fiberController.addListener(_onNutritionChanged);
  }

  void _onNutritionChanged() {
    if (!_isEditing) return;

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
        title: Text(_getMealTypeDisplay()),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit meal',
            ),
          if (_isEditing)
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMealHeader(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildNutritionSection(),
            if (_currentMeal.foodItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildFoodItemsSection(),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 32),
              _buildEditingActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getMealTypeIcon(),
                size: 24,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMealTypeDisplay(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDateTime(_currentMeal.timestamp),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentMeal.foodItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isManualEntry() ? Icons.edit_note : Icons.auto_awesome,
                        size: 16,
                        color: _isManualEntry() ? AppTheme.secondary : AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isManualEntry() ? 'Manual Entry' : 'AI Analyzed',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isManualEntry() ? AppTheme.secondary : AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_currentMeal.plateDiameter != null || _currentMeal.dishWeight != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_currentMeal.plateDiameter != null) ...[
                  const Icon(Icons.circle_outlined, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentMeal.plateDiameter!.toStringAsFixed(1)}cm plate',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
                if (_currentMeal.plateDiameter != null && _currentMeal.dishWeight != null)
                  const Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                if (_currentMeal.dishWeight != null) ...[
                  const Icon(Icons.scale_outlined, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentMeal.dishWeight!.toStringAsFixed(0)}g total',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_currentMeal.imagePath == null) {
      return const SizedBox.shrink();
    }

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
                  'Meal Photo',
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
                File(_currentMeal.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: AppTheme.error, size: 32),
                          SizedBox(height: 8),
                          Text('Image not found'),
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

  Widget _buildNutritionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nutrition Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isEditing)
                const Text(
                  'Tap values to edit',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main macros
          Row(
            children: [
              Expanded(child: _buildNutrientCard(
                'Calories',
                _caloriesController,
                AppTheme.calories,
                'cal',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildNutrientCard(
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
              Expanded(child: _buildNutrientCard(
                'Carbs',
                _carbsController,
                AppTheme.carbs,
                'g',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildNutrientCard(
                'Fat',
                _fatController,
                AppTheme.fat,
                'g',
              )),
            ],
          ),
          const SizedBox(height: 12),
          _buildNutrientCard(
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

  Widget _buildNutrientCard(
    String label,
    TextEditingController controller,
    Color color,
    String unit, {
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: _isEditing ? () => _showEditDialog(label, controller, unit) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isEditing ? color.withAlpha(100) : color.withAlpha(50),
            width: _isEditing ? 2 : 1,
          ),
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
                if (_isEditing) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: fullWidth ? 16 : 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemsSection() {
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
          
          ..._currentMeal.foodItems.map((food) {
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

  Widget _buildEditingActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, size: 20),
          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _cancelEditing,
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Cancel Changes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    // Reset controllers to original values
    _calculateTotalNutrition();
    _caloriesController.text = _totalNutrition.calories.toStringAsFixed(0);
    _proteinController.text = _totalNutrition.protein.toStringAsFixed(1);
    _carbsController.text = _totalNutrition.carbs.toStringAsFixed(1);
    _fatController.text = _totalNutrition.fat.toStringAsFixed(1);
    _fiberController.text = (_totalNutrition.fiber ?? 0).toStringAsFixed(1);
    
    setState(() {
      _isEditing = false;
    });
  }

  void _showEditDialog(String label, TextEditingController controller, String unit) {
    final tempController = TextEditingController(text: controller.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
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

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NutritionProvider>();
      
      // Create updated food items with adjusted nutrition
      final adjustedFoodItems = _adjustFoodItemNutrition();
      
      // Update the meal
      final updatedMeal = _currentMeal.copyWith(
        foodItems: adjustedFoodItems,
        analysisMetadata: {
          ..._currentMeal.analysisMetadata ?? {},
          'lastEditedAt': DateTime.now().toIso8601String(),
          'editedTotal': _totalNutrition.toMap(),
        },
      );

      await provider.updateMeal(updatedMeal);
      
      if (mounted) {
        setState(() {
          _currentMeal = updatedMeal;
          _isEditing = false;
        });
        
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meal updated successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
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
    if (_currentMeal.foodItems.isEmpty) return [];
    
    final originalTotal = _currentMeal.totalNutrition;
    if (originalTotal.calories == 0) return _currentMeal.foodItems;
    
    final calorieRatio = _totalNutrition.calories / originalTotal.calories;
    final proteinRatio = originalTotal.protein > 0 ? _totalNutrition.protein / originalTotal.protein : 1.0;
    final carbsRatio = originalTotal.carbs > 0 ? _totalNutrition.carbs / originalTotal.carbs : 1.0;
    final fatRatio = originalTotal.fat > 0 ? _totalNutrition.fat / originalTotal.fat : 1.0;
    
    return _currentMeal.foodItems.map((food) {
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

  String _getMealTypeDisplay() {
    switch (_currentMeal.type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData _getMealTypeIcon() {
    switch (_currentMeal.type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.local_cafe;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final time = _formatTime(dateTime);
    final now = DateTime.now();
    
    if (_isSameDay(dateTime, now)) {
      return 'Today at $time';
    } else if (_isSameDay(dateTime, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday at $time';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day} at $time';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.success;
    if (confidence >= 0.6) return AppTheme.secondary;
    if (confidence >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }

  bool _isManualEntry() {
    final entryMethod = _currentMeal.analysisMetadata?['entryMethod'] as String?;
    return entryMethod == 'manual';
  }
}