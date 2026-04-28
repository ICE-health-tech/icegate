import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ice_gate/link_layer/storage_services/minio_service.dart';
import 'dart:io';

class AIFoodCaloriesService {
  // Gemini 1.5 Flash: Cheap, Fast, and supports Vision
  static String get _agentUrl => dotenv.env['FOOD_AGENT_URL'] ?? "http://localhost:8001";

  static Future<CaloriesProtocol> getCalories(
    String foodName, {
    XFile? image,
    double? distance,
    double? volume,
    Map<String, dynamic>? fdcData,
    String? personId,
  }) async {
    try {
      // 1. Upload to S3 if image exists
      String? imageUrl;
      if (image != null) {
        final s3 = MinioService();
        final subFolder = personId != null ? '$personId/food' : 'guest/food';
        imageUrl = await s3.uploadFile(File(image.path), subFolder: subFolder);
        print("AIFoodCaloriesService: Image uploaded to S3: $imageUrl");
      }

      // 2. Log the food name for debugging
      print("AIFoodCaloriesService: Analyzing food '$foodName'");

      // 3. Construct Request Body for /analyze_food_url
      // The deployed agent expects { s3_url, volume_cm3 } format,
      // NOT the old LangServe /food_agent/invoke format.
      final requestBody = {
        "s3_url": imageUrl ?? "",
        "volume_cm3": volume ?? 250.0,
      };

      print("AIFoodCaloriesService: Invoking Food Agent at $_agentUrl");

      // Call the correct endpoint: /analyze_food_url
      final response = await http.post(
        Uri.parse("$_agentUrl/analyze_food_url"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("Agent Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // The agent returns { output, intermediate_steps, image_url }
        final dynamic output = responseData['output'];
        
        // Try to parse structured data from intermediate_steps
        // Each step has { tool, args, result } with nutrition info
        final List? steps = responseData['intermediate_steps'] as List?;
        
        if (steps != null && steps.isNotEmpty) {
          double totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFat = 0;
          
          // Sum up all calculated food items from intermediate steps
          for (final step in steps) {
            final result = step['result'] as String? ?? '';
            // Parse macros from get_food_nutrition step results
            final proteinMatch = RegExp(r'Protein:\s*([\d.]+)g').firstMatch(result);
            final carbsMatch = RegExp(r'Carbs:\s*([\d.]+)g').firstMatch(result);
            final fatMatch = RegExp(r'Fat:\s*([\d.]+)g').firstMatch(result);
            
            // Only sum from calculate_volume_calories steps (they have total calories)
            if (step['tool'] == 'calculate_volume_calories') {
              final totalCalMatch = RegExp(r'Total Calories:\s*([\d.]+)').firstMatch(result);
              if (totalCalMatch != null) {
                totalCalories += double.tryParse(totalCalMatch.group(1)!) ?? 0;
              }
            }
            
            if (proteinMatch != null) totalProtein += double.tryParse(proteinMatch.group(1)!) ?? 0;
            if (carbsMatch != null) totalCarbs += double.tryParse(carbsMatch.group(1)!) ?? 0;
            if (fatMatch != null) totalFat += double.tryParse(fatMatch.group(1)!) ?? 0;
          }
          
          // CaloriesProtocol expects int fields, so round the sums
          return CaloriesProtocol(
            calories: totalCalories.round(),
            protein: totalProtein.round(),
            carbs: totalCarbs.round(),
            fat: totalFat.round(),
            imageUrl: imageUrl,
          );
        }

        if (output is Map<String, dynamic>) {
          final result = CaloriesProtocol.fromJson(output);
          return result.copyWith(imageUrl: imageUrl);
        } else if (output is String) {
          print("Agent returned text output: $output");
        }
        
        return CaloriesProtocol(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          imageUrl: imageUrl,
        );
      } else {
        print("Agent Error: ${response.body}");
        return CaloriesProtocol.empty();
      }
    } catch (e) {
      print("Error in AIFoodCaloriesService: $e");
      return CaloriesProtocol.empty();
    }
  }
}
