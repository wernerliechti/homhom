class NutritionStats {
  final int mealsTracked;
  final double averageCalories;
  final int daysWithCalorieDeficit;
  final double averageCalorieDelta;
  final double proteinGoalHitRate;
  final double loggingConsistency;
  final int totalDays;
  final DateTime startDate;
  final DateTime endDate;

  const NutritionStats({
    required this.mealsTracked,
    required this.averageCalories,
    required this.daysWithCalorieDeficit,
    required this.averageCalorieDelta,
    required this.proteinGoalHitRate,
    required this.loggingConsistency,
    required this.totalDays,
    required this.startDate,
    required this.endDate,
  });

  static final NutritionStats empty = NutritionStats(
    mealsTracked: 0,
    averageCalories: 0,
    daysWithCalorieDeficit: 0,
    averageCalorieDelta: 0,
    proteinGoalHitRate: 0,
    loggingConsistency: 0,
    totalDays: 0,
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );

  bool get hasData => mealsTracked > 0;

  String get averageCaloriesFormatted => averageCalories.toStringAsFixed(0);
  String get averageCalorieDeltaFormatted {
    final delta = averageCalorieDelta;
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(0)}';
  }
  String get proteinGoalHitRateFormatted => '${(proteinGoalHitRate * 100).toStringAsFixed(0)}%';
  String get loggingConsistencyFormatted => '${(loggingConsistency * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toMap() {
    return {
      'mealsTracked': mealsTracked,
      'averageCalories': averageCalories,
      'daysWithCalorieDeficit': daysWithCalorieDeficit,
      'averageCalorieDelta': averageCalorieDelta,
      'proteinGoalHitRate': proteinGoalHitRate,
      'loggingConsistency': loggingConsistency,
      'totalDays': totalDays,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory NutritionStats.fromMap(Map<String, dynamic> map) {
    return NutritionStats(
      mealsTracked: map['mealsTracked'] as int,
      averageCalories: (map['averageCalories'] as num).toDouble(),
      daysWithCalorieDeficit: map['daysWithCalorieDeficit'] as int,
      averageCalorieDelta: (map['averageCalorieDelta'] as num).toDouble(),
      proteinGoalHitRate: (map['proteinGoalHitRate'] as num).toDouble(),
      loggingConsistency: (map['loggingConsistency'] as num).toDouble(),
      totalDays: map['totalDays'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}

enum StatsPeriod {
  thisWeek('This Week'),
  thisMonth('This Month'),
  total('Total');

  const StatsPeriod(this.label);
  final String label;
}