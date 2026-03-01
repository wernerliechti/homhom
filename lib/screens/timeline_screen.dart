import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class TimelineScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const TimelineScreen({super.key, this.onNavigateToTab});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh timeline when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final meals = provider.todayMeals;
          
          if (meals.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: CustomScrollView(
              slivers: [
                _buildDateHeader(provider),
                _buildMealsList(meals, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No meals today',
              style: AppTheme.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Start by taking a photo of your meal!\nTap the camera tab below to get started.',
              style: AppTheme.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to camera tab
                widget.onNavigateToTab?.call(2);
              },
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Add First Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(NutritionProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: provider.goToPreviousDay,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous day',
                ),
                Column(
                  children: [
                    Text(
                      _formatDate(provider.selectedDate),
                      style: AppTheme.heading3,
                      textAlign: TextAlign.center,
                    ),
                    if (!provider.isToday)
                      TextButton(
                        onPressed: provider.goToToday,
                        child: const Text('Go to today'),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: provider.goToNextDay,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next day',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDaySummary(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(NutritionProvider provider) {
    final nutrition = provider.todayNutrition;
    final goals = provider.goals;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNutrientSummary(
          'Calories',
          nutrition.calories,
          goals?.calories ?? 2000,
          AppTheme.calories,
        ),
        _buildNutrientSummary(
          'Protein',
          nutrition.protein,
          goals?.protein ?? 150,
          AppTheme.protein,
          unit: 'g',
        ),
        _buildNutrientSummary(
          'Carbs',
          nutrition.carbs,
          goals?.carbs ?? 250,
          AppTheme.carbs,
          unit: 'g',
        ),
        _buildNutrientSummary(
          'Fat',
          nutrition.fat,
          goals?.fat ?? 65,
          AppTheme.fat,
          unit: 'g',
        ),
      ],
    );
  }

  Widget _buildNutrientSummary(
    String label,
    double current,
    double goal,
    Color color, {
    String unit = 'cal',
  }) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: color.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              current.toInt().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(List<Meal> meals, NutritionProvider provider) {
    // Group meals by type for better organization
    final mealsByType = <MealType, List<Meal>>{};
    for (final meal in meals) {
      mealsByType.putIfAbsent(meal.type, () => []).add(meal);
    }

    // Sort meal types by typical eating time
    final orderedTypes = [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack];
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final typeIndex = index ~/ 100; // Group by type
          final mealIndex = index % 100;  // Meal within type
          
          if (typeIndex >= orderedTypes.length) return null;
          
          final type = orderedTypes[typeIndex];
          final typeMeals = mealsByType[type];
          
          if (typeMeals == null || typeMeals.isEmpty) {
            // Skip empty types, but need to account for indexing
            return const SizedBox.shrink();
          }
          
          if (mealIndex == 0) {
            // Type header
            return _buildMealTypeHeader(type);
          } else if (mealIndex <= typeMeals.length) {
            // Meal item
            final meal = typeMeals[mealIndex - 1];
            return _buildMealCard(meal, provider);
          }
          
          return null;
        },
        childCount: meals.length + 10, // Generous count for headers
      ),
    );
  }

  Widget _buildMealTypeHeader(MealType type) {
    final typeInfo = _getMealTypeInfo(type);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(
            typeInfo['icon'] as IconData,
            size: 20,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            typeInfo['name'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.divider,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMealTypeInfo(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return {'name': 'Breakfast', 'icon': Icons.free_breakfast};
      case MealType.lunch:
        return {'name': 'Lunch', 'icon': Icons.lunch_dining};
      case MealType.dinner:
        return {'name': 'Dinner', 'icon': Icons.dinner_dining};
      case MealType.snack:
        return {'name': 'Snacks', 'icon': Icons.local_cafe};
    }
  }

  Widget _buildMealCard(Meal meal, NutritionProvider provider) {
    final isAnalyzing = provider.isAnalyzing;
    final hasAnalysis = meal.foodItems.isNotEmpty;
    final nutrition = meal.totalNutrition;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showMealDetails(meal),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo
                _buildMealPhoto(meal),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time and analysis status
                      Row(
                        children: [
                          Text(
                            _formatTime(meal.timestamp),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (isAnalyzing)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Analyzing...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            )
                          else if (hasAnalysis)
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppTheme.success,
                            )
                          else
                            const Icon(
                              Icons.photo,
                              size: 16,
                              color: AppTheme.textTertiary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Nutrition summary or food items
                      if (hasAnalysis) ...[
                        Text(
                          '${nutrition.calories.toInt()} cal • '
                          '${nutrition.protein.toInt()}g protein • '
                          '${nutrition.carbs.toInt()}g carbs',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meal.foodItems.map((f) => f.name).join(', '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const Text(
                          'Photo saved - tap to add nutrition details',
                          style: TextStyle(
                            fontSize: 13,
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
          ),
        ),
      ),
    );
  }

  Widget _buildMealPhoto(Meal meal) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.surfaceVariant,
      ),
      child: meal.imagePath != null 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(meal.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: AppTheme.textTertiary,
                  );
                },
              ),
            )
          : const Icon(
              Icons.restaurant,
              color: AppTheme.textTertiary,
            ),
    );
  }

  void _showMealDetails(Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MealDetailsSheet(meal: meal),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (_isSameDay(date, today)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
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
}

class _MealDetailsSheet extends StatelessWidget {
  final Meal meal;

  const _MealDetailsSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    final nutrition = meal.totalNutrition;
    final hasAnalysis = meal.foodItems.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                _formatMealType(meal.type),
                style: AppTheme.heading2,
              ),
              const Spacer(),
              Text(
                _formatTime(meal.timestamp),
                style: AppTheme.body2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Photo
          if (meal.imagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surfaceVariant,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(meal.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          if (hasAnalysis) ...[
            // Nutrition summary
            const Text(
              'Nutrition Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutrientDetail('Calories', nutrition.calories, AppTheme.calories),
                _buildNutrientDetail('Protein', nutrition.protein, AppTheme.protein, 'g'),
                _buildNutrientDetail('Carbs', nutrition.carbs, AppTheme.carbs, 'g'),
                _buildNutrientDetail('Fat', nutrition.fat, AppTheme.fat, 'g'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Food items
            const Text(
              'Identified Foods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            ...meal.foodItems.map((food) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          food.portionDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${food.nutrition.calories.toInt()} cal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            // No analysis available
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI analysis not available. Configure your OpenAI API key in Settings to enable food recognition.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientDetail(String label, double value, Color color, [String unit = 'cal']) {
    return Column(
      children: [
        Text(
          value.toInt().toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  String _formatMealType(MealType type) {
    switch (type) {
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

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}