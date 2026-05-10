import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipeResultsScreen extends StatefulWidget {
  final List<String> ingredients;

  const RecipeResultsScreen({super.key, required this.ingredients});

  @override
  State<RecipeResultsScreen> createState() => _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends State<RecipeResultsScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<String> _dietaryRestrictions = [];
  String _allergies = '';
  int _calorieGoal = 2000;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _dietaryRestrictions = prefs.getStringList('dietaryRestrictions') ?? [];
      _allergies = prefs.getString('allergies') ?? '';
      _calorieGoal = prefs.getDouble('dailyCalories')?.round() ?? 2000;
    });

    await _generateRecipes();
  }

  Future<void> _generateRecipes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipes = await RecipeService.generateRecipes(
        ingredients: widget.ingredients,
        dietaryRestrictions: _dietaryRestrictions,
        allergies: _allergies,
        calorieGoal: _calorieGoal,
      );

      if (!mounted) return;

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to generate recipes. Please try again.';
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E7D32)),
          SizedBox(height: 16),
          Text(
            'AI is cooking up some recipes...',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            const Text(
              'No matching recipes found',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ingredients.isEmpty
                  ? 'Go back and add ingredients first.'
                  : 'Try adding more ingredients or changing your dietary settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    Color matchColor;
    if (recipe.matchPercentage >= 85) {
      matchColor = const Color(0xFF2E7D32);
    } else if (recipe.matchPercentage >= 60) {
      matchColor = const Color(0xFFFF8F00);
    } else {
      matchColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: matchColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: matchColor),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.matchPercentage}%',
                          style: TextStyle(
                            color: matchColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.timer_outlined, '${recipe.cookTime} min'),
                  _buildInfoChip(Icons.local_fire_department, '${recipe.calories} cal'),
                  _buildInfoChip(Icons.straighten, recipe.difficulty),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.mainIngredients.map((ingredient) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ingredient,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text(
          'Recipe Suggestions',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _recipes.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.kitchen, size: 20, color: Color(0xFFFF8F00)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Using: ${widget.ingredients.take(4).join(', ')}${widget.ingredients.length > 4 ? '...' : ''}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._recipes.map(_buildRecipeCard),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton.icon(
                              onPressed: _generateRecipes,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Generate New Recipes'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }
}
