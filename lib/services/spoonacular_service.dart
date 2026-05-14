import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'package:flutter/foundation.dart';

class SpoonacularRecipeService {
  static const String _apiKey = String.fromEnvironment(
    'SPOONACULAR_API_KEY',
    defaultValue: 'PASTE_YOUR_SPOONACULAR_API_KEY',
  );

  static const String _baseUrl = 'https://api.spoonacular.com';

  static bool get isConfigured {
    return _apiKey.trim().isNotEmpty &&
        !_apiKey.contains('PASTE_YOUR_SPOONACULAR_API_KEY');
  }

  static Future<List<Recipe>> generateRecipes({
    required List<String> ingredients,
    required List<String> dietaryRestrictions,
    required String allergies,
    required int calorieGoal,
    int number = 6,
  }) async {
    if (!isConfigured) {
      throw Exception('Spoonacular API key is not configured.');
    }

    final ingredientQuery = ingredients
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(12)
        .join(',');

    if (ingredientQuery.isEmpty) {
      throw Exception('No ingredients provided.');
    }

    final targetPerMeal = (calorieGoal / 3).round();
    final minCalories = (targetPerMeal - 250).clamp(100, 2000);
    final maxCalories = (targetPerMeal + 250).clamp(100, 2000);

    final uri = Uri.parse('$_baseUrl/recipes/complexSearch').replace(
      queryParameters: {
        'apiKey': _apiKey,
        'includeIngredients': ingredientQuery,
        'number': number.toString(),
        'addRecipeInformation': 'true',
        'addRecipeNutrition': 'true',
        'fillIngredients': 'true',
        'sort': 'max-used-ingredients',
        'instructionsRequired': 'true',
        'ignorePantry': 'true',
        'minCalories': minCalories.toString(),
        'maxCalories': maxCalories.toString(),
        if (_dietParameter(dietaryRestrictions).isNotEmpty)
          'diet': _dietParameter(dietaryRestrictions),
        if (_intolerancesParameter(dietaryRestrictions, allergies).isNotEmpty)
          'intolerances': _intolerancesParameter(
            dietaryRestrictions,
            allergies,
          ),
      },
    );
    debugPrint('--- Spoonacular Debug ---');
    debugPrint('Configured: $isConfigured');
    debugPrint('Ingredients: $ingredientQuery');
    debugPrint('Diet: ${_dietParameter(dietaryRestrictions)}');
    debugPrint(
      'Intolerances: ${_intolerancesParameter(dietaryRestrictions, allergies)}',
    );
    debugPrint(
      'URL without key: ${uri.toString().replaceAll(_apiKey, 'HIDDEN_API_KEY')}',
    );
    debugPrint('API key length: ${_apiKey.length}');
    debugPrint('-------------------------');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    debugPrint('Spoonacular status code: ${response.statusCode}');
    debugPrint('Spoonacular raw response: ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Spoonacular request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'];

    if (results is! List || results.isEmpty) {
      throw Exception('Spoonacular returned no recipes.');
    }

final recipes = results
    .whereType<Map<String, dynamic>>()
    .map((json) => _recipeFromSpoonacularJson(json, ingredients))
    .toList();

recipes.sort(
  (a, b) => b.matchPercentage.compareTo(a.matchPercentage),
);

return recipes;
  }

  static Recipe _recipeFromSpoonacularJson(
    Map<String, dynamic> json,
    List<String> userIngredients,
  ) {
    final id =
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final title = _stripHtml(json['title']?.toString() ?? 'Spoonacular Recipe');

    final usedIngredientCount = _toInt(json['usedIngredientCount'], 0);
    final missedIngredientCount = _toInt(json['missedIngredientCount'], 0);
    final totalCompared = usedIngredientCount + missedIngredientCount;

    final matchPercentage = totalCompared == 0
        ? 80
        : ((usedIngredientCount / totalCompared) * 100).round().clamp(0, 100);

    final readyInMinutes = _toInt(json['readyInMinutes'], 30);

    final nutrition = json['nutrition'];
    final nutrients = nutrition is Map<String, dynamic>
        ? nutrition['nutrients']
        : null;

    final calories = _nutrientAmount(nutrients, 'Calories').round();
    final protein = _nutrientAmount(nutrients, 'Protein').round();
    final carbs = _nutrientAmount(nutrients, 'Carbohydrates').round();
    final fat = _nutrientAmount(nutrients, 'Fat').round();

    final ingredients = _extractIngredients(json);
    final instructions = _extractInstructions(json);

    return Recipe(
      id: 'spoonacular-$id',
      name: title,
      ingredients: ingredients.isEmpty ? userIngredients : ingredients,
      instructions: instructions.isEmpty
          ? ['Open the original recipe source for detailed instructions.']
          : instructions,
      cookTime: readyInMinutes,
      calories: calories == 0 ? 500 : calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      matchPercentage: matchPercentage,
      difficulty: readyInMinutes <= 20
          ? 'Easy'
          : readyInMinutes <= 45
          ? 'Medium'
          : 'Hard',
      mainIngredients: ingredients.take(3).toList(),
    );
  }

 static List<String> _extractIngredients(Map<String, dynamic> json) {
  final extended = json['extendedIngredients'];

  if (extended is! List) return [];

  return extended
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final original = item['original']?.toString().trim();
        final originalString = item['originalString']?.toString().trim();
        final name = item['name']?.toString().trim();

        final value = (original != null && original.isNotEmpty)
            ? original
            : (originalString != null && originalString.isNotEmpty)
                ? originalString
                : name ?? '';

        return _stripHtml(value);
      })
      .where((item) {
        final lower = item.toLowerCase();

        if (item.trim().isEmpty) return false;

        // Prevent recipe steps from accidentally appearing as ingredients.
        if (lower.length > 120) return false;
        if (lower.contains('cook over')) return false;
        if (lower.contains('stirring occasionally')) return false;
        if (lower.contains('serve immediately')) return false;
        if (lower.contains('reduce the heat')) return false;
        if (lower.contains('preheat')) return false;
        if (lower.contains('add the')) return false;

        return true;
      })
      .toList();
}
static List<String> _extractInstructions(Map<String, dynamic> json) {
  final analyzed = json['analyzedInstructions'];

  if (analyzed is List && analyzed.isNotEmpty) {
    final steps = <String>[];

    for (final group in analyzed) {
      if (group is Map<String, dynamic>) {
        final groupSteps = group['steps'];

        if (groupSteps is List) {
          for (final step in groupSteps) {
            if (step is Map<String, dynamic>) {
              final text = step['step']?.toString().trim();

              if (text != null && text.isNotEmpty) {
                steps.add(_stripHtml(text));
              }
            }
          }
        }
      }
    }

    if (steps.isNotEmpty) {
      return steps.toSet().toList();
    }
  }

  final rawInstructions = json['instructions']?.toString();

  if (rawInstructions == null || rawInstructions.trim().isEmpty) {
    return [];
  }

  final cleaned = _stripHtml(rawInstructions)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return cleaned
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((step) => step.trim())
      .where((step) => step.isNotEmpty)
      .toSet()
      .toList();
}
  static double _nutrientAmount(dynamic nutrients, String name) {
    if (nutrients is! List) return 0;

    for (final nutrient in nutrients) {
      if (nutrient is Map<String, dynamic>) {
        final nutrientName = nutrient['name']?.toString().toLowerCase();

        if (nutrientName == name.toLowerCase()) {
          final amount = nutrient['amount'];
          if (amount is num) return amount.toDouble();
          if (amount is String) return double.tryParse(amount) ?? 0;
        }
      }
    }

    return 0;
  }

  static String _dietParameter(List<String> dietaryRestrictions) {
    final restrictions = dietaryRestrictions.map((r) => r.toLowerCase());

    if (restrictions.contains('vegan')) return 'vegan';
    if (restrictions.contains('vegetarian')) return 'vegetarian';
    if (restrictions.contains('gluten-free')) return 'gluten free';
    if (restrictions.contains('ketogenic') || restrictions.contains('keto')) {
      return 'ketogenic';
    }
    if (restrictions.contains('paleo')) return 'paleo';

    return '';
  }

  static String _intolerancesParameter(
    List<String> dietaryRestrictions,
    String allergies,
  ) {
    final values = <String>{};

    final restrictions = dietaryRestrictions.map((r) => r.toLowerCase());

    if (restrictions.contains('dairy-free')) values.add('dairy');
    if (restrictions.contains('gluten-free')) values.add('gluten');

    final allergyItems = allergies
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty);

    for (final allergy in allergyItems) {
      if (allergy.contains('peanut')) values.add('peanut');
      if (allergy.contains('tree nut') || allergy.contains('nuts')) {
        values.add('tree nut');
      }
      if (allergy.contains('egg')) values.add('egg');
      if (allergy.contains('soy')) values.add('soy');
      if (allergy.contains('wheat')) values.add('wheat');
      if (allergy.contains('seafood')) values.add('seafood');
      if (allergy.contains('shellfish') || allergy.contains('shrimp')) {
        values.add('shellfish');
      }
      if (allergy.contains('dairy') || allergy.contains('milk')) {
        values.add('dairy');
      }
      if (allergy.contains('gluten')) values.add('gluten');
      if (allergy.contains('sesame')) values.add('sesame');
    }

    return values.join(',');
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
