import 'nutrition_goals.dart';

class GoalPeriod {
  final String id;
  final DateTime startDate;
  final DateTime? endDate; // Optional end date
  final NutritionGoals goals;
  final String notes;
  final DateTime createdAt;

  const GoalPeriod({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.goals,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'goals': goals.toMap(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalPeriod.fromMap(Map<String, dynamic> map) {
    return GoalPeriod(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      goals: NutritionGoals.fromMap(map['goals'] as Map<String, dynamic>),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  GoalPeriod copyWith({
    DateTime? startDate,
    DateTime? endDate,
    NutritionGoals? goals,
    String? notes,
  }) {
    return GoalPeriod(
      id: id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goals: goals ?? this.goals,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  /// Check if this goal period is active for a given date
  bool isActiveOn(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    
    // Must be on or after start date
    if (normalizedDate.isBefore(normalizedStart)) {
      return false;
    }
    
    // If end date is set, must be before end date
    if (endDate != null) {
      final normalizedEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return normalizedDate.isBefore(normalizedEnd);
    }
    
    // If no end date, goal is open-ended
    return true;
  }

  /// Check if this goal period has an explicit end date
  bool get hasEndDate => endDate != null;

  /// Get the duration in days (null if open-ended)
  int? get durationDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays;
  }

  /// Get a formatted date range string
  String get dateRangeString {
    final start = _formatDate(startDate);
    if (endDate == null) {
      return '$start - ongoing';
    }
    final end = _formatDate(endDate!);
    return '$start - $end';
  }

  /// Check if this goal period is completely in the future
  bool get isInFuture {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    
    return normalizedStart.isAfter(normalizedToday);
  }

  /// Check if this goal period can be deleted (only if completely in future)
  bool get canBeDeleted => isInFuture;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}