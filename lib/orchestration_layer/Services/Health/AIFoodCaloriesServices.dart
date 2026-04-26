import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIFoodCaloriesService {
  // Gemini 1.5 Flash: Cheap, Fast, and supports Vision
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  static Future<CaloriesProtocol> getCalories(
    String foodName, {
    XFile? image,
    double? distance,
    double? volume,
    Map<String, dynamic>? fdcData,
  }) async {
    try {
      // 1. Prepare Image Data if exists
      String? base64Image;
      if (image != null) {
        final bytes = await image.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // 2. Construct the prompt
      String prompt = """
      Analyze this food item. 
      Name Provided: "$foodName"
      
      CONTEXT DATA:
      - Measured Volume: ${volume?.toStringAsFixed(1) ?? "N/A"} cm³
      - Measured Length: ${distance?.toStringAsFixed(1) ?? "N/A"} cm
      - Reference Data: ${fdcData != null ? jsonEncode(fdcData) : "None"}
      
      TASK:
      1. Identify the food from the image (if provided) and the name.
      2. Estimate density (g/cm³).
      3. Calculate total grams using the measured volume.
      4. Calculate Calories, Protein, Carbs, and Fat based on estimated weight.
      
      Return ONLY a JSON object:
      {
        "calories": number,
        "protein": number,
        "carbs": number,
        "fat": number,
        "serving_size": "string (e.g. '250g based on scan')",
        "confidence": number
      }
      """;

      print("--- GEMINI FOOD ANALYSIS REQUEST ---");
      print("Name: $foodName, Volume: $volume");
      if (image != null)
        print("Image included (Base64 length: ${base64Image?.length})");

      final List<Map<String, dynamic>> contents = [
        {
          "parts": [
            {"text": prompt},
            if (base64Image != null)
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
          ],
        },
      ];

      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": contents,
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.2,
          },
        }),
      );

      print("Gemini Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        print("--- GEMINI RESPONSE ---");
        print(textResponse);

        final Map<String, dynamic> calorieData = jsonDecode(textResponse);
        return CaloriesProtocol.fromJson(calorieData);
      } else {
        print("Gemini Error: ${response.body}");
        return CaloriesProtocol.empty();
      }
    } catch (e) {
      print("Error in Gemini Service: $e");
      return CaloriesProtocol.empty();
    }
  }
}
