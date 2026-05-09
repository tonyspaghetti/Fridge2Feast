import 'package:flutter/material.dart';
import 'calorie_goal.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  final String email;
  final String userID;
  final String fullName;
  final String age;
  final String cookingSkill;

  const DietaryPreferencesScreen({
    super.key,
    required this.email,
    required this.userID,
    required this.fullName,
    required this.age,
    required this.cookingSkill,
  });

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  final _allergiesController = TextEditingController();

  final Set<String> _selectedPreferences = {};

  final List<_DietOption> _dietOptions = const [
    _DietOption('Vegetarian', Icons.eco_rounded),
    _DietOption('Vegan', Icons.spa_rounded),
    _DietOption('Keto', Icons.local_fire_department_rounded),
    _DietOption('Gluten-Free', Icons.no_food_rounded),
    _DietOption('Halal', Icons.restaurant_rounded),
    _DietOption('Kosher', Icons.dinner_dining_rounded),
    _DietOption('Paleo', Icons.egg_alt_rounded),
    _DietOption('Dairy-Free', Icons.icecream_rounded),
  ];

  @override
  void dispose() {
    _allergiesController.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalorieGoalScreen(
          email: widget.email,
          userID: widget.userID,
          fullName: widget.fullName,
          age: widget.age,
          cookingSkill: widget.cookingSkill,
          dietaryRestrictions: _selectedPreferences.toList(),
          allergies: _allergiesController.text.trim(),
        ),
      ),
    );
  }

  Widget _progressBar(bool active) {
    return Container(
      width: 32,
      height: 5,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _dietCard(_DietOption option) {
    final isSelected = _selectedPreferences.contains(option.title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPreferences.remove(option.title);
          } else {
            _selectedPreferences.add(option.title);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                setState(() {
                  if (isSelected) {
                    _selectedPreferences.remove(option.title);
                  } else {
                    _selectedPreferences.add(option.title);
                  }
                });
              },
              activeColor: const Color(0xFF2E7D32),
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              option.icon,
              size: 22,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                option.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Row(
                children: [
                  _progressBar(true),
                  const SizedBox(width: 6),
                  _progressBar(true),
                  const SizedBox(width: 6),
                  _progressBar(false),
                  const SizedBox(width: 12),
                  const Text(
                    'Step 2 of 3',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Dietary Preferences',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select all that apply to you',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              const Text(
                'Dietary Restrictions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dietOptions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.6,
                ),
                itemBuilder: (context, index) {
                  return _dietCard(_dietOptions[index]);
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Allergies (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  hintText: 'e.g., Peanuts, Shellfish',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
              ),

              const Spacer(),

              _continueButton(),

              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: _continue,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DietOption {
  final String title;
  final IconData icon;

  const _DietOption(this.title, this.icon);
}