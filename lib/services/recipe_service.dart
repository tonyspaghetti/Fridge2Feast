import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

class RecipeService {
  static const String _savedRecipesKey = 'savedRecipes';
  static const String _mealHistoryKey = 'mealHistory';

  static Future<List<Recipe>> generateRecipes({
    required List<String> ingredients,
    required List<String> dietaryRestrictions,
    required String allergies,
    required int calorieGoal,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedIngredients = ingredients
        .map((ingredient) => ingredient.trim().toLowerCase())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    if (normalizedIngredients.isEmpty) return [];

    final random = Random();
    final recipePool = <Recipe>[];

    bool has(String keyword) {
      return normalizedIngredients.any((ingredient) => ingredient.contains(keyword));
    }

    int ingredientBoost(List<String> recipeIngredients) {
      final matchedCount = recipeIngredients.where((recipeIngredient) {
        final normalizedRecipeIngredient = recipeIngredient.toLowerCase();
        return normalizedIngredients.any(
          (userIngredient) =>
              normalizedRecipeIngredient.contains(userIngredient) ||
              userIngredient.contains(normalizedRecipeIngredient),
        );
      }).length;

      return (matchedCount * 4).clamp(0, 16).toInt();
    }

    void addRecipe(Recipe recipe) {
      final adjustedMatch = recipe.matchPercentage +
          ingredientBoost(recipe.ingredients) +
          _calorieMatchScore(recipe, calorieGoal) +
          random.nextInt(7);

      recipePool.add(
        recipe.copyWith(matchPercentage: adjustedMatch.clamp(0, 100).toInt()),
      );
    }

    if (has('chicken')) {
      addRecipe(
        Recipe.sample(
          name: '🍗 Herb Roasted Chicken',
          ingredients: [
            'chicken breast',
            'olive oil',
            'garlic',
            'rosemary',
            'salt',
            'pepper',
          ],
          instructions: [
            'Preheat oven to 400°F.',
            'Rub chicken with olive oil, garlic, rosemary, salt, and pepper.',
            'Roast for 25-30 minutes, or until fully cooked.',
            'Let rest for 5 minutes before serving.',
          ],
          cookTime: 35,
          calories: 450,
          matchPercentage: 82,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍛 Chicken Rice Bowl',
          ingredients: [
            'chicken breast',
            'rice',
            'garlic',
            'soy sauce',
            'green onions',
          ],
          instructions: [
            'Cook rice until fluffy.',
            'Slice chicken into small pieces.',
            'Sauté garlic and chicken until fully cooked.',
            'Add soy sauce and simmer for 2 minutes.',
            'Serve chicken over rice with green onions.',
          ],
          cookTime: 25,
          calories: 540,
          matchPercentage: 80,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🥘 Garlic Chicken Skillet',
          ingredients: [
            'chicken breast',
            'garlic',
            'olive oil',
            'onions',
            'pepper',
          ],
          instructions: [
            'Cut chicken into bite-sized pieces.',
            'Heat olive oil in a skillet.',
            'Cook onions and garlic until fragrant.',
            'Add chicken and cook until golden and fully done.',
          ],
          cookTime: 22,
          calories: 390,
          matchPercentage: 78,
        ),
      );
    }

    if (has('rice')) {
      addRecipe(
        Recipe.sample(
          name: '🍚 Garlic Fried Rice',
          ingredients: ['rice', 'garlic', 'soy sauce', 'eggs', 'green onions'],
          instructions: [
            'Heat oil in a wok or large pan.',
            'Add minced garlic and stir for 30 seconds.',
            'Add rice and soy sauce, then stir-fry for 3 minutes.',
            'Push rice aside, scramble eggs, then mix everything together.',
            'Garnish with green onions and serve warm.',
          ],
          cookTime: 15,
          calories: 380,
          matchPercentage: 78,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍲 Simple Rice Bowl',
          ingredients: ['rice', 'mixed vegetables', 'olive oil', 'garlic', 'salt'],
          instructions: [
            'Warm cooked rice in a pan.',
            'Sauté vegetables with garlic and olive oil.',
            'Combine rice and vegetables.',
            'Season with salt and serve warm.',
          ],
          cookTime: 18,
          calories: 420,
          matchPercentage: 72,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🌶️ Spicy Rice Stir-fry',
          ingredients: ['rice', 'garlic', 'onions', 'red pepper flakes', 'soy sauce'],
          instructions: [
            'Heat oil in a large pan.',
            'Cook onions and garlic until soft.',
            'Add rice, soy sauce, and red pepper flakes.',
            'Stir-fry until hot and slightly crispy.',
          ],
          cookTime: 16,
          calories: 360,
          matchPercentage: 70,
        ),
      );
    }

    if (has('broccoli') || has('pasta')) {
      addRecipe(
        Recipe.sample(
          name: '🥦 Broccoli Pasta',
          ingredients: [
            'pasta',
            'broccoli',
            'garlic',
            'olive oil',
            'parmesan',
            'red pepper flakes',
          ],
          instructions: [
            'Cook pasta according to package instructions.',
            'Steam broccoli for 5 minutes.',
            'Sauté garlic in olive oil until fragrant.',
            'Toss pasta and broccoli with the garlic oil.',
            'Top with parmesan and red pepper flakes.',
          ],
          cookTime: 20,
          calories: 520,
          matchPercentage: 74,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🥦 Broccoli Garlic Sauté',
          ingredients: ['broccoli', 'garlic', 'olive oil', 'lemon', 'salt', 'pepper'],
          instructions: [
            'Cut broccoli into florets.',
            'Heat olive oil in a skillet.',
            'Add garlic and broccoli.',
            'Cook until tender-crisp, then finish with lemon.',
          ],
          cookTime: 14,
          calories: 210,
          matchPercentage: 76,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍝 Quick Veggie Pasta',
          ingredients: ['pasta', 'tomatoes', 'garlic', 'olive oil', 'onions'],
          instructions: [
            'Boil pasta until al dente.',
            'Sauté garlic, onions, and tomatoes.',
            'Add pasta to the pan and toss everything together.',
            'Serve warm.',
          ],
          cookTime: 22,
          calories: 480,
          matchPercentage: 71,
        ),
      );
    }

    if (has('egg') || has('eggs')) {
      addRecipe(
        Recipe.sample(
          name: '🍳 Veggie Egg Scramble',
          ingredients: ['eggs', 'spinach', 'tomatoes', 'onions', 'salt', 'pepper'],
          instructions: [
            'Whisk eggs with salt and pepper.',
            'Sauté onions and tomatoes for 2-3 minutes.',
            'Add spinach and cook until wilted.',
            'Pour in eggs and gently scramble until set.',
          ],
          cookTime: 12,
          calories: 310,
          matchPercentage: 80,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🥚 Simple Omelette',
          ingredients: ['eggs', 'cheese', 'onions', 'pepper', 'salt'],
          instructions: [
            'Beat eggs with salt and pepper.',
            'Pour eggs into a heated nonstick pan.',
            'Add onions and cheese.',
            'Fold omelette and cook until set.',
          ],
          cookTime: 10,
          calories: 330,
          matchPercentage: 77,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍚 Egg Rice Bowl',
          ingredients: ['eggs', 'rice', 'green onions', 'soy sauce', 'garlic'],
          instructions: [
            'Warm rice in a bowl.',
            'Scramble eggs in a pan.',
            'Add eggs over rice.',
            'Top with soy sauce and green onions.',
          ],
          cookTime: 13,
          calories: 410,
          matchPercentage: 79,
        ),
      );
    }

    if (has('tomato') || has('tomatoes') || has('lettuce') || has('cucumber')) {
      addRecipe(
        Recipe.sample(
          name: '🥗 Fresh Garden Bowl',
          ingredients: [
            'lettuce',
            'tomatoes',
            'cucumber',
            'olive oil',
            'lemon',
            'salt',
            'pepper',
          ],
          instructions: [
            'Wash and chop all vegetables.',
            'Whisk olive oil, lemon juice, salt, and pepper.',
            'Toss vegetables with dressing.',
            'Serve immediately for best texture.',
          ],
          cookTime: 10,
          calories: 220,
          matchPercentage: 78,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🥒 Cucumber Tomato Salad',
          ingredients: ['cucumber', 'tomatoes', 'olive oil', 'lemon', 'salt', 'pepper'],
          instructions: [
            'Slice cucumbers and tomatoes.',
            'Mix olive oil, lemon juice, salt, and pepper.',
            'Toss vegetables with dressing.',
            'Chill briefly before serving.',
          ],
          cookTime: 8,
          calories: 160,
          matchPercentage: 76,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍅 Tomato Garlic Toast',
          ingredients: ['tomatoes', 'garlic', 'bread', 'olive oil', 'salt'],
          instructions: [
            'Toast bread until crisp.',
            'Dice tomatoes and mix with garlic and olive oil.',
            'Spoon tomato mixture onto toast.',
            'Season with salt and serve.',
          ],
          cookTime: 12,
          calories: 280,
          matchPercentage: 70,
        ),
      );
    }


    if (recipePool.isNotEmpty) {
      final flexibleIngredients = normalizedIngredients.take(3).toList();
      final mainIngredient = flexibleIngredients.first;

      addRecipe(
        Recipe.sample(
          name: '🍽️ Chef\'s Choice Skillet',
          ingredients: [...flexibleIngredients, 'olive oil', 'garlic', 'salt', 'pepper'],
          instructions: [
            'Chop your available ingredients into small pieces.',
            'Heat olive oil in a skillet over medium heat.',
            'Add garlic, then cook the ingredients until tender.',
            'Season with salt and pepper before serving.',
          ],
          cookTime: 20,
          calories: 340,
          matchPercentage: 68,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🥣 Quick $mainIngredient Bowl',
          ingredients: [...flexibleIngredients, 'rice', 'olive oil', 'lemon', 'salt'],
          instructions: [
            'Prepare a warm base using rice or another available grain.',
            'Cook your main ingredients until tender.',
            'Layer everything in a bowl.',
            'Finish with lemon, salt, and a drizzle of olive oil.',
          ],
          cookTime: 18,
          calories: 390,
          matchPercentage: 66,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍲 Fridge Cleanout Soup',
          ingredients: [...flexibleIngredients, 'water', 'garlic', 'onions', 'salt'],
          instructions: [
            'Add chopped ingredients to a pot.',
            'Cover with water or broth.',
            'Simmer until everything is soft and flavorful.',
            'Season to taste and serve warm.',
          ],
          cookTime: 28,
          calories: 300,
          matchPercentage: 64,
        ),
      );
    }

    if (recipePool.isEmpty) {
      addRecipe(
        Recipe.sample(
          name: '🥘 Simple Pantry Stir-fry',
          ingredients: [
            'mixed vegetables',
            'soy sauce',
            'garlic',
            'ginger',
            'sesame oil',
          ],
          instructions: [
            'Heat oil in a large pan.',
            'Add garlic and ginger, then stir for 30 seconds.',
            'Add vegetables and stir-fry for 5-7 minutes.',
            'Add soy sauce and cook for 1 more minute.',
          ],
          cookTime: 15,
          calories: 250,
          matchPercentage: 65,
        ),
      );

      addRecipe(
        Recipe.sample(
          name: '🍲 Flexible Fridge Bowl',
          ingredients: [
            'mixed vegetables',
            'rice',
            'olive oil',
            'garlic',
            'salt',
          ],
          instructions: [
            'Cook any available vegetables in olive oil.',
            'Add garlic and season lightly.',
            'Serve over rice or another grain if available.',
          ],
          cookTime: 18,
          calories: 330,
          matchPercentage: 62,
        ),
      );
    }

    final allergens = _parseAllergies(allergies);

    final filteredRecipes = recipePool.where((recipe) {
      return !_containsAllergen(recipe, allergens) &&
          _matchesDietaryRestrictions(recipe, dietaryRestrictions);
    }).toList();

    filteredRecipes.shuffle(random);

    final maxResults = filteredRecipes.length <= 4 ? filteredRecipes.length : 4;
    final selectedRecipes = filteredRecipes.take(maxResults).toList();

    selectedRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return selectedRecipes;
  }

  static Future<void> saveRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = prefs.getStringList(_savedRecipesKey) ?? [];

    final alreadySaved = savedRecipesJson.any((jsonStr) {
      try {
        final savedRecipe = Recipe.fromJson(jsonDecode(jsonStr));
        return savedRecipe.id == recipe.id;
      } catch (_) {
        return false;
      }
    });

    if (alreadySaved) return;

    final recipeWithDate = recipe.copyWith(
      dateSaved: DateTime.now(),
      clearDateCooked: true,
      clearUserRating: true,
    );

    savedRecipesJson.insert(0, jsonEncode(recipeWithDate.toJson()));
    await prefs.setStringList(_savedRecipesKey, savedRecipesJson);
  }

  static Future<void> removeSavedRecipe(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = prefs.getStringList(_savedRecipesKey) ?? [];

    final updatedList = savedRecipesJson.where((jsonStr) {
      try {
        final recipe = Recipe.fromJson(jsonDecode(jsonStr));
        return recipe.id != recipeId;
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setStringList(_savedRecipesKey, updatedList);
  }

  static Future<List<Recipe>> getSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = prefs.getStringList(_savedRecipesKey) ?? [];
    return _decodeRecipeList(savedRecipesJson);
  }

  static Future<void> addToMealHistory(Recipe recipe, int rating) async {
    final prefs = await SharedPreferences.getInstance();
    final mealHistoryJson = prefs.getStringList(_mealHistoryKey) ?? [];

    final cookedRecipe = recipe.copyWith(
      dateCooked: DateTime.now(),
      userRating: rating.clamp(1, 5).toInt(),
      clearDateSaved: true,
    );

    mealHistoryJson.insert(0, jsonEncode(cookedRecipe.toJson()));
    await prefs.setStringList(_mealHistoryKey, mealHistoryJson);
  }

  static Future<List<Recipe>> getMealHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final mealHistoryJson = prefs.getStringList(_mealHistoryKey) ?? [];
    return _decodeRecipeList(mealHistoryJson);
  }

  static List<Recipe> _decodeRecipeList(List<String> jsonList) {
    final recipes = <Recipe>[];
    for (final jsonStr in jsonList) {
      try {
        recipes.add(Recipe.fromJson(jsonDecode(jsonStr)));
      } catch (_) {
        // Skip corrupted saved entries instead of crashing the screen.
      }
    }
    return recipes;
  }

  static List<String> _parseAllergies(String allergies) {
    return allergies
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static bool _containsAllergen(Recipe recipe, List<String> allergens) {
    final recipeText = recipe.ingredients.join(' ').toLowerCase();
    return allergens.any((allergen) => recipeText.contains(allergen));
  }

  static bool _matchesDietaryRestrictions(
    Recipe recipe,
    List<String> dietaryRestrictions,
  ) {
    final restrictions = dietaryRestrictions.map((item) => item.toLowerCase()).toList();
    final ingredients = recipe.ingredients.join(' ').toLowerCase();

    final hasMeatOrSeafood = ingredients.contains('chicken') ||
        ingredients.contains('beef') ||
        ingredients.contains('pork') ||
        ingredients.contains('fish') ||
        ingredients.contains('shrimp') ||
        ingredients.contains('shellfish');

    final hasDairy = ingredients.contains('milk') ||
        ingredients.contains('cheese') ||
        ingredients.contains('parmesan') ||
        ingredients.contains('butter') ||
        ingredients.contains('cream') ||
        ingredients.contains('yogurt');

    final hasEgg = ingredients.contains('egg');
    final hasGluten = ingredients.contains('pasta') ||
        ingredients.contains('bread') ||
        ingredients.contains('flour') ||
        ingredients.contains('soy sauce');
    final hasHighCarb = ingredients.contains('rice') ||
        ingredients.contains('pasta') ||
        ingredients.contains('bread');
    final hasPork = ingredients.contains('pork');
    final hasShellfish = ingredients.contains('shellfish') || ingredients.contains('shrimp');

    if (restrictions.contains('vegetarian') && hasMeatOrSeafood) return false;
    if (restrictions.contains('vegan') && (hasMeatOrSeafood || hasDairy || hasEgg)) return false;
    if (restrictions.contains('gluten-free') && hasGluten) return false;
    if (restrictions.contains('dairy-free') && hasDairy) return false;
    if (restrictions.contains('keto') && hasHighCarb) return false;
    if (restrictions.contains('halal') && hasPork) return false;
    if (restrictions.contains('kosher') && (hasPork || hasShellfish)) return false;
    if (restrictions.contains('paleo') && (hasHighCarb || hasDairy)) return false;

    return true;
  }

  static int _calorieMatchScore(Recipe recipe, int calorieGoal) {
    final targetPerMeal = calorieGoal / 3;
    final difference = (recipe.calories - targetPerMeal).abs();

    if (difference <= 100) return 8;
    if (difference <= 200) return 4;
    return 0;
  }
}
