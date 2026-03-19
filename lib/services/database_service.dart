import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_data.dart';
import '../models/goal_period.dart';
import '../models/nutrition_stats.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'homhom.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createGoalPeriodsTable(db);
        }
        if (oldVersion < 3) {
          await _addEndDateToGoalPeriods(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Meals table
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        type INTEGER NOT NULL,
        imagePath TEXT,
        foodItems TEXT NOT NULL,
        notes TEXT,
        plateDiameter REAL,
        dishWeight REAL,
        analysisMetadata TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Nutrition goals table
    await db.execute('''
      CREATE TABLE nutrition_goals (
        id INTEGER PRIMARY KEY,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL,
        sodium REAL,
        sugar REAL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Daily summaries for faster queries
    await db.execute('''
      CREATE TABLE daily_summaries (
        date TEXT PRIMARY KEY,
        totalCalories REAL NOT NULL,
        totalProtein REAL NOT NULL,
        totalCarbs REAL NOT NULL,
        totalFat REAL NOT NULL,
        mealCount INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Goal periods table
    await _createGoalPeriodsTable(db);

    // Indexes for faster queries
    await db.execute('CREATE INDEX idx_meals_timestamp ON meals(timestamp DESC)');
    await db.execute('CREATE INDEX idx_meals_type ON meals(type)');
    await db.execute('CREATE INDEX idx_daily_summaries_date ON daily_summaries(date DESC)');
    await db.execute('CREATE INDEX idx_goal_periods_start_date ON goal_periods(startDate DESC)');
  }

  Future<void> _createGoalPeriodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE goal_periods (
        id TEXT PRIMARY KEY,
        startDate TEXT NOT NULL,
        endDate TEXT,
        goals TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _addEndDateToGoalPeriods(Database db) async {
    await db.execute('ALTER TABLE goal_periods ADD COLUMN endDate TEXT');
  }

  // Meal operations
  Future<void> insertMeal(Meal meal) async {
    final db = await database;
    await db.insert('meals', _mealToMap(meal));
    await _updateDailySummary(meal.timestamp);
  }

  Future<void> updateMeal(Meal meal) async {
    final db = await database;
    await db.update(
      'meals',
      _mealToMap(meal),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
    await _updateDailySummary(meal.timestamp);
  }

  Future<void> deleteMeal(String id) async {
    final db = await database;
    
    // Get the meal to know which day to update
    final mealMaps = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    if (mealMaps.isNotEmpty) {
      final meal = _mealFromMap(mealMaps.first);
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
      await _updateDailySummary(meal.timestamp);
    }
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'meals',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return maps.map(_mealFromMap).toList();
  }

  Future<List<Meal>> getMealsInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'meals',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map(_mealFromMap).toList();
  }

  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'meals',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map(_mealFromMap).toList();
  }

  // Nutrition goals operations
  Future<void> setNutritionGoals(NutritionGoals goals) async {
    final db = await database;
    await db.delete('nutrition_goals'); // Only keep one set of goals
    await db.insert('nutrition_goals', {
      ...goals.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<NutritionGoals?> getNutritionGoals() async {
    final db = await database;
    final maps = await db.query('nutrition_goals', limit: 1);
    
    if (maps.isEmpty) return null;
    return NutritionGoals.fromMap(maps.first);
  }

  // Daily nutrition calculations
  Future<NutritionData> getDayNutrition(DateTime date) async {
    final meals = await getMealsByDate(date);
    if (meals.isEmpty) return NutritionData.zero;

    return meals.fold<NutritionData>(
      NutritionData.zero,
      (total, meal) => total + meal.totalNutrition,
    );
  }

  Future<Map<String, int>> getMealTypeCount(DateTime date) async {
    final meals = await getMealsByDate(date);
    final counts = <String, int>{
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };

    for (final meal in meals) {
      counts[meal.type.name] = (counts[meal.type.name] ?? 0) + 1;
    }

    return counts;
  }

  // Daily summaries for performance
  Future<void> _updateDailySummary(DateTime date) async {
    final db = await database;
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final nutrition = await getDayNutrition(date);
    final meals = await getMealsByDate(date);

    await db.delete('daily_summaries', where: 'date = ?', whereArgs: [dateKey]);
    await db.insert('daily_summaries', {
      'date': dateKey,
      'totalCalories': nutrition.calories,
      'totalProtein': nutrition.protein,
      'totalCarbs': nutrition.carbs,
      'totalFat': nutrition.fat,
      'mealCount': meals.length,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _mealToMap(Meal meal) {
    return {
      'id': meal.id,
      'timestamp': meal.timestamp.toIso8601String(),
      'type': meal.type.index,
      'imagePath': meal.imagePath,
      'foodItems': json.encode(meal.foodItems.map((item) => item.toMap()).toList()),
      'notes': meal.notes,
      'plateDiameter': meal.plateDiameter,
      'dishWeight': meal.dishWeight,
      'analysisMetadata': meal.analysisMetadata != null ? json.encode(meal.analysisMetadata) : null,
      'createdAt': meal.createdAt.toIso8601String(),
      'updatedAt': meal.updatedAt.toIso8601String(),
    };
  }

  Meal _mealFromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: MealType.values[map['type'] as int],
      imagePath: map['imagePath'] as String?,
      foodItems: (json.decode(map['foodItems'] as String) as List<dynamic>)
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      plateDiameter: (map['plateDiameter'] as num?)?.toDouble(),
      dishWeight: (map['dishWeight'] as num?)?.toDouble(),
      analysisMetadata: map['analysisMetadata'] != null 
          ? json.decode(map['analysisMetadata'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Goal periods operations
  Future<void> insertGoalPeriod(GoalPeriod goalPeriod) async {
    final db = await database;
    await db.insert('goal_periods', _goalPeriodToMap(goalPeriod));
  }

  Future<void> updateGoalPeriod(GoalPeriod goalPeriod) async {
    final db = await database;
    await db.update(
      'goal_periods',
      _goalPeriodToMap(goalPeriod),
      where: 'id = ?',
      whereArgs: [goalPeriod.id],
    );
  }

  Future<void> deleteGoalPeriod(String id) async {
    final db = await database;
    await db.delete('goal_periods', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GoalPeriod>> getGoalPeriods() async {
    final db = await database;
    final maps = await db.query(
      'goal_periods',
      orderBy: 'startDate DESC',
    );

    return maps.map(_goalPeriodFromMap).toList();
  }

  Future<GoalPeriod?> getCurrentGoalPeriod([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final db = await database;
    
    // Get all goal periods ordered by start date
    final maps = await db.query(
      'goal_periods',
      orderBy: 'startDate ASC',
    );

    final goalPeriods = maps.map(_goalPeriodFromMap).toList();
    
    // Find the active goal period for the target date
    return _findActiveGoalPeriod(goalPeriods, targetDate);
  }

  /// Find the active goal period for a given date using the new logic
  GoalPeriod? _findActiveGoalPeriod(List<GoalPeriod> goalPeriods, DateTime targetDate) {
    if (goalPeriods.isEmpty) return null;

    // Sort by start date to ensure proper ordering
    goalPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));

    // First, auto-set end dates for goals that don't have them
    _autoSetEndDates(goalPeriods);

    // Find the goal that is active for the target date
    for (final goal in goalPeriods) {
      if (goal.isActiveOn(targetDate)) {
        return goal;
      }
    }

    return null;
  }

  /// Automatically set end dates for goals that don't have them
  void _autoSetEndDates(List<GoalPeriod> goalPeriods) {
    for (int i = 0; i < goalPeriods.length - 1; i++) {
      final currentGoal = goalPeriods[i];
      final nextGoal = goalPeriods[i + 1];
      
      // If current goal doesn't have an end date, set it to the next goal's start date
      if (currentGoal.endDate == null) {
        goalPeriods[i] = currentGoal.copyWith(endDate: nextGoal.startDate);
      }
    }
    // The last goal remains open-ended if it doesn't have an end date
  }

  Future<GoalPeriod> createDefaultGoalPeriod() async {
    const uuid = Uuid();
    final goalPeriod = GoalPeriod(
      id: uuid.v4(),
      startDate: DateTime.now(),
      goals: NutritionGoals.balanced2000(),
      notes: 'Default goals',
      createdAt: DateTime.now(),
    );

    await insertGoalPeriod(goalPeriod);
    return goalPeriod;
  }

  /// Create a new goal period and automatically manage end dates
  Future<GoalPeriod> createGoalPeriod(
    NutritionGoals goals, 
    DateTime startDate, 
    String notes, {
    DateTime? endDate,
  }) async {
    // Validate that this period doesn't overlap with existing ones
    await _validateGoalPeriodOverlap(startDate, endDate);

    // Get existing goal periods to determine proper end date
    final existingGoals = await getGoalPeriods();
    
    // Determine the correct end date for the new goal
    DateTime? finalEndDate = endDate;
    if (finalEndDate == null) {
      // Find the next goal that starts after this one
      final futureGoals = existingGoals
          .where((g) => g.startDate.isAfter(startDate))
          .toList();
      
      if (futureGoals.isNotEmpty) {
        // Sort by start date and take the earliest
        futureGoals.sort((a, b) => a.startDate.compareTo(b.startDate));
        finalEndDate = futureGoals.first.startDate;
      }
      // If no future goals, leave end date as null (open-ended)
    }

    const uuid = Uuid();
    final newGoal = GoalPeriod(
      id: uuid.v4(),
      startDate: startDate,
      endDate: finalEndDate,
      goals: goals,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Update any existing open-ended goal that should end when this starts
    final previousGoals = existingGoals
        .where((g) => g.startDate.isBefore(startDate) && g.endDate == null)
        .toList();
    
    if (previousGoals.isNotEmpty) {
      // Sort by start date and take the latest (most recent)
      previousGoals.sort((a, b) => b.startDate.compareTo(a.startDate));
      final previousGoal = previousGoals.first;
      
      final updatedPreviousGoal = previousGoal.copyWith(endDate: startDate);
      await updateGoalPeriod(updatedPreviousGoal);
    }

    await insertGoalPeriod(newGoal);
    return newGoal;
  }

  /// Validate that a new goal period doesn't overlap with existing ones
  /// Only checks for explicit overlaps with goals that have both start and end dates
  Future<void> _validateGoalPeriodOverlap(DateTime startDate, DateTime? endDate) async {
    final existingGoals = await getGoalPeriods();
    
    // Normalize dates to avoid time-of-day issues
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = endDate != null 
        ? DateTime(endDate.year, endDate.month, endDate.day)
        : null;

    for (final existing in existingGoals) {
      final existingStart = DateTime(existing.startDate.year, existing.startDate.month, existing.startDate.day);
      final existingEnd = existing.endDate != null 
          ? DateTime(existing.endDate!.year, existing.endDate!.month, existing.endDate!.day)
          : null;

      // Only validate against goals that have explicit end dates
      // Open-ended goals will be automatically managed
      if (existingEnd != null && normalizedEnd != null) {
        // Both have end dates - check for overlap
        bool hasOverlap = !(normalizedEnd.isBefore(existingStart) || 
                           normalizedStart.isAtSameMomentAs(existingEnd) || 
                           normalizedStart.isAfter(existingEnd));
        
        if (hasOverlap) {
          throw Exception(
            'Goal period overlaps with existing period (${existing.dateRangeString}). '
            'Please choose different dates that don\'t conflict.'
          );
        }
      }
      
      // Check for duplicate start dates (not allowed)
      if (normalizedStart.isAtSameMomentAs(existingStart)) {
        throw Exception(
          'A goal period already starts on ${_formatDate(startDate)}. '
          'Please choose a different start date.'
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Statistics calculations
  Future<NutritionStats> calculateStats(StatsPeriod period) async {
    final now = DateTime.now();
    late final DateTime startDate;
    late final DateTime endDate;

    switch (period) {
      case StatsPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case StatsPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case StatsPeriod.total:
        final firstMeal = await _getFirstMealDate();
        startDate = firstMeal ?? DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    print('Calculating stats for $period: $startDate to $endDate');
    final result = await _calculateStatsForPeriod(startDate, endDate);
    print('Stats result: ${result.mealsTracked} meals, ${result.averageCalories} avg cal');
    return result;
  }

  Future<DateTime?> _getFirstMealDate() async {
    final db = await database;
    final result = await db.query(
      'meals',
      columns: ['timestamp'],
      orderBy: 'timestamp ASC',
      limit: 1,
    );

    return result.isNotEmpty 
        ? DateTime.parse(result.first['timestamp'] as String)
        : null;
  }

  Future<NutritionStats> _calculateStatsForPeriod(DateTime startDate, DateTime endDate) async {
    final meals = await getMealsInDateRange(startDate, endDate);
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    print('Found ${meals.length} meals for period $startDate to $endDate');
    
    if (meals.isEmpty) {
      return NutritionStats(
        mealsTracked: 0,
        averageCalories: 0,
        daysWithCalorieDeficit: 0,
        averageCalorieDelta: 0,
        proteinGoalHitRate: 0,
        loggingConsistency: 0,
        totalDays: totalDays,
        startDate: startDate,
        endDate: endDate,
      );
    }

    // Group meals by date
    final mealsByDate = <DateTime, List<Meal>>{};
    final mealsWithNutrition = <Meal>[];
    
    for (final meal in meals) {
      final date = DateTime(meal.timestamp.year, meal.timestamp.month, meal.timestamp.day);
      mealsByDate.putIfAbsent(date, () => []).add(meal);
      
      // Track meals that have nutrition data (AI analyzed)
      if (meal.foodItems.isNotEmpty) {
        mealsWithNutrition.add(meal);
      }
    }

    final daysWithMeals = mealsByDate.keys.length;
    print('Days with meals: $daysWithMeals, Meals with nutrition: ${mealsWithNutrition.length}');
    
    // Calculate daily nutrition totals (only for meals with nutrition data)
    final dailyNutrition = <DateTime, NutritionData>{};
    for (final entry in mealsByDate.entries) {
      final dayTotal = entry.value
          .map((meal) => meal.totalNutrition)
          .fold(NutritionData.zero, (total, nutrition) => total + nutrition);
      
      // Only include days that have nutrition data
      if (dayTotal.calories > 0) {
        dailyNutrition[entry.key] = dayTotal;
      }
    }

    // Calculate average calories (only for days with nutrition data)
    final daysWithNutrition = dailyNutrition.keys.length;
    final totalCalories = dailyNutrition.values.map((n) => n.calories).fold(0.0, (a, b) => a + b);
    final averageCalories = daysWithNutrition > 0 ? totalCalories / daysWithNutrition : 0.0;

    // Calculate calorie deficit days and average delta
    int deficitDays = 0;
    double totalDelta = 0.0;
    int proteinGoalsHit = 0;

    for (final entry in dailyNutrition.entries) {
      final goalPeriod = await getCurrentGoalPeriod(entry.key);
      if (goalPeriod != null) {
        final dailyCalories = entry.value.calories;
        final goalCalories = goalPeriod.goals.calories;
        final delta = dailyCalories - goalCalories;
        
        totalDelta += delta;
        if (delta < 0) deficitDays++;
        
        // Check protein goal
        if (entry.value.protein >= goalPeriod.goals.protein) {
          proteinGoalsHit++;
        }
      }
    }

    final averageDelta = daysWithNutrition > 0 ? totalDelta / daysWithNutrition : 0.0;
    final proteinHitRate = daysWithNutrition > 0 ? proteinGoalsHit / daysWithNutrition : 0.0;
    final loggingConsistency = totalDays > 0 ? daysWithMeals / totalDays : 0.0;

    print('Final stats: ${meals.length} total meals, $daysWithNutrition days with nutrition, $averageCalories avg calories');

    return NutritionStats(
      mealsTracked: meals.length, // Total meals including photo-only
      averageCalories: averageCalories,
      daysWithCalorieDeficit: deficitDays,
      averageCalorieDelta: averageDelta,
      proteinGoalHitRate: proteinHitRate,
      loggingConsistency: loggingConsistency,
      totalDays: totalDays,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Map<String, dynamic> _goalPeriodToMap(GoalPeriod goalPeriod) {
    return {
      'id': goalPeriod.id,
      'startDate': goalPeriod.startDate.toIso8601String(),
      'endDate': goalPeriod.endDate?.toIso8601String(),
      'goals': json.encode(goalPeriod.goals.toMap()),
      'notes': goalPeriod.notes,
      'createdAt': goalPeriod.createdAt.toIso8601String(),
    };
  }

  GoalPeriod _goalPeriodFromMap(Map<String, dynamic> map) {
    return GoalPeriod(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      goals: NutritionGoals.fromMap(json.decode(map['goals'] as String) as Map<String, dynamic>),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Get all meals (for backup)
  Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final result = await db.query('meals', orderBy: 'timestamp DESC');
    return result.map((map) => _mealFromMap(map)).toList();
  }

  /// Clear all data (for import - replace all)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('meals');
    await db.delete('daily_summaries');
    await db.delete('goal_periods');
    print('🗑️  All data cleared');
  }

  /// Set current goal period (for import)
  Future<void> setCurrentGoalPeriod(GoalPeriod goalPeriod) async {
    final db = await database;
    
    // End any existing active goal period
    final existing = await getCurrentGoalPeriod();
    if (existing != null && existing.endDate == null) {
      await db.update(
        'goal_periods',
        {'endDate': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }

    // Insert new goal period
    await db.insert(
      'goal_periods',
      _goalPeriodToMap(goalPeriod),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Add meal (for import)
  Future<void> addMeal(Meal meal) async {
    await insertMeal(meal);
  }
}