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

      // 2. Prepare the prompt for the LangChain Agent
      final String promptText = """
Please analyze this food and calculate calories. 
Name: "$foodName"
LiDAR Volume: ${volume?.toStringAsFixed(1) ?? "N/A"} cm³
Reference Data: ${fdcData != null ? jsonEncode(fdcData) : "None"}
""";

      // 3. Construct Request Body for /food_agent/invoke
      final requestBody = {
        "input": {
          "input": [
            {"type": "text", "text": promptText},
            if (imageUrl != null)
              {
                "type": "image_url",
                "image_url": imageUrl, // Assuming the agent handles S3 URLs
              },
          ],
          "chat_history": []
        }
      };

      print("AIFoodCaloriesService: Invoking Food Agent at $_agentUrl");

      final response = await http.post(
        Uri.parse("$_agentUrl/food_agent/invoke"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("Agent Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // The agent's final answer is in output
        final dynamic output = responseData['output'];
        
        // If output is a string (common for agents), we might need to parse it if it's JSON
        // Or if the agent returns a structured object, we use it directly.
        // For now, let's assume the agent returns a string that we need to extract data from,
        // or a JSON object that matches CaloriesProtocol.
        
        if (output is Map<String, dynamic>) {
          return CaloriesProtocol.fromJson(output);
        } else if (output is String) {
          // Attempt to find JSON in string if needed, but for simplicity:
          print("Agent returned string output: $output");
          // Fallback to direct Gemini if agent output is not structured yet
          // (Or you can implement a regex parser here)
        }
        
        // Mocking a successful return from the agent's text for now 
        // to show how it fits into the protocol.
        return const CaloriesProtocol(
          calories: 0, // Should be parsed from agent output
          protein: 0,
          carbs: 0,
          fat: 0,
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
