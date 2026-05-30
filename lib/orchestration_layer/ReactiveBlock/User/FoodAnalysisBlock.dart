import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/AIFoodCaloriesServices.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/FoodDataCentralService.dart';
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';

/// Result of [FoodAnalysisBlock.analyze] (includes AI availability).
class FoodAnalysisOutcome {
  final CaloriesProtocol protocol;
  final bool aiSucceeded;

  const FoodAnalysisOutcome({
    required this.protocol,
    required this.aiSucceeded,
  });
}

class FoodAnalysisBlock {
  final AppDatabase _db;

  final isAnalyzing = signal<bool>(false);
  final analysisStatus = signal<String>("");

  FoodAnalysisBlock(this._db);

  Future<FoodAnalysisOutcome> analyze({
    required String foodName,
    XFile? image,
    String? localRelativePath,
    String? existingPublicImageUrl,
    double? volume,
    double? distance,
    String? personId,
  }) async {
    isAnalyzing.value = true;
    analysisStatus.value = "Analyzing $foodName...";

    try {
      Map<String, dynamic>? fdcData;
      if (foodName.isNotEmpty && foodName.length > 2) {
        try {
          fdcData = await FoodDataCentralService.searchFood(foodName);
        } catch (e) {
          debugPrint("FoodAnalysisBlock: FDC search failed: $e");
        }
      }

      final outcome = await AIFoodCaloriesService.analyzeFood(
        foodName,
        image: image,
        localRelativePath: localRelativePath,
        existingPublicImageUrl: existingPublicImageUrl,
        volume: volume,
        distance: distance,
        fdcData: fdcData,
        personId: personId,
      );

      return FoodAnalysisOutcome(
        protocol: outcome.calories,
        aiSucceeded: outcome.requestOk,
      );
    } finally {
      isAnalyzing.value = false;
      analysisStatus.value = "";
    }
  }

  Future<void> analyzeAndSave({
    required String mealId,
    required String foodName,
    XFile? image,
    String? localRelativePath,
    double? volume,
    double? distance,
    String? personId,
  }) async {
    debugPrint(
      "FoodAnalysisBlock: 🔍 Starting background analysis for meal $mealId",
    );

    try {
      XFile? effectiveImage = image;
      String? effectiveLocalPath = localRelativePath;
      String? existingHttpsUrl;
      if (effectiveImage == null && (effectiveLocalPath == null || effectiveLocalPath.isEmpty)) {
        final meal = await (_db.select(_db.mealsTable)
              ..where((t) => t.id.equals(mealId)))
            .getSingleOrNull();
        final u = meal?.mealImageUrl;
        if (u != null && !u.startsWith('http')) {
          effectiveLocalPath = u;
        }
        effectiveImage = await _mealImageToXFile(
          meal?.mealImageUrl,
          personId ?? meal?.personID,
        );
        if (effectiveImage == null &&
            u != null &&
            (u.startsWith('http://') || u.startsWith('https://'))) {
          existingHttpsUrl = u;
        }
      }

      final outcome = await analyze(
        foodName: foodName,
        image: effectiveImage,
        localRelativePath: effectiveLocalPath,
        existingPublicImageUrl: existingHttpsUrl,
        volume: volume,
        distance: distance,
        personId: personId,
      );

      if (outcome.aiSucceeded) {
        final result = outcome.protocol;
        debugPrint(
          "FoodAnalysisBlock: ✅ Analysis complete for $mealId: ${result.calories} kcal",
        );
        await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId)))
            .write(
          MealsTableCompanion(
            protein: Value(result.protein.toDouble()),
            carbs: Value(result.carbs.toDouble()),
            fat: Value(result.fat.toDouble()),
            calories: Value(result.calories.toDouble()),
            mealImageUrl: result.imageUrl != null
                ? Value(result.imageUrl)
                : const Value.absent(),
            isAnalyzing: const Value(false),
            needsAiRetry: const Value(false),
          ),
        );
      } else {
        debugPrint(
          "FoodAnalysisBlock: ⚠️ AI request failed for $mealId — flagging retry",
        );
        await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId)))
            .write(
          const MealsTableCompanion(
            isAnalyzing: Value(false),
            needsAiRetry: Value(true),
          ),
        );
      }
    } catch (e) {
      debugPrint("FoodAnalysisBlock: ❌ Error during analysis for $mealId: $e");
      try {
        await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId)))
            .write(
          const MealsTableCompanion(
            isAnalyzing: Value(false),
            needsAiRetry: Value(true),
          ),
        );
      } catch (_) {}
    }
  }

  /// Re-run AI for a meal saved with [MealData.needsAiRetry].
  Future<bool> retryAnalysisForMeal(String mealId) async {
    final meal = await (_db.select(_db.mealsTable)
          ..where((t) => t.id.equals(mealId)))
        .getSingleOrNull();
    if (meal == null) return false;

    await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId))).write(
      const MealsTableCompanion(
        isAnalyzing: Value(true),
        needsAiRetry: Value(false),
      ),
    );

    final image = await _mealImageToXFile(meal.mealImageUrl, meal.personID);
    await analyzeAndSave(
      mealId: mealId,
      foodName: meal.mealName,
      image: image,
      volume: null,
      distance: null,
      personId: meal.personID,
    );
    return true;
  }

  static Future<XFile?> _mealImageToXFile(
    String? relativePath,
    String? personId,
  ) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return null;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (relativePath.contains('/')) {
        final full = p.join(appDir.path, relativePath);
        if (File(full).existsSync()) return XFile(full);
      }
      if (personId != null && personId.isNotEmpty) {
        final isolated = p.join(
          appDir.path,
          personId,
          'meals',
          p.basename(relativePath),
        );
        if (File(isolated).existsSync()) return XFile(isolated);
      }
      final general = p.join(appDir.path, 'meals', p.basename(relativePath));
      if (File(general).existsSync()) return XFile(general);
    } catch (e) {
      debugPrint('FoodAnalysisBlock: image resolve failed: $e');
    }
    return null;
  }

  void dispose() {
    isAnalyzing.dispose();
    analysisStatus.dispose();
  }
}
