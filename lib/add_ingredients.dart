// add_ingredients.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';  // DATABASE

class AddIngredientsScreen extends StatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  State<AddIngredientsScreen> createState() => _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends State<AddIngredientsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _ingredientNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  
  String _selectedCategory = 'Fridge';
  DateTime? _selectedExpiryDate;
  
  // Quick add ingredients list
  final List<String> _quickAddIngredients = [
    'Chicken Breast', 'Eggs', 'Milk', 'Cheese', 'Yogurt',
    'Tomatoes', 'Onions', 'Garlic', 'Potatoes', 'Carrots',
    'Pasta', 'Rice', 'Bread', 'Flour', 'Sugar',
    'Olive Oil', 'Butter', 'Salt', 'Pepper',
    'Basil', 'Lemon', 'Cucumber', 'Bell Peppers', 'Spinach',
    'Broccoli', 'Banana', 'Apples', 'Berries', 'Avocado', 'Lettuce'
  ];
  
  List<Map<String, dynamic>> _addedIngredients = [];
  String? _currentUserID;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();  
  
  final Map<String, IconData> _categoryIcons = {
    'Fridge': Icons.kitchen_rounded,
    'Pantry': Icons.cabin_rounded,
    'Freezer': Icons.ac_unit_rounded,
    'Spices': Icons.spa_rounded,
  };
  
  final Map<String, List<String>> _categoryExamples = {
    'Fridge': ['Milk', 'Eggs', 'Cheese', 'Yogurt', 'Butter'],
    'Pantry': ['Rice', 'Pasta', 'Flour', 'Sugar', 'Olive Oil'],
    'Freezer': ['Frozen Vegetables', 'Ice Cream', 'Frozen Meat'],
    'Spices': ['Salt', 'Pepper', 'Basil', 'Oregano'],
  };

  final Map<String, Color> _catagoryColors = {
    'Fridge': const Color(0xFF2196F3), // Blue
    'Pantry': const Color(0xFFFF9800), // Orange
    'Freezer': const Color(0xFF9C27B0), // Purple
    'Spices': const Color(0xFF4CAF50), // Green
  };

  @override
  void initState() {
    super.initState();
    // Wait for first frame to be rendered so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDatabase();
    });
  }

  @override
  void dispose() {
    _ingredientNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // ============ DATABASE METHODS ============

  Future<void> _initDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    
    if (userID == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again')),
        );
      }
      return;
    }
    
    setState(() {
      _currentUserID = userID;
    });
    
    await _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    if (_currentUserID == null) return;
    
    final ingredients = await _dbHelper.getUserIngredients(_currentUserID!);
    
    setState(() {
      _addedIngredients = ingredients.map((ing) {
        return {
          'id': ing['id'],
          'name': ing['name'],
          'quantity': ing['quantity'].toString(),
          'unit': ing['unit'] ?? '',
          'category': ing['category'],
          'expiryDate': ing['expiryDate'],
          'addedAt': ing['addedAt'],
        };
      }).toList();
    });
  }

  // ============ HELPER METHODS ============

  double _parseQuantity(dynamic quantity) {
    if (quantity == null) return 1.0;
    if (quantity is double) return quantity;
    if (quantity is int) return quantity.toDouble();
    if (quantity is String) {
      if (quantity.isEmpty) return 1.0;
      try {
        return double.parse(quantity);
      } catch (e) {
        return 1.0;
      }
    }
    return 1.0;
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(1);
  }

  int _findIngredientIndex(String name, String category) {
    return _addedIngredients.indexWhere(
      (ingredient) => 
          ingredient['name'].toLowerCase() == name.toLowerCase() && 
          ingredient['category'] == category
    );
  }

  String _detectCategory(String ingredient) {
    final pantryItems = ['Rice', 'Pasta', 'Flour', 'Sugar', 'Salt', 'Pepper', 'Olive Oil'];
    final freezerItems = ['Frozen', 'Ice Cream'];
    final spicesItems = ['Basil', 'Oregano', 'Thyme', 'Rosemary'];
    
    if (pantryItems.any((item) => ingredient.contains(item))) return 'Pantry';
    if (freezerItems.any((item) => ingredient.contains(item))) return 'Freezer';
    if (spicesItems.any((item) => ingredient.contains(item))) return 'Spices';
    return 'Fridge';
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedIngredients(){
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var category in _categoryIcons.keys){
      grouped[category] = _addedIngredients.where((ing) => ing['category'] == category).toList();
    }
    grouped.removeWhere((key,value) => value.isEmpty);
    return grouped;
  }

  // ============ UI ACTIONS ============

  void _addIngredientManually() async {
    if (_formKey.currentState!.validate()) {
      final String name = _ingredientNameController.text.trim();
      String quantityText = _quantityController.text.trim();
      final String unit = _unitController.text.trim();
      final String category = _selectedCategory;
      
      if (quantityText.isEmpty) {
        quantityText = '1';
      }
      
      final double quantity = double.tryParse(quantityText) ?? 1.0;
      
      await _dbHelper.addOrUpdateIngredient(
        userID: _currentUserID!,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        expiryDate: _selectedExpiryDate?.toIso8601String(),
      );
      
      await _loadIngredients();
      
      // Clear form
      _ingredientNameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _selectedExpiryDate = null;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_formatQuantity(quantity)} $unit $name'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    }
  }

  void _addQuickIngredient(String ingredientName) async {
    final category = _detectCategory(ingredientName);
    
    await _dbHelper.addOrUpdateIngredient(
      userID: _currentUserID!,
      name: ingredientName,
      quantity: 1.0,
      unit: '',
      category: category,
      expiryDate: null,
    );
    
    await _loadIngredients();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+1 $ingredientName'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _decrementIngredient(int id, double currentQuantity) async {
    final wasRemoved = await _dbHelper.decrementIngredient(id, currentQuantity);
    await _loadIngredients();
    
    if (mounted) {
      if (wasRemoved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from your kitchen'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decreased quantity'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteIngredient(int id) async {
    await _dbHelper.deleteIngredient(id);
    await _loadIngredients();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from your kitchen'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _clearAllIngredients() async {
    await _dbHelper.clearUserIngredients(_currentUserID!);
    await _loadIngredients();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All ingredients cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearCategory(String category) async {
    final categoryIngredients = _addedIngredients
        .where((ing) => ing['category'] == category)
        .toList();

    for (var ing in categoryIngredients) {
      await _dbHelper.deleteIngredient(ing['id']);
    }
    await _loadIngredients();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared all items from $category'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _showAIFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Coming Soon'),
        content: Text('$feature feature is under development!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  // ============ UI WIDGETS ============

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
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  Widget _gradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? null : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF2E7D32),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> ingredients) {
  if (ingredients.isEmpty) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _catagoryColors[category]?.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(_categoryIcons[category], color: _catagoryColors[category], size: 24),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _catagoryColors[category],
                ),
              ),
              const Spacer(),
              Text(
                '${ingredients.length} item${ingredients.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                onPressed: () => _clearCategory(category),
                tooltip: 'Clear all $category items',
              ),
            ],
          ),
        ),
        // Ingredients in this category
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredients.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.shade100,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];
            final quantity = _parseQuantity(ingredient['quantity']);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Category color bar
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _catagoryColors[category],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ingredient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        if (ingredient['unit'].toString().isNotEmpty)
                          Text(
                            '${_formatQuantity(quantity)} ${ingredient['unit']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () => _decrementIngredient(ingredient['id'], quantity),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _formatQuantity(quantity),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => _addQuickIngredient(ingredient['name']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                    onPressed: () => _deleteIngredient(ingredient['id']),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text('Add Ingredients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _addedIngredients),
            child: const Text(
              'Done Adding',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                const Spacer(),
                if (_currentUserID != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, size: 12, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text('Your Kitchen', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Manual Addition Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ingredient Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _ingredientNameController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Tomatoes',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter ingredient name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'e.g., 2 (defaults to 1)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Unit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _unitController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g., lbs, cups',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: _categoryIcons.keys.map((category) => _categoryChip(category)).toList(),
                            ),
                            if (_categoryExamples[_selectedCategory] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Examples: ${_categoryExamples[_selectedCategory]!.join(', ')}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expiry Date (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 8),
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
                                    Text(
                                      _selectedExpiryDate == null
                                          ? 'Select date'
                                          : '${_selectedExpiryDate!.month}/${_selectedExpiryDate!.day}/${_selectedExpiryDate!.year}',
                                      style: TextStyle(
                                        color: _selectedExpiryDate == null ? Colors.grey.shade600 : Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_selectedExpiryDate != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(() => _selectedExpiryDate = null),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "We'll remind you when ingredients are expiring soon",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _addIngredientManually,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Add Ingredient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Add Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
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
                  const Text('Tap to quickly add common ingredients (tapping again increases quantity)', 
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAddIngredients.map((ingredient) {
                      final existingIndex = _findIngredientIndex(ingredient, _detectCategory(ingredient));
                      final currentQty = existingIndex != -1 ? _addedIngredients[existingIndex]['quantity'] : null;
                      
                      return ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ingredient),
                            if (currentQty != null && currentQty.toString() != '0') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  currentQty.toString(),
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onPressed: () => _addQuickIngredient(ingredient),
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // AI-Powered Features Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32).withValues(alpha: 0.05),
                    const Color(0xFFFF8F00).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
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
                        child: _gradientButton(
                          text: 'Scan Photo',
                          icon: Icons.camera_alt_rounded,
                          onPressed: () => _showAIFeatureComingSoon('Scan Photo'),
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _gradientButton(
                          text: 'Voice Input',
                          icon: Icons.mic_rounded,
                          onPressed: () => _showAIFeatureComingSoon('Voice Input'),
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(children: const [Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('📸 Ingredient recognition from photos', style: TextStyle(fontSize: 13))]),
                        const SizedBox(height: 8),
                        Row(children: const [Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('🤖 Automatic expiry date prediction', style: TextStyle(fontSize: 13))]),
                        const SizedBox(height: 8),
                        Row(children: const [Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('🎤 Natural language voice parsing', style: TextStyle(fontSize: 13))]),
                        const SizedBox(height: 8),
                        Row(children: const [Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('⚡ Smart quantity detection', style: TextStyle(fontSize: 13))]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Display ingredients list with +1/-1 buttons
            // Display ingredients grouped by category
            if (_addedIngredients.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Your Ingredients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAllIngredients,
                    child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Build each category section
              ..._categoryIcons.keys.map((category) {
                final categoryIngredients = _getGroupedIngredients()[category] ?? [];
                return _buildCategorySection(category, categoryIngredients);
              }).toList(),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}