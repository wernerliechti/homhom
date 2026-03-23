import 'dart:convert';
import 'meal.dart';
import 'goal_period.dart';

class BackupMetadata {
  final String appVersion;
  final String schemaVersion;
  final DateTime exportedAt;
  final int mealCount;
  final int goalPeriodCount;

  BackupMetadata({
    required this.appVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.mealCount,
    required this.goalPeriodCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'mealCount': mealCount,
      'goalPeriodCount': goalPeriodCount,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      schemaVersion: map['schemaVersion'] as String? ?? '1.0',
      exportedAt: DateTime.parse(map['exportedAt'] as String? ?? DateTime.now().toIso8601String()),
      mealCount: map['mealCount'] as int? ?? 0,
      goalPeriodCount: map['goalPeriodCount'] as int? ?? 0,
    );
  }
}

class BackupData {
  final BackupMetadata metadata;
  final List<Meal> meals;
  final List<GoalPeriod> goalPeriods;

  BackupData({
    required this.metadata,
    required this.meals,
    required this.goalPeriods,
  });

  Map<String, dynamic> toMap() {
    return {
      'metadata': metadata.toMap(),
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'goalPeriods': goalPeriods.map((gp) => gp.toMap()).toList(),
    };
  }

  factory BackupData.fromMap(Map<String, dynamic> map) {
    return BackupData(
      metadata: BackupMetadata.fromMap(map['metadata'] as Map<String, dynamic>? ?? {}),
      meals: (map['meals'] as List<dynamic>?)
          ?.map((item) => Meal.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      goalPeriods: (map['goalPeriods'] as List<dynamic>?)
          ?.map((item) => GoalPeriod.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory BackupData.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupData.fromMap(map);
  }
}
