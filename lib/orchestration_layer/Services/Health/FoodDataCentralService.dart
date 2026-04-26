import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoodDataCentralService {
  // Demo key from USDA. Users should ideally use their own.
  static String get _apiKey => dotenv.env['USDA_API_KEY'] ?? "";
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Search for food and return primary nutritional data
  static Future<Map<String, dynamic>?> searchFood(String query) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/foods/search?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&pageSize=1',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List foods = data['foods'] ?? [];

        if (foods.isNotEmpty) {
          final food = foods.first;
          final nutrients = food['foodNutrients'] as List;

          // Helper to find nutrient by ID or name
          double getVal(dynamic nameOrId) {
            final n = nutrients.firstWhere(
              (element) =>
                  element['nutrientName'].toString().toLowerCase().contains(
                    nameOrId.toString().toLowerCase(),
                  ) ||
                  element['nutrientId'].toString() == nameOrId.toString(),
              orElse: () => null,
            );
            return n != null ? (n['value'] as num).toDouble() : 0.0;
          }

          return {
            'name': food['description'],
            'calories': getVal('Energy'),
            'protein': getVal('Protein'),
            'fat': getVal('Total lipid (fat)'),
            'carbs': getVal('Carbohydrate, by difference'),
            'servingSize': food['servingSize'],
            'servingSizeUnit': food['servingSizeUnit'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error searching FoodData Central: $e');
    }
    return null;
  }
}
