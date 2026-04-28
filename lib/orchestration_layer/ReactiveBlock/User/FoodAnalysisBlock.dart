import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/AIFoodCaloriesServices.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/FoodDataCentralService.dart';
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals/signals.dart';

class FoodAnalysisBlock {
  final AppDatabase _db;
  
  // State signals
  final isAnalyzing = signal<bool>(false);
  final analysisStatus = signal<String>("");

  FoodAnalysisBlock(this._db);

  /// Pure analysis method that returns the result.
  Future<CaloriesProtocol> analyze({
    required String foodName,
    XFile? image,
    double? volume,
    double? distance,
    String? personId,
  }) async {
    isAnalyzing.value = true;
    analysisStatus.value = "Analyzing $foodName...";

    try {
      // 1. Search FDC if name exists (Reference data for AI)
      Map<String, dynamic>? fdcData;
      if (foodName.isNotEmpty && foodName.length > 2) {
        try {
          fdcData = await FoodDataCentralService.searchFood(foodName);
        } catch (e) {
          debugPrint("FoodAnalysisBlock: FDC search failed: $e");
        }
      }

      // 2. AI Analysis
      final result = await AIFoodCaloriesService.getCalories(
        foodName,
        image: image,
        volume: volume,
        distance: distance,
        fdcData: fdcData,
        personId: personId,
      );
      
      return result;
    } finally {
      isAnalyzing.value = false;
      analysisStatus.value = "";
    }
  }

  /// Starts the food analysis process in the background.
  /// Updates the database record when finished.
  Future<void> analyzeAndSave({
    required String mealId,
    required String foodName,
    XFile? image,
    double? volume,
    double? distance,
    String? personId,
  }) async {
    debugPrint("FoodAnalysisBlock: 🔍 Starting background analysis for meal $mealId");
    
    try {
      final result = await analyze(
        foodName: foodName,
        image: image,
        volume: volume,
        distance: distance,
        personId: personId,
      );

      debugPrint("FoodAnalysisBlock: ✅ Analysis complete for $mealId: ${result.calories} kcal");

      // 3. Update Database
      await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId))).write(
        MealsTableCompanion(
          protein: Value(result.protein.toDouble()),
          carbs: Value(result.carbs.toDouble()),
          fat: Value(result.fat.toDouble()),
          calories: Value(result.calories.toDouble()),
          mealImageUrl: result.imageUrl != null ? Value(result.imageUrl) : const Value.absent(),
          isAnalyzing: const Value(false),
        ),
      );
    } catch (e) {
      debugPrint("FoodAnalysisBlock: ❌ Error during analysis for $mealId: $e");
      try {
        await (_db.update(_db.mealsTable)..where((t) => t.id.equals(mealId))).write(
          const MealsTableCompanion(
            isAnalyzing: Value(false),
          ),
        );
      } catch (_) {}
    }
  }

  void dispose() {
    isAnalyzing.dispose();
    analysisStatus.dispose();
  }
}
