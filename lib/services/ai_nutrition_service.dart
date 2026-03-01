import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';

class AINutritionService {
  static const _storage = FlutterSecureStorage();
  static const String _openaiKeyKey = 'openai_api_key';

  // API Key Management
  Future<String?> getOpenAIKey() async => await _storage.read(key: _openaiKeyKey);
  Future<void> setOpenAIKey(String key) async => await _storage.write(key: _openaiKeyKey, value: key);
  Future<bool> isConfigured() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty;
  }

  /// Analyze a meal photo and return identified food items with nutrition data
  Future<List<FoodItem>> analyzeMealPhoto(
    String imagePath, {
    double? plateDiameter,
    double? dishWeight,
  }) async {
    final apiKey = await getOpenAIKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      // Read and encode the image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Create the analysis prompt
      final prompt = _buildAnalysisPrompt(plateDiameter, dishWeight);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4o', // Vision-capable model
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'high',
                  }
                }
              ]
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        return _parseAnalysisResponse(content);
      } else {
        throw Exception('Analysis failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Meal analysis error: $e');
    }
  }

  String _buildAnalysisPrompt(double? plateDiameter, double? dishWeight) {
    final contextInfo = <String>[];
    
    if (plateDiameter != null) {
      contextInfo.add('Plate diameter: ${plateDiameter}cm');
    }
    if (dishWeight != null) {
      contextInfo.add('Total dish weight: ${dishWeight}g');
    }

    final context = contextInfo.isNotEmpty 
        ? 'Additional context: ${contextInfo.join(', ')}\n\n'
        : '';

    return '''Analyze this meal photo and identify all visible food items. For each food item, estimate the portion size and calculate detailed nutritional information.

${context}Please respond with ONLY valid JSON in this exact format:

{
  "foods": [
    {
      "name": "food name",
      "description": "brief description of preparation/cooking method",
      "estimatedWeight": 150.0,
      "confidence": 0.85,
      "portionMethod": "visual estimation method used",
      "nutrition": {
        "calories": 280.0,
        "protein": 12.5,
        "carbs": 35.0,
        "fat": 8.2,
        "fiber": 3.1,
        "sugar": 2.0,
        "sodium": 450.0,
        "vitaminC": 15.0,
        "calcium": 120.0,
        "iron": 2.1
      }
    }
  ],
  "analysisNotes": "Overall analysis notes about portion estimation accuracy"
}

Guidelines:
- Identify each distinct food item separately
- Estimate weight in grams based on visual appearance
- Confidence from 0.0 to 1.0 based on identification certainty
- Include realistic nutritional values per estimated portion
- Be conservative with portion estimates rather than overestimating
- Consider cooking methods in nutrition calculations
- Include key micronutrients when significant amounts are present''';
  }

  List<FoodItem> _parseAnalysisResponse(String response) {
    try {
      // Clean the response to ensure it's valid JSON
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();

      final data = json.decode(cleanResponse) as Map<String, dynamic>;
      final foods = data['foods'] as List<dynamic>;

      return foods.map((foodData) {
        final foodMap = foodData as Map<String, dynamic>;
        final nutritionMap = foodMap['nutrition'] as Map<String, dynamic>;

        return FoodItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + 
               (foods.indexOf(foodData)).toString(),
          name: foodMap['name'] as String,
          description: foodMap['description'] as String,
          estimatedWeight: (foodMap['estimatedWeight'] as num).toDouble(),
          confidence: (foodMap['confidence'] as num).toDouble(),
          portionMethod: foodMap['portionMethod'] as String?,
          nutrition: NutritionData.fromMap(nutritionMap),
          metadata: {
            'analysisNotes': data['analysisNotes'] as String?,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Test the API connection
  Future<bool> testConnection() async {
    try {
      final apiKey = await getOpenAIKey();
      if (apiKey == null || apiKey.isEmpty) return false;

      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get estimated cost for analysis
  double getEstimatedCost({int imageCount = 1}) {
    // GPT-4 Vision pricing (approximate)
    const costPerImage = 0.01; // ~$0.01 per high-detail image
    return imageCount * costPerImage;
  }
}