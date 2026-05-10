import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'screens/freshness_check_screen.dart';

class AddIngredientsScreen extends StatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  State<AddIngredientsScreen> createState() => _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends State<AddIngredientsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedCategory = 'Fridge';
  DateTime? _selectedExpiryDate;
  String? _currentUserID;
  List<Map<String, dynamic>> _addedIngredients = [];

  final List<String> _quickAddIngredients = const [
    'Chicken Breast',
    'Eggs',
    'Milk',
    'Cheese',
    'Yogurt',
    'Tomatoes',
    'Onions',
    'Garlic',
    'Potatoes',
    'Carrots',
    'Pasta',
    'Rice',
    'Bread',
    'Flour',
    'Sugar',
    'Olive Oil',
    'Butter',
    'Salt',
    'Pepper',
    'Basil',
    'Lemon',
    'Cucumber',
    'Bell Peppers',
    'Spinach',
    'Broccoli',
    'Banana',
    'Apples',
    'Berries',
    'Avocado',
    'Lettuce',
  ];

  final Map<String, IconData> _categoryIcons = const {
    'Fridge': Icons.kitchen_rounded,
    'Pantry': Icons.cabin_rounded,
    'Freezer': Icons.ac_unit_rounded,
    'Spices': Icons.spa_rounded,
  };

  final Map<String, List<String>> _categoryExamples = const {
    'Fridge': ['Milk', 'Eggs', 'Cheese', 'Yogurt', 'Butter'],
    'Pantry': ['Rice', 'Pasta', 'Flour', 'Sugar', 'Olive Oil'],
    'Freezer': ['Frozen Vegetables', 'Ice Cream', 'Frozen Meat'],
    'Spices': ['Salt', 'Pepper', 'Basil', 'Oregano'],
  };

  final Map<String, Color> _categoryColors = const {
    'Fridge': Color(0xFF2196F3),
    'Pantry': Color(0xFFFF9800),
    'Freezer': Color(0xFF9C27B0),
    'Spices': Color(0xFF4CAF50),
  };

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _ingredientNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (!mounted) return;

    if (userID == null || userID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete setup again.')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentUserID = userID;
    });

    await _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final userID = _currentUserID;
    if (userID == null) return;

    final ingredients = await _dbHelper.getUserIngredients(userID);
    if (!mounted) return;

    setState(() {
      _addedIngredients = ingredients.map((ingredient) {
        return {
          'id': ingredient['id'],
          'name': ingredient['name'],
          'quantity': ingredient['quantity'],
          'unit': ingredient['unit'] ?? '',
          'category': ingredient['category'],
          'expiryDate': ingredient['expiryDate'],
          'addedAt': ingredient['addedAt'],
        };
      }).toList();
    });
  }

  double _parseQuantity(dynamic quantity) {
    if (quantity is num) return quantity.toDouble();
    if (quantity is String) return double.tryParse(quantity) ?? 1.0;
    return 1.0;
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) return quantity.round().toString();
    return quantity.toStringAsFixed(1);
  }


  String? _formatExpiryDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final date = DateTime.tryParse(value.toString());
    if (date == null) return null;
    return '${date.month}/${date.day}/${date.year}';
  }

  String _detectCategory(String ingredient) {
    final item = ingredient.toLowerCase();
    final pantryItems = ['rice', 'pasta', 'flour', 'sugar', 'salt', 'pepper', 'olive oil', 'bread'];
    final freezerItems = ['frozen', 'ice cream'];
    final spicesItems = ['basil', 'oregano', 'thyme', 'rosemary'];

    if (pantryItems.any((keyword) => item.contains(keyword))) return 'Pantry';
    if (freezerItems.any((keyword) => item.contains(keyword))) return 'Freezer';
    if (spicesItems.any((keyword) => item.contains(keyword))) return 'Spices';
    return 'Fridge';
  }

  int _findIngredientIndex(String name, String category) {
    return _addedIngredients.indexWhere((ingredient) {
      return ingredient['name'].toString().toLowerCase() == name.toLowerCase() &&
          ingredient['category'] == category;
    });
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedIngredients() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final category in _categoryIcons.keys) {
      grouped[category] = _addedIngredients.where((ingredient) {
        return ingredient['category'] == category;
      }).toList();
    }
    grouped.removeWhere((_, ingredients) => ingredients.isEmpty);
    return grouped;
  }

  Future<void> _addIngredientManually() async {
    if (!_formKey.currentState!.validate()) return;

    final userID = _currentUserID;
    if (userID == null) return;

    final name = _ingredientNameController.text.trim();
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 1.0;
    final unit = _unitController.text.trim();

    await _dbHelper.addOrUpdateIngredient(
      userID: userID,
      name: name,
      quantity: quantity,
      unit: unit,
      category: _selectedCategory,
      expiryDate: _selectedExpiryDate?.toIso8601String(),
    );

    await _loadIngredients();

    if (!mounted) return;
    setState(() {
      _selectedExpiryDate = null;
    });
    _ingredientNameController.clear();
    _quantityController.clear();
    _unitController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_formatQuantity(quantity <= 0 ? 1 : quantity)} ${unit.isEmpty ? '' : '$unit '}$name'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _addQuickIngredient(String ingredientName) async {
    final userID = _currentUserID;
    if (userID == null) return;

    await _dbHelper.addOrUpdateIngredient(
      userID: userID,
      name: ingredientName,
      quantity: 1,
      unit: '',
      category: _detectCategory(ingredientName),
    );

    await _loadIngredients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+1 $ingredientName'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _decrementIngredient(int id, double currentQuantity) async {
    final wasRemoved = await _dbHelper.decrementIngredient(id, currentQuantity);
    await _loadIngredients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasRemoved ? 'Removed from your kitchen' : 'Decreased quantity'),
        backgroundColor: wasRemoved ? Colors.red : null,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteIngredient(int id) async {
    await _dbHelper.deleteIngredient(id);
    await _loadIngredients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from your kitchen'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearAllIngredients() async {
    final userID = _currentUserID;
    if (userID == null) return;

    await _dbHelper.clearUserIngredients(userID);
    await _loadIngredients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All ingredients cleared'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _clearCategory(String category) async {
    final userID = _currentUserID;
    if (userID == null) return;

    await _dbHelper.clearCategory(userID, category);
    await _loadIngredients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared all items from $category'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _selectedExpiryDate = picked;
    });
  }

  Future<void> _openFreshnessCheck([Map<String, dynamic>? ingredient]) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FreshnessCheckScreen(
          ingredientId: ingredient?['id'] is int ? ingredient!['id'] as int : null,
          ingredientName: ingredient?['name']?.toString(),
          category: ingredient?['category']?.toString(),
        ),
      ),
    );

    if (updated == true) {
      await _loadIngredients();
    }
  }

  void _showAIFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Coming Soon'),
        content: Text('$feature is under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
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

  Widget _categoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      avatar: Icon(_categoryIcons[category], size: 18),
      selectedColor: const Color(0xFFE8F5E9),
      checkmarkColor: const Color(0xFF2E7D32),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: primary ? Colors.white : const Color(0xFF2E7D32), size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? const Color(0xFF2E7D32) : Colors.white,
          foregroundColor: primary ? Colors.white : const Color(0xFF2E7D32),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: primary ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> ingredients) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    final color = _categoryColors[category] ?? const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(_categoryIcons[category], color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                const Spacer(),
                Text(
                  '${ingredients.length} item${ingredients.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                  onPressed: () => _clearCategory(category),
                  tooltip: 'Clear $category',
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ingredients.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              final quantity = _parseQuantity(ingredient['quantity']);
              final id = ingredient['id'] as int;
              final unit = ingredient['unit']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 30,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ingredient['name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          Text(
                            '${_formatQuantity(quantity)}${unit.isEmpty ? '' : ' $unit'}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          if (_formatExpiryDate(ingredient['expiryDate']) != null)
                            Text(
                              "Est. expiry: ${_formatExpiryDate(ingredient['expiryDate'])}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () => _decrementIngredient(id, quantity),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _formatQuantity(quantity),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => _addQuickIngredient(ingredient['name'].toString()),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.health_and_safety_outlined, size: 20, color: Color(0xFF2E7D32)),
                      tooltip: 'Check freshness',
                      onPressed: () => _openFreshnessCheck(ingredient),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                      onPressed: () => _deleteIngredient(id),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedIngredients = _getGroupedIngredients();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text('Add Ingredients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _addedIngredients),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _progressBar(true),
                const SizedBox(width: 6),
                _progressBar(false),
                const SizedBox(width: 12),
                const Text(
                  'Build your virtual kitchen',
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: Color(0xFF2E7D32), size: 22),
                        SizedBox(width: 8),
                        Text('Add Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _ingredientNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Ingredient Name *',
                        hintText: 'e.g., Tomatoes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter an ingredient name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              hintText: 'Defaults to 1',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final quantity = double.tryParse(value.trim());
                              if (quantity == null || quantity <= 0) return 'Use a positive number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'lbs, cups',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _categoryIcons.keys.map(_categoryChip).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Examples: ${_categoryExamples[_selectedCategory]!.join(', ')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectExpiryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedExpiryDate == null
                                    ? 'Select expiry date optional'
                                    : '${_selectedExpiryDate!.month}/${_selectedExpiryDate!.day}/${_selectedExpiryDate!.year}',
                                style: TextStyle(
                                  color: _selectedExpiryDate == null ? Colors.grey.shade600 : Colors.black,
                                ),
                              ),
                            ),
                            if (_selectedExpiryDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _selectedExpiryDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _actionButton(
                      text: 'Add Ingredient',
                      icon: Icons.add_rounded,
                      onPressed: _addIngredientManually,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: Color(0xFFFF8F00), size: 22),
                      SizedBox(width: 8),
                      Text('Quick Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap a common ingredient to add it. Tapping again increases quantity.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAddIngredients.map((ingredient) {
                      final category = _detectCategory(ingredient);
                      final existingIndex = _findIngredientIndex(ingredient, category);
                      final currentQty = existingIndex == -1
                          ? null
                          : _formatQuantity(_parseQuantity(_addedIngredients[existingIndex]['quantity']));

                      return ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ingredient),
                            if (currentQty != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(currentQty, style: const TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        onPressed: () => _addQuickIngredient(ingredient),
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32).withOpacity(0.05),
                    const Color(0xFFFF8F00).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 22),
                      SizedBox(width: 8),
                      Text('AI-Powered Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          text: 'Scan Photo',
                          icon: Icons.camera_alt_rounded,
                          primary: false,
                          onPressed: () => _openFreshnessCheck(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_addedIngredients.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Your Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAllIngredients,
                    child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._categoryIcons.keys.map((category) {
                return _buildCategorySection(category, groupedIngredients[category] ?? []);
              }),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
