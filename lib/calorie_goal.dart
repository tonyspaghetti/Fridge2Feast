import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class CalorieGoalScreen extends StatefulWidget {
  final String email;
  final String userID;
  final String fullName;
  final String age;
  final String cookingSkill;
  final List<String> dietaryRestrictions;
  final String allergies;

  const CalorieGoalScreen({
    super.key,
    required this.email,
    required this.userID,
    required this.fullName,
    required this.age,
    required this.cookingSkill,
    required this.dietaryRestrictions,
    required this.allergies,
  });

  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {
  double _calories = 2000;

  int get calories => _calories.round();
  int get perMeal => (calories / 3).round();
  int get perWeek => calories * 7;

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

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasCompletedSetup', true);
    await prefs.setString('email', widget.email);
    await prefs.setString('userID', widget.userID);
    await prefs.setString('fullName', widget.fullName);
    await prefs.setString('age', widget.age);
    await prefs.setString('cookingSkill', widget.cookingSkill);
    await prefs.setStringList(
      'dietaryRestrictions',
      widget.dietaryRestrictions,
    );
    await prefs.setString('allergies', widget.allergies);
    await prefs.setDouble('dailyCalories', _calories);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          fullName: widget.fullName,
        ),
      ),
      (route) => false,
    );
  }

  Widget _gradientButton() {
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
          onPressed: _finishSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Complete Setup',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _statItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = _calories.round();

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
                  _progressBar(true),
                  const SizedBox(width: 12),
                  const Text(
                    'Step 3 of 3',
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
                'Daily Calorie Goal',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "We'll suggest recipes that fit your target",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 44),

              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 42,
                      color: Color(0xFFFF8F00),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      calories.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('calories per day'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Slider(
                value: _calories,
                min: 1200,
                max: 4000,
                divisions: 28,
                onChanged: (value) {
                  setState(() {
                    _calories = value;
                  });
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    value: perMeal.toString(),
                    label: 'Per Meal',
                    color: const Color(0xFF2E7D32),
                  ),
                  _statItem(
                    value: calories.toString(),
                    label: 'Per Day',
                    color: const Color(0xFFFF8F00),
                  ),
                  _statItem(
                    value: perWeek.toString(),
                    label: 'Per Week',
                    color: const Color(0xFF6A1B9A),
                  ),
                ],
              ),

              const Spacer(),

              _gradientButton(),
            ],
          ),
        ),
      ),
    );
  }
}