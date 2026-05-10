class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final List<String> instructions;
  final int cookTime;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int matchPercentage;
  final String difficulty;
  final List<String> mainIngredients;
  final DateTime? dateSaved;
  final DateTime? dateCooked;
  final int? userRating;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.cookTime,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.matchPercentage,
    required this.difficulty,
    required this.mainIngredients,
    this.dateSaved,
    this.dateCooked,
    this.userRating,
  });

  factory Recipe.sample({
    required String name,
    required List<String> ingredients,
    required List<String> instructions,
    required int cookTime,
    required int calories,
    required int matchPercentage,
  }) {
    final stableId = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return Recipe(
      id: stableId,
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      cookTime: cookTime,
      calories: calories,
      protein: (calories * 0.15 / 4).round(),
      carbs: (calories * 0.55 / 4).round(),
      fat: (calories * 0.30 / 9).round(),
      matchPercentage: matchPercentage.clamp(0, 100).toInt(),
      difficulty: cookTime <= 20 ? 'Easy' : (cookTime <= 45 ? 'Medium' : 'Hard'),
      mainIngredients: ingredients.take(3).toList(),
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    List<String>? ingredients,
    List<String>? instructions,
    int? cookTime,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? matchPercentage,
    String? difficulty,
    List<String>? mainIngredients,
    DateTime? dateSaved,
    DateTime? dateCooked,
    int? userRating,
    bool clearDateSaved = false,
    bool clearDateCooked = false,
    bool clearUserRating = false,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookTime: cookTime ?? this.cookTime,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      difficulty: difficulty ?? this.difficulty,
      mainIngredients: mainIngredients ?? this.mainIngredients,
      dateSaved: clearDateSaved ? null : (dateSaved ?? this.dateSaved),
      dateCooked: clearDateCooked ? null : (dateCooked ?? this.dateCooked),
      userRating: clearUserRating ? null : (userRating ?? this.userRating),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'cookTime': cookTime,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'matchPercentage': matchPercentage,
      'difficulty': difficulty,
      'mainIngredients': mainIngredients,
      'dateSaved': dateSaved?.toIso8601String(),
      'dateCooked': dateCooked?.toIso8601String(),
      'userRating': userRating,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime? asDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    List<String> asStringList(dynamic value) {
      if (value is List) return value.map((item) => item.toString()).toList();
      return const [];
    }

    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Recipe',
      ingredients: asStringList(json['ingredients']),
      instructions: asStringList(json['instructions']),
      cookTime: asInt(json['cookTime']),
      calories: asInt(json['calories']),
      protein: asInt(json['protein']),
      carbs: asInt(json['carbs']),
      fat: asInt(json['fat']),
      matchPercentage: asInt(json['matchPercentage']).clamp(0, 100).toInt(),
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      mainIngredients: asStringList(json['mainIngredients']),
      dateSaved: asDate(json['dateSaved']),
      dateCooked: asDate(json['dateCooked']),
      userRating: json['userRating'] == null ? null : asInt(json['userRating']),
    );
  }
}
