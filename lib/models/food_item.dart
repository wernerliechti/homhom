import 'nutrition_data.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double estimatedWeight; // grams
  final double confidence; // 0.0 to 1.0
  final NutritionData nutrition;
  
  // Portion estimation metadata
  final String? portionMethod; // "visual", "weight", "plate_reference"
  final Map<String, dynamic>? metadata; // Additional AI analysis data

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedWeight,
    required this.confidence,
    required this.nutrition,
    this.portionMethod,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'estimatedWeight': estimatedWeight,
      'confidence': confidence,
      'nutrition': nutrition.toMap(),
      'portionMethod': portionMethod,
      'metadata': metadata,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      estimatedWeight: (map['estimatedWeight'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      nutrition: NutritionData.fromMap(map['nutrition'] as Map<String, dynamic>),
      portionMethod: map['portionMethod'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  FoodItem copyWith({
    String? name,
    String? description,
    double? estimatedWeight,
    double? confidence,
    NutritionData? nutrition,
    String? portionMethod,
    Map<String, dynamic>? metadata,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      confidence: confidence ?? this.confidence,
      nutrition: nutrition ?? this.nutrition,
      portionMethod: portionMethod ?? this.portionMethod,
      metadata: metadata ?? this.metadata,
    );
  }

  String get confidenceText {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  String get portionDescription {
    final grams = estimatedWeight.toStringAsFixed(0);
    if (estimatedWeight > 1000) {
      final kg = (estimatedWeight / 1000).toStringAsFixed(1);
      return '${kg}kg (~${grams}g)';
    }
    return '${grams}g';
  }
}