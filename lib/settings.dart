import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String fullName;

  const SettingsScreen({
    super.key,
    required this.fullName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _selectedSkill = 'Beginner';
  double _calories = 2000;

  final Set<String> _selectedDietaryRestrictions = {};

  final List<String> _dietaryOptions = const [
    'Vegetarian',
    'Vegan',
    'Keto',
    'Gluten-Free',
    'Halal',
    'Kosher',
    'Paleo',
    'Dairy-Free',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
      ),
    );

    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFFFCF5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
    );
  }

  Widget _skillChip(String skill) {
    final isSelected = _selectedSkill == skill;

    return ChoiceChip(
      label: Text(skill),
      selected: isSelected,
      selectedColor: const Color(0xFFFFE0B2),
      checkmarkColor: const Color(0xFF2E7D32),
      onSelected: (_) {
        setState(() {
          _selectedSkill = skill;
        });
      },
    );
  }

  Widget _dietaryChip(String option) {
    final isSelected = _selectedDietaryRestrictions.contains(option);

    return FilterChip(
      label: Text(option),
      selected: isSelected,
      selectedColor: const Color(0xFFFFE0B2),
      checkmarkColor: const Color(0xFF2E7D32),
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _selectedDietaryRestrictions.remove(option);
          } else {
            _selectedDietaryRestrictions.add(option);
          }
        });
      },
    );
  }

  Widget _gradientButton() {
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
        ),
        child: ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = _calories.round();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text(
                  'Customize your cooking profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _settingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Basic Info'),
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email Address'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Age'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cooking Skill',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _skillChip('Beginner'),
                        _skillChip('Intermediate'),
                        _skillChip('Advanced'),
                      ],
                    ),
                  ],
                ),
              ),

              _settingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Dietary Preferences'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dietaryOptions
                          .map((option) => _dietaryChip(option))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _allergiesController,
                      decoration: _inputDecoration(
                        'Allergies, e.g. peanuts, shellfish',
                      ),
                    ),
                  ],
                ),
              ),

              _settingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Daily Calorie Goal'),
                    Center(
                      child: Text(
                        '$calories',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'calories per day',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.black,
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
                  ],
                ),
              ),

              _gradientButton(),
            ],
          ),
        ),
      ),
    );
  }
}