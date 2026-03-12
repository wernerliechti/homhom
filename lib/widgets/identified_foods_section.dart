import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../theme/app_theme.dart';

/// Reusable component for displaying "Identified Foods" section
/// Used in both AI Results and Meal Detail screens
class IdentifiedFoodsSection extends StatelessWidget {
  final List<FoodItem> foodItems;
  final Map<String, double> editedWeights; // foodItemId -> weight
  final Function(String foodId, double newWeight) onWeightChanged;
  final Function(FoodItem food) onEditPressed;
  final EdgeInsets padding;

  const IdentifiedFoodsSection({
    required this.foodItems,
    required this.editedWeights,
    required this.onWeightChanged,
    required this.onEditPressed,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
          
          // Food items list
          ..._buildFoodItemsList(context),
        ],
      ),
    );
  }

  List<Widget> _buildFoodItemsList(BuildContext context) {
    return foodItems.asMap().entries.map((entry) {
      final index = entry.key;
      final food = entry.value;
      final editedWeight = editedWeights[food.id] ?? food.estimatedWeight;
      final editedNutrition = food.getNutritionForWeight(editedWeight);

      return Column(
        children: [
          FoodItemCard(
            food: food,
            editedWeight: editedWeight,
            editedNutrition: editedNutrition,
            onWeightChanged: (newWeight) => onWeightChanged(food.id, newWeight),
            onEditPressed: () => onEditPressed(food),
          ),
          if (index < foodItems.length - 1) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
        ],
      );
    }).toList();
  }
}

/// Reusable food item card with 2x2 macro grid layout
class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  final double editedWeight;
  final NutritionData editedNutrition;
  final Function(double newWeight) onWeightChanged;
  final VoidCallback onEditPressed;

  const FoodItemCard({
    required this.food,
    required this.editedWeight,
    required this.editedNutrition,
    required this.onWeightChanged,
    required this.onEditPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Info + Macro Grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence dot + Food info (left column)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence dot + food name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4, right: 12),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(food.confidence),
                          shape: BoxShape.circle,
                        ),
                      ),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // 2x2 Macro Grid (right column)
            _buildMacroGrid(),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Row 2: Edit button + Weight controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Edit button (left)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditPressed,
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
            
            // Weight controls (right)
            Row(
              children: [
                // Minus button
                Material(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      final newWeight = (editedWeight - 10).clamp(10, 10000).toDouble();
                      onWeightChanged(newWeight);
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
                  '${editedWeight.toStringAsFixed(0)} g',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Plus button
                Material(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      final newWeight = (editedWeight + 10).clamp(10, 10000).toDouble();
                      onWeightChanged(newWeight);
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
    );
  }

  /// Build 2x2 macro grid (Cal, P / C, F)
  Widget _buildMacroGrid() {
    return Column(
      children: [
        // Top row: Cal, P
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMacroTag('Cal', editedNutrition.calories.toInt().toString(), AppTheme.calories),
            const SizedBox(width: 8),
            _buildMacroTag('P', editedNutrition.protein.toStringAsFixed(1), AppTheme.protein),
          ],
        ),
        const SizedBox(height: 8),
        
        // Bottom row: C, F
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMacroTag('C', editedNutrition.carbs.toStringAsFixed(1), AppTheme.carbs),
            const SizedBox(width: 8),
            _buildMacroTag('F', editedNutrition.fat.toStringAsFixed(1), AppTheme.fat),
          ],
        ),
      ],
    );
  }

  /// Build individual macro tag
  Widget _buildMacroTag(String label, String value, Color color) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.success;
    if (confidence >= 0.6) return AppTheme.secondary;
    if (confidence >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }
}
