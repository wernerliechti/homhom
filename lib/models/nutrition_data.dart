class NutritionData {
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  
  // Optional micronutrients
  final double? fiber; // grams
  final double? sugar; // grams
  final double? sodium; // mg
  final double? vitaminC; // mg
  final double? calcium; // mg
  final double? iron; // mg

  const NutritionData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.vitaminC,
    this.calcium,
    this.iron,
  });

  // Helper getters for macros
  double get totalMacros => protein + carbs + fat;
  double get proteinPercentage => totalMacros > 0 ? (protein / totalMacros) * 100 : 0;
  double get carbsPercentage => totalMacros > 0 ? (carbs / totalMacros) * 100 : 0;
  double get fatPercentage => totalMacros > 0 ? (fat / totalMacros) * 100 : 0;

  // Calorie breakdown
  double get proteinCalories => protein * 4;
  double get carbsCalories => carbs * 4;
  double get fatCalories => fat * 9;

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
    };
  }

  factory NutritionData.fromMap(Map<String, dynamic> map) {
    return NutritionData(
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble(),
      sugar: (map['sugar'] as num?)?.toDouble(),
      sodium: (map['sodium'] as num?)?.toDouble(),
      vitaminC: (map['vitaminC'] as num?)?.toDouble(),
      calcium: (map['calcium'] as num?)?.toDouble(),
      iron: (map['iron'] as num?)?.toDouble(),
    );
  }

  NutritionData operator +(NutritionData other) {
    return NutritionData(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: (fiber ?? 0) + (other.fiber ?? 0),
      sugar: (sugar ?? 0) + (other.sugar ?? 0),
      sodium: (sodium ?? 0) + (other.sodium ?? 0),
      vitaminC: (vitaminC ?? 0) + (other.vitaminC ?? 0),
      calcium: (calcium ?? 0) + (other.calcium ?? 0),
      iron: (iron ?? 0) + (other.iron ?? 0),
    );
  }

  NutritionData copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? vitaminC,
    double? calcium,
    double? iron,
  }) {
    return NutritionData(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      vitaminC: vitaminC ?? this.vitaminC,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
    );
  }

  static const NutritionData zero = NutritionData(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );
}