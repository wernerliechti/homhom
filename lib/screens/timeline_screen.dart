import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/hom_provider.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';
import '../widgets/hom_balance_indicator.dart';
import 'new_settings_screen.dart';
import 'meal_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAddMeal;

  const TimelineScreen({super.key, this.onNavigateToAddMeal});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _showRemaining = false; // Toggle state for consumed vs remaining view

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
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Consumer<HomProvider>(
          builder: (context, homProvider, child) {
            // Debug: Always show something to verify provider is working
            if (!homProvider.isInitialized) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HOMs: Loading...',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              );
            }
            return const HomBalanceIndicator(compact: true);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewSettingsScreen(),
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

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: CustomScrollView(
              slivers: [
                _buildDateHeader(provider),
                _buildMealsList(provider),
              ],
            ),
          );
        },
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
    final remaining = (goal - current).clamp(0.0, goal);
    final remainingProgress = goal > 0 ? (remaining / goal).clamp(0.0, 1.0) : 0.0;
    
    // Calculate display values based on toggle state
    final displayValue = _showRemaining ? remaining.toInt() : current.toInt();
    final displayProgress = _showRemaining ? remainingProgress : progress;
    final displayColor = _showRemaining ? color.withAlpha(100) : color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showRemaining = !_showRemaining;
        });
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: displayProgress,
                  strokeWidth: 4,
                  backgroundColor: color.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                ),
              ),
              Text(
                displayValue.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _showRemaining ? AppTheme.textSecondary : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
              if (_showRemaining) ...[
                const SizedBox(width: 2),
                Text(
                  'left',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textTertiary.withAlpha(150),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(NutritionProvider provider) {
    final meals = provider.todayMeals;

    if (meals.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final meal = meals[index];
            return _buildMealCard(meal);
          },
          childCount: meals.length,
        ),
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
                // Navigate to add meal
                widget.onNavigateToAddMeal?.call();
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add First Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final hasAnalysis = meal.foodItems.isNotEmpty;
    final nutrition = meal.totalNutrition;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(meal.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDeleteMeal(meal),
        onDismissed: (direction) => _deleteMeal(meal),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _openMealDetail(meal),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Photo thumbnail
                  _buildMealPhoto(meal),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with time and meal type
                        Row(
                          children: [
                            Icon(
                              _getMealTypeIcon(meal.type),
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getMealTypeDisplay(meal.type),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(meal.timestamp),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Analysis status and nutrition
                        if (hasAnalysis) ...[
                          Row(
                            children: [
                              Icon(
                                _isManualEntry(meal) ? Icons.edit_note : Icons.auto_awesome,
                                size: 14,
                                color: _isManualEntry(meal) ? AppTheme.secondary : AppTheme.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isManualEntry(meal)
                                    ? 'Manual Entry • ${meal.foodItems.length} food${meal.foodItems.length == 1 ? '' : 's'}'
                                    : 'AI Analyzed • ${meal.foodItems.length} food${meal.foodItems.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isManualEntry(meal) ? AppTheme.secondary : AppTheme.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${nutrition.calories.toInt()} cal • '
                            '${nutrition.protein.toInt()}g protein • '
                            '${nutrition.carbs.toInt()}g carbs • '
                            '${nutrition.fat.toInt()}g fat',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal.foodItems
                                    .take(3)
                                    .map((f) => f.name)
                                    .join(', ') +
                                (meal.foodItems.length > 3 ? '...' : ''),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.photo,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Photo only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tap to add nutrition details or analyze with AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Arrow to indicate clickable
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealPhoto(Meal meal) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surfaceVariant,
      ),
      child: meal.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(meal.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: AppTheme.textTertiary,
                    size: 24,
                  );
                },
              ),
            )
          : const Icon(
              Icons.restaurant,
              color: AppTheme.textTertiary,
              size: 24,
            ),
    );
  }

  void _openMealDetail(Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(meal: meal),
      ),
    );
  }

  String _getMealTypeDisplay(MealType type) {
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

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
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

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(date, today)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
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

  Future<bool?> _confirmDeleteMeal(Meal meal) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to delete this ${_getMealTypeDisplay(meal.type).toLowerCase()}?'),
            if (meal.foodItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'This meal contains ${meal.foodItems.length} identified food item${meal.foodItems.length == 1 ? '' : 's'} and nutrition data.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(Meal meal) async {
    try {
      final provider = context.read<NutritionProvider>();
      await provider.deleteMeal(meal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getMealTypeDisplay(meal.type)} deleted'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo not yet implemented'),
                    behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete meal: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _isManualEntry(Meal meal) {
    final entryMethod = meal.analysisMetadata?['entryMethod'] as String?;
    return entryMethod == 'manual';
  }
}
