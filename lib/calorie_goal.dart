import 'package:flutter/material.dart';

class CalorieGoalScreen extends StatefulWidget {
  const CalorieGoalScreen({super.key});

  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {
  double _calories = 2000;

  int get calories => _calories.round();
  int get perMeal => (calories / 3).round();
  int get perDayDiv7 => (calories / 7).round();
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

  void _finishSetup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup complete')),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "We'll suggest recipes that fit your target",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 44),

              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 34,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                  ),
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
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'calories per day',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '1,200',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '4,000',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.black,
                  overlayColor: Colors.black.withValues(alpha: 0.10),
                  trackHeight: 5,
                ),
                child: Slider(
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
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    value: perMeal.toString(),
                    label: 'Per Meal',
                    color: const Color(0xFF2E7D32),
                  ),
                  _statItem(
                    value: perDayDiv7.toString(),
                    label: 'Per Day ÷7',
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

              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: _finishSetup,
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