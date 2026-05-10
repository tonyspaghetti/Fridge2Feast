import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isCookingMode = false;
  int _currentStep = 0;
  bool _isSaved = false;
  final Map<String, bool> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    for (final ingredient in widget.recipe.ingredients) {
      _checkedIngredients[ingredient] = false;
    }
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await RecipeService.getSavedRecipes();
    if (!mounted) return;
    setState(() {
      _isSaved = saved.any((recipe) => recipe.id == widget.recipe.id);
    });
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await RecipeService.removeSavedRecipe(widget.recipe.id);
      if (!mounted) return;
      setState(() => _isSaved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe removed from saved')),
      );
      return;
    }

    await RecipeService.saveRecipe(widget.recipe);
    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe saved!')),
    );
  }

  void _showCompletionDialog() {
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('🎉 Meal Complete!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you rate this recipe?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      return IconButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starNumber;
                          });
                        },
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFF8F00),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await RecipeService.addToMealHistory(widget.recipe, selectedRating);
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    setState(() {
                      _isCookingMode = false;
                      _currentStep = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal added to your kitchen diary!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNutritionBar() {
    final total = widget.recipe.protein + widget.recipe.carbs + widget.recipe.fat;
    final proteinPercent = total > 0 ? (widget.recipe.protein / total) : 0.33;
    final carbsPercent = total > 0 ? (widget.recipe.carbs / total) : 0.33;
    final fatPercent = total > 0 ? (widget.recipe.fat / total) : 0.33;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('${widget.recipe.calories}', 'Calories', const Color(0xFFFF8F00)),
              _buildNutritionItem('${widget.recipe.protein}g', 'Protein', const Color(0xFF2E7D32)),
              _buildNutritionItem('${widget.recipe.carbs}g', 'Carbs', const Color(0xFF2196F3)),
              _buildNutritionItem('${widget.recipe.fat}g', 'Fat', const Color(0xFF9C27B0)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Expanded(
                  flex: (proteinPercent * 100).round().clamp(1, 100).toInt(),
                  child: Container(height: 6, color: const Color(0xFF2E7D32)),
                ),
                Expanded(
                  flex: (carbsPercent * 100).round().clamp(1, 100).toInt(),
                  child: Container(height: 6, color: const Color(0xFF2196F3)),
                ),
                Expanded(
                  flex: (fatPercent * 100).round().clamp(1, 100).toInt(),
                  child: Container(height: 6, color: const Color(0xFF9C27B0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildNormalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionBar(),
          const SizedBox(height: 24),
          const Text(
            'Ingredients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...widget.recipe.ingredients.map((ingredient) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _checkedIngredients[ingredient] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _checkedIngredients[ingredient] = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ingredient)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...widget.recipe.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFFFF8F00)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCookingMode() {
    final currentInstruction = widget.recipe.instructions[_currentStep];
    final isLastStep = _currentStep == widget.recipe.instructions.length - 1;

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / widget.recipe.instructions.length,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF2E7D32),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFFFF8F00)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_currentStep + 1}',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    currentInstruction,
                    style: const TextStyle(fontSize: 20, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastStep) {
                      _showCompletionDialog();
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isLastStep ? 'Complete' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isCookingMode ? Colors.white : const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: Text(
          widget.recipe.name,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: const Color(0xFFFF8F00),
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: _isCookingMode ? _buildCookingMode() : _buildNormalView(),
      floatingActionButton: _isCookingMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _isCookingMode = true),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Cooking'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
    );
  }
}
