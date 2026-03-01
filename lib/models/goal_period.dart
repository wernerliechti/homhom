import 'nutrition_goals.dart';

class GoalPeriod {
  final String id;
  final DateTime startDate;
  final NutritionGoals goals;
  final String notes;
  final DateTime createdAt;

  const GoalPeriod({
    required this.id,
    required this.startDate,
    required this.goals,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'goals': goals.toMap(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalPeriod.fromMap(Map<String, dynamic> map) {
    return GoalPeriod(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      goals: NutritionGoals.fromMap(map['goals'] as Map<String, dynamic>),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  GoalPeriod copyWith({
    DateTime? startDate,
    NutritionGoals? goals,
    String? notes,
  }) {
    return GoalPeriod(
      id: id,
      startDate: startDate ?? this.startDate,
      goals: goals ?? this.goals,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}