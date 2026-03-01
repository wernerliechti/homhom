import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_data.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
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

    // Indexes for faster queries
    await db.execute('CREATE INDEX idx_meals_timestamp ON meals(timestamp DESC)');
    await db.execute('CREATE INDEX idx_meals_type ON meals(type)');
    await db.execute('CREATE INDEX idx_daily_summaries_date ON daily_summaries(date DESC)');
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
}