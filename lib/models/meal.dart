import 'package:uuid/uuid.dart';
import 'food_item.dart';
import 'nutrition_data.dart';

enum MealType { breakfast, lunch, dinner, snack }

class Meal {
  final String id;
  final DateTime timestamp;
  final MealType type;
  final String? imagePath;
  final List<FoodItem> foodItems;
  final String? notes;
  
  // Photo metadata for better AI analysis
  final double? plateDiameter; // cm
  final double? dishWeight; // grams
  final Map<String, dynamic>? analysisMetadata;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Meal({
    String? id,
    required this.timestamp,
    required this.type,
    this.imagePath,
    this.foodItems = const [],
    this.notes,
    this.plateDiameter,
    this.dishWeight,
    this.analysisMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate total nutrition from all food items
  NutritionData get totalNutrition {
    if (foodItems.isEmpty) return NutritionData.zero;
    
    return foodItems.fold<NutritionData>(
      NutritionData.zero,
      (total, item) => total + item.nutrition,
    );
  }

  // Get meal type based on time if not set
  static MealType getMealTypeFromTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 11) return MealType.breakfast;
    if (hour >= 11 && hour < 15) return MealType.lunch;
    if (hour >= 17 && hour < 22) return MealType.dinner;
    return MealType.snack;
  }

  String get typeDisplayName {
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

  String get timeDisplay {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  bool get hasAnalysis => foodItems.isNotEmpty;
  bool get isProcessing => imagePath != null && !hasAnalysis;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'imagePath': imagePath,
      'foodItems': foodItems.map((item) => item.toMap()).toList(),
      'notes': notes,
      'plateDiameter': plateDiameter,
      'dishWeight': dishWeight,
      'analysisMetadata': analysisMetadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: MealType.values[map['type'] as int],
      imagePath: map['imagePath'] as String?,
      foodItems: (map['foodItems'] as List<dynamic>?)
          ?.map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] as String?,
      plateDiameter: (map['plateDiameter'] as num?)?.toDouble(),
      dishWeight: (map['dishWeight'] as num?)?.toDouble(),
      analysisMetadata: map['analysisMetadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Meal copyWith({
    DateTime? timestamp,
    MealType? type,
    String? imagePath,
    List<FoodItem>? foodItems,
    String? notes,
    double? plateDiameter,
    double? dishWeight,
    Map<String, dynamic>? analysisMetadata,
  }) {
    return Meal(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      foodItems: foodItems ?? this.foodItems,
      notes: notes ?? this.notes,
      plateDiameter: plateDiameter ?? this.plateDiameter,
      dishWeight: dishWeight ?? this.dishWeight,
      analysisMetadata: analysisMetadata ?? this.analysisMetadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}