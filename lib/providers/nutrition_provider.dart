import 'package:flutter/foundation.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_data.dart';
import '../services/database_service.dart';
import '../services/ai_nutrition_service.dart';

class NutritionProvider with ChangeNotifier {
  final DatabaseService _database = DatabaseService();
  final AINutritionService _aiService = AINutritionService();

  // Current state
  List<Meal> _todayMeals = [];
  NutritionGoals? _goals;
  NutritionData _todayNutrition = NutritionData.zero;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isAnalyzing = false;

  // Getters
  List<Meal> get todayMeals => _todayMeals;
  NutritionGoals? get goals => _goals;
  NutritionData get todayNutrition => _todayNutrition;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasGoals => _goals != null;

  // Calculated values
  NutritionGoals get remainingNutrition {
    if (_goals == null) return NutritionGoals.balanced2000();
    return _goals!.remaining(_todayNutrition);
  }

  double get calorieProgress => _goals?.calorieProgress(_todayNutrition.calories) ?? 0.0;
  double get proteinProgress => _goals?.proteinProgress(_todayNutrition.protein) ?? 0.0;
  double get carbsProgress => _goals?.carbsProgress(_todayNutrition.carbs) ?? 0.0;
  double get fatProgress => _goals?.fatProgress(_todayNutrition.fat) ?? 0.0;

  // Initialization
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadGoals();
      await _loadTodayData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGoals() async {
    _goals = await _database.getNutritionGoals();
    if (_goals == null) {
      // Set default goals
      _goals = NutritionGoals.balanced2000();
      await _database.setNutritionGoals(_goals!);
    }
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    await _loadMealsForDate(_selectedDate);
  }

  Future<void> _loadMealsForDate(DateTime date) async {
    _todayMeals = await _database.getMealsByDate(date);
    _todayNutrition = await _database.getDayNutrition(date);
    notifyListeners();
  }

  // Date navigation
  Future<void> selectDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (normalizedDate == _selectedDate) return;

    _selectedDate = normalizedDate;
    await _loadMealsForDate(_selectedDate);
  }

  Future<void> goToPreviousDay() async {
    await selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> goToNextDay() async {
    await selectDate(_selectedDate.add(const Duration(days: 1)));
  }

  Future<void> goToToday() async {
    final today = DateTime.now();
    await selectDate(DateTime(today.year, today.month, today.day));
  }

  bool get isToday {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return _selectedDate == todayNormalized;
  }

  // Meal operations
  Future<Meal> addMealPhoto(
    String imagePath, {
    double? plateDiameter,
    double? dishWeight,
  }) async {
    final mealType = Meal.getMealTypeFromTime(DateTime.now());
    
    final meal = Meal(
      timestamp: DateTime.now(),
      type: mealType,
      imagePath: imagePath,
      plateDiameter: plateDiameter,
      dishWeight: dishWeight,
    );

    await _database.insertMeal(meal);
    await _loadMealsForDate(_selectedDate);

    // Start AI analysis in background
    _analyzeMealInBackground(meal);

    return meal;
  }

  Future<void> _analyzeMealInBackground(Meal meal) async {
    if (meal.imagePath == null) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final foodItems = await _aiService.analyzeMealPhoto(
        meal.imagePath!,
        plateDiameter: meal.plateDiameter,
        dishWeight: meal.dishWeight,
      );

      final updatedMeal = meal.copyWith(
        foodItems: foodItems,
        analysisMetadata: {
          'analyzedAt': DateTime.now().toIso8601String(),
          'confidence': foodItems.isNotEmpty 
              ? foodItems.map((f) => f.confidence).reduce((a, b) => a + b) / foodItems.length
              : 0.0,
        },
      );

      await _database.updateMeal(updatedMeal);
      await _loadMealsForDate(_selectedDate);
    } catch (e) {
      print('Analysis failed: $e');
      // Could show error notification here
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> updateMeal(Meal meal) async {
    await _database.updateMeal(meal);
    await _loadMealsForDate(_selectedDate);
  }

  Future<Meal> saveMealWithAnalysis(
    String imagePath,
    List<FoodItem> foodItems, {
    double? plateDiameter,
    double? dishWeight,
    Map<String, dynamic>? analysisMetadata,
  }) async {
    final mealType = Meal.getMealTypeFromTime(DateTime.now());
    
    final meal = Meal(
      timestamp: DateTime.now(),
      type: mealType,
      imagePath: imagePath,
      foodItems: foodItems,
      plateDiameter: plateDiameter,
      dishWeight: dishWeight,
      analysisMetadata: analysisMetadata ?? {
        'analyzedAt': DateTime.now().toIso8601String(),
      },
    );

    await _database.insertMeal(meal);
    await _loadMealsForDate(_selectedDate);
    
    return meal;
  }

  Future<void> deleteMeal(String mealId) async {
    await _database.deleteMeal(mealId);
    await _loadMealsForDate(_selectedDate);
  }

  // Goals management
  Future<void> updateGoals(NutritionGoals newGoals) async {
    _goals = newGoals;
    await _database.setNutritionGoals(newGoals);
    notifyListeners();
  }

  // AI service management
  Future<bool> isAIConfigured() async {
    return await _aiService.isConfigured();
  }

  Future<void> setOpenAIKey(String key) async {
    await _aiService.setOpenAIKey(key);
    notifyListeners();
  }

  Future<String?> getOpenAIKey() async {
    return await _aiService.getOpenAIKey();
  }

  AINutritionService get aiService => _aiService;

  // Statistics
  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    return await _database.getRecentMeals(limit: limit);
  }

  Future<Map<String, int>> getMealTypeCount(DateTime date) async {
    return await _database.getMealTypeCount(date);
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadMealsForDate(_selectedDate);
  }
}