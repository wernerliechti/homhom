import 'nutrition_data.dart';

class NutritionGoals {
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  
  // Optional micronutrient goals
  final double? fiber; // grams
  final double? sodium; // mg (max)
  final double? sugar; // grams (max)

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
    this.sugar,
  });

  // Common goal presets
  static NutritionGoals balanced2000() {
    return const NutritionGoals(
      calories: 2000,
      protein: 150, // 30%
      carbs: 200, // 40%
      fat: 67, // 30%
      fiber: 25,
      sodium: 2300,
      sugar: 50,
    );
  }

  static NutritionGoals moderateCalorie1800() {
    return const NutritionGoals(
      calories: 1800,
      protein: 135, // 30%
      carbs: 180, // 40%
      fat: 60, // 30%
      fiber: 23,
      sodium: 2300,
      sugar: 45,
    );
  }

  static NutritionGoals lowCarb2000() {
    return const NutritionGoals(
      calories: 2000,
      protein: 150, // 30%
      carbs: 100, // 20%
      fat: 111, // 50%
      fiber: 20,
      sodium: 2300,
      sugar: 30,
    );
  }

  static NutritionGoals highProtein2200() {
    return const NutritionGoals(
      calories: 2200,
      protein: 200, // 36%
      carbs: 165, // 30%
      fat: 83, // 34%
      fiber: 28,
      sodium: 2300,
      sugar: 50,
    );
  }

  // Calculate remaining nutrition for the day
  NutritionGoals remaining(NutritionData consumed) {
    return NutritionGoals(
      calories: (calories - consumed.calories).clamp(0, double.infinity),
      protein: (protein - consumed.protein).clamp(0, double.infinity),
      carbs: (carbs - consumed.carbs).clamp(0, double.infinity),
      fat: (fat - consumed.fat).clamp(0, double.infinity),
      fiber: fiber != null ? 
        (fiber! - (consumed.fiber ?? 0)).clamp(0, double.infinity) : null,
      sodium: sodium != null ? 
        (sodium! - (consumed.sodium ?? 0)).clamp(0, double.infinity) : null,
      sugar: sugar != null ? 
        (sugar! - (consumed.sugar ?? 0)).clamp(0, double.infinity) : null,
    );
  }

  // Calculate progress percentages
  double calorieProgress(double consumed) => consumed / calories;
  double proteinProgress(double consumed) => consumed / protein;
  double carbsProgress(double consumed) => consumed / carbs;
  double fatProgress(double consumed) => consumed / fat;

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'sugar': sugar,
    };
  }

  factory NutritionGoals.fromMap(Map<String, dynamic> map) {
    return NutritionGoals(
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
      sodium: (map['sodium'] as num?)?.toDouble(),
      sugar: (map['sugar'] as num?)?.toDouble(),
    );
  }

  NutritionGoals copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodium,
    double? sugar,
  }) {
    return NutritionGoals(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
    );
  }
}