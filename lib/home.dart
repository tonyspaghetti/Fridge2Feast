import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_ingredients.dart';
import 'database.dart';
import 'settings.dart';

// main dashboard users see after onboarding
class HomeScreen extends StatefulWidget {
  final String fullName;

  const HomeScreen({
    super.key,
    required this.fullName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = 'Chef';
  int _ingredientCount = 0; 
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fullName = widget.fullName;
    _loadSavedProfile();
    _loadIngredientCount();
  }

  Future<void> _loadIngredientCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if(userID != null){
      final count = await _db.getIngredientCount(userID);
      if(mounted){
        setState((){
          _ingredientCount = count;
        });
      }
    }
  }

  void _addIngredients() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AddIngredientsScreen(),
    ),
  );
  
  await _loadIngredientCount();

  if (result != null && result is List) {
    // Ingredients were added
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${result.length} ingredient(s) to your kitchen!'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    setState(() {

    });
  }
}

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if(mounted){
      setState(() {
      _fullName = prefs.getString('fullName') ?? widget.fullName;
    });
    }
  }

  String get firstName {
    final trimmed = _fullName.trim();
    if (trimmed.isEmpty) return 'Chef';
    return trimmed.split(' ').first;
  }

  Future<void> _openSettings() async {
    final didSave = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          fullName: _fullName,
        ),
      ),
    );

    if (didSave == true) {
      await _loadSavedProfile();
    }
  }

  Widget _statCard({
    required String number,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2E7D32),
              Color(0xFFFF8F00),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
  required String text,
  required VoidCallback onPressed,
  }) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool hasIngredients = _ingredientCount > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFFFF8F00),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome back, $firstName! 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _openSettings,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's create something delicious",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statCard(number: _ingredientCount.toString(), label: 'Ingredients'),
                        const SizedBox(width: 10),
                        _statCard(number: '0', label: 'Meals Cooked'),
                        const SizedBox(width: 10),
                        _statCard(number: '0', label: 'Tracked'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _outlineButton(
                text: 'Add Ingredients',
                //onPressed: () => _comingSoon(context, 'Add ingredients'),
                onPressed: _addIngredients,
              ),

              const SizedBox(height: 14),

              _gradientButton(
                text: 'Find Recipes',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => _comingSoon(context, 'Recipe generation'),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Virtual Kitchen',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _comingSoon(context, 'History'),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('History'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 46,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your kitchen is empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start by adding ingredients you have at home',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _gradientButton(
                      text: 'Add Your First Ingredient',
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          _comingSoon(context, 'Add your first ingredient'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}