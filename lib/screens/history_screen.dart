import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Recipe> _savedRecipes = [];
  List<Recipe> _mealHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final saved = await RecipeService.getSavedRecipes();
    final history = await RecipeService.getMealHistory();
    if (!mounted) return;
    setState(() {
      _savedRecipes = saved;
      _mealHistory = history;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildRecipeCard(Recipe recipe, {bool showRating = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${recipe.cookTime} min • ${recipe.calories} cal',
              style: const TextStyle(fontSize: 12),
            ),
            if (showRating && recipe.userRating != null)
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 14,
                        color: index < recipe.userRating!
                            ? const Color(0xFFFF8F00)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(recipe.dateCooked!),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            if (!showRating && recipe.dateSaved != null)
              Text(
                'Saved on ${_formatDate(recipe.dateSaved!)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text(
          'My Kitchen Diary',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8F00),
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Saved', icon: Icon(Icons.bookmark_border)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _savedRecipes.isEmpty
                    ? _buildEmptyState(
                        'No saved recipes yet',
                        Icons.bookmark_border,
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: _savedRecipes
                            .map((r) => _buildRecipeCard(r))
                            .toList(),
                      ),
                _mealHistory.isEmpty
                    ? _buildEmptyState('No cooking history yet', Icons.history)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: _mealHistory
                            .map((r) => _buildRecipeCard(r, showRating: true))
                            .toList(),
                      ),
              ],
            ),
    );
  }
}
