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
    String? dishName,
    double? plateDiameter,
    double? dishWeight,
  }) async {
    final apiKey = await getOpenAIKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      // Debug: Log the metadata being sent
      print('AI Analysis Debug:');
      print('  Dish name: ${dishName ?? 'not provided'}');
      print('  Plate diameter: ${plateDiameter ?? 'not provided'}cm');
      print('  Dish weight: ${dishWeight ?? 'not provided'}g');
      
      // Read and encode the image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Create the analysis prompt
      final prompt = _buildAnalysisPrompt(dishName, plateDiameter, dishWeight);
      
      // Debug: Log the prompt context
      print('  Prompt includes context: ${dishName != null || plateDiameter != null || dishWeight != null}');

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

  String _buildAnalysisPrompt(String? dishName, double? plateDiameter, double? dishWeight) {
    final contextInfo = <String>[];
    
    if (dishName != null) {
      contextInfo.add('Dish name: "$dishName"');
    }
    if (plateDiameter != null) {
      contextInfo.add('Plate diameter: ${plateDiameter}cm');
    }
    if (dishWeight != null) {
      contextInfo.add('Total dish weight: ${dishWeight}g');
    }

    final hasContext = contextInfo.isNotEmpty;
    final context = hasContext 
        ? '🔍 MEASUREMENT CONTEXT PROVIDED: ${contextInfo.join(', ')}\n\n'
        : '';

    final calibrationInstructions = hasContext ? '''
🎯 CRITICAL CALIBRATION INSTRUCTIONS:
${dishName != null ? '- The user identified this as: "$dishName" - use this to guide your food identification and nutrition accuracy' : ''}
${plateDiameter != null ? '- The plate/bowl in the image is exactly ${plateDiameter}cm diameter (standard dinner plate = 25-27cm)' : ''}
${dishWeight != null ? '- The total weight of food + container is ${dishWeight}g - use this to validate your estimates' : ''}
- Scale your portion estimates based on these measurements
- A smaller plate (< 23cm) means smaller portions than they appear
- A larger plate (> 28cm) means larger portions than typical
${dishWeight != null ? '- Your food weight estimates should sum to approximately ${dishWeight}g minus container weight' : ''}
${dishName != null ? '- When the dish name is provided, prioritize identifying components that match this dish type' : ''}

''' : '''
⚠️ NO MEASUREMENT CONTEXT - Use visual estimation only
- Assume standard 25cm dinner plate for reference
- Use typical portion size assumptions

''';

    return '''Analyze this meal photo and identify all visible food items. For each food item, estimate the portion size and calculate detailed nutritional information.
${dishName != null ? 'The user has identified this dish as: "$dishName". Use this information to improve accuracy of food identification and nutrition estimates.' : ''}

${context}${calibrationInstructions}

Please respond with ONLY valid JSON in this exact format:

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
- Estimate weight in grams based on visual appearance and provided context
- If plate diameter is provided, use it for scale reference (typical dinner plate = 25-27cm)
- If dish weight is provided, ensure your food weight estimates sum approximately to this total
- Confidence from 0.0 to 1.0 based on identification certainty
- Include realistic nutritional values per estimated portion
- Adjust portion sizes based on plate reference - smaller plates mean smaller portions
- Consider cooking methods in nutrition calculations
- Include key micronutrients when significant amounts are present
- CRITICAL: Use the provided measurements to calibrate your estimates - don't ignore this context''';
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