import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';
import 'package:ice_gate/link_layer/storage_services/MediaS3Paths.dart';
import 'package:ice_gate/link_layer/storage_services/MediaSync.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of calling the food AI agent (HTTP + parsing).
class AIFoodCaloriesOutcome {
  final CaloriesProtocol calories;
  /// False when the HTTP request failed, threw, or returned non-200.
  final bool requestOk;

  const AIFoodCaloriesOutcome({
    required this.calories,
    required this.requestOk,
  });
}

class AIFoodCaloriesService {
  static String get _agentUrl =>
      dotenv.env['FOOD_AGENT_URL'] ?? "http://localhost:8001";

  /// Uploads to `{personId}/food/…` (and `{personId}/meals/…` when [localRelativePath] is set).
  static Future<String?> _resolvePublicImageUrl({
    XFile? image,
    String? localRelativePath,
    String? existingPublicImageUrl,
    String? personId,
  }) async {
    if (existingPublicImageUrl != null &&
        (existingPublicImageUrl.startsWith('http://') ||
            existingPublicImageUrl.startsWith('https://'))) {
      appLog("AIFoodCaloriesService: Using existing public image URL for agent");
      return existingPublicImageUrl;
    }

    if (localRelativePath != null &&
        localRelativePath.isNotEmpty &&
        !localRelativePath.startsWith('http')) {
      final normalized = localRelativePath.replaceAll('\\', '/');
      final url = await MediaSync.uploadRelativePath(normalized);
      if (url != null) {
        appLog("AIFoodCaloriesService: Uploaded saved meal image to S3: $url");
        return url;
      }
    }

    if (image == null) return null;

    try {
      final pid = personId?.trim().isNotEmpty == true ? personId! : 'guest';
      final fileName = p.basename(image.path);
      final foodKey = mealImageS3Key(personId: pid, fileName: fileName);

      File uploadFile = File(image.path);
      if (localRelativePath != null &&
          localRelativePath.isNotEmpty &&
          !localRelativePath.startsWith('http')) {
        final appDir = await getApplicationDocumentsDirectory();
        final saved = File(p.join(appDir.path, localRelativePath));
        if (await saved.exists()) uploadFile = saved;
      }

      final url = await MinioService().uploadFileAtKey(
        uploadFile,
        objectKey: foodKey,
      );
      appLog("AIFoodCaloriesService: Image uploaded to S3 ($foodKey): $url");
      return url;
    } catch (e) {
      appLog("AIFoodCaloriesService: S3 upload failed: $e");
      return null;
    }
  }

  static Future<AIFoodCaloriesOutcome> analyzeFood(
    String foodName, {
    XFile? image,
    String? localRelativePath,
    String? existingPublicImageUrl,
    double? distance,
    double? volume,
    Map<String, dynamic>? fdcData,
    String? personId,
  }) async {
    try {
      final imageUrl = await _resolvePublicImageUrl(
        image: image,
        localRelativePath: localRelativePath,
        existingPublicImageUrl: existingPublicImageUrl,
        personId: personId,
      );

      final s3UrlForAgent =
          (imageUrl != null &&
              (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')))
          ? imageUrl
          : '';

      if (s3UrlForAgent.isEmpty) {
        appLog(
          "AIFoodCaloriesService: No public HTTPS image URL (missing file upload or invalid path). Skipping agent.",
        );
        return AIFoodCaloriesOutcome(
          calories: CaloriesProtocol.empty(),
          requestOk: false,
        );
      }

      appLog("AIFoodCaloriesService: Analyzing food '$foodName'");

      final requestBody = {
        "s3_url": s3UrlForAgent,
        "volume_cm3": volume ?? 250.0,
        "food_name": foodName,
      };

      appLog("AIFoodCaloriesService: Invoking Food Agent at $_agentUrl");

      final response = await http.post(
        Uri.parse("$_agentUrl/analyze_food_url"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      appLog("Agent Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final dynamic output = responseData['output'];

        final List? steps = responseData['intermediate_steps'] as List?;

        if (steps != null && steps.isNotEmpty) {
          double totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFat = 0;

          for (final step in steps) {
            final result = step['result'] as String? ?? '';
            final proteinMatch =
                RegExp(r'Protein:\s*([\d.]+)g').firstMatch(result);
            final carbsMatch = RegExp(r'Carbs:\s*([\d.]+)g').firstMatch(result);
            final fatMatch = RegExp(r'Fat:\s*([\d.]+)g').firstMatch(result);

            if (step['tool'] == 'calculate_volume_calories') {
              final totalCalMatch =
                  RegExp(r'Total Calories:\s*([\d.]+)').firstMatch(result);
              if (totalCalMatch != null) {
                totalCalories +=
                    double.tryParse(totalCalMatch.group(1)!) ?? 0;
              }
            }

            if (proteinMatch != null) {
              totalProtein +=
                  double.tryParse(proteinMatch.group(1)!) ?? 0;
            }
            if (carbsMatch != null) {
              totalCarbs += double.tryParse(carbsMatch.group(1)!) ?? 0;
            }
            if (fatMatch != null) {
              totalFat += double.tryParse(fatMatch.group(1)!) ?? 0;
            }
          }

          return AIFoodCaloriesOutcome(
            calories: CaloriesProtocol(
              calories: totalCalories.round(),
              protein: totalProtein.round(),
              carbs: totalCarbs.round(),
              fat: totalFat.round(),
              imageUrl: imageUrl,
            ),
            requestOk: true,
          );
        }

        if (output is Map<String, dynamic>) {
          final result = CaloriesProtocol.fromJson(output);
          return AIFoodCaloriesOutcome(
            calories: result.copyWith(imageUrl: imageUrl),
            requestOk: true,
          );
        } else if (output is String) {
          appLog("Agent returned text output: $output");
        }

        return AIFoodCaloriesOutcome(
          calories: CaloriesProtocol(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            imageUrl: imageUrl,
          ),
          requestOk: true,
        );
      } else {
        appLog("Agent Error: ${response.body}");
        return AIFoodCaloriesOutcome(
          calories: CaloriesProtocol.empty(),
          requestOk: false,
        );
      }
    } catch (e) {
      appLog("Error in AIFoodCaloriesService: $e");
      return AIFoodCaloriesOutcome(
        calories: CaloriesProtocol.empty(),
        requestOk: false,
      );
    }
  }
}
