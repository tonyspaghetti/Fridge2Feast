import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database.dart';
import '../services/roboflow_freshness_service.dart';

class FreshnessCheckScreen extends StatefulWidget {
  final int? ingredientId;
  final String? ingredientName;
  final String? category;

  const FreshnessCheckScreen({
    super.key,
    this.ingredientId,
    this.ingredientName,
    this.category,
  });

  @override
  State<FreshnessCheckScreen> createState() => _FreshnessCheckScreenState();
}

class _FreshnessCheckScreenState extends State<FreshnessCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  File? _imageFile;
  DateTime? _purchaseDate;
  String _storageMethod = 'Refrigerated';
  String _smell = 'Normal';
  String _texture = 'Firm';
  String _appearance = 'Looks normal';
  bool _hasMold = false;
  bool _hasSlime = false;
  bool _isAnalyzing = false;
  FreshnessResult? _result;

  final List<String> _storageMethods = const [
    'Refrigerated',
    'Pantry / room temp',
    'Freezer',
  ];

  final List<String> _smellOptions = const [
    'Normal',
    'No smell',
    'Sour / unusual',
    'Bad / rotten',
  ];

  final List<String> _textureOptions = const [
    'Firm',
    'Soft',
    'Mushy',
    'Slimy',
  ];

  final List<String> _appearanceOptions = const [
    'Looks normal',
    'Bruised / wilted',
    'Discolored',
    'Moldy',
  ];

  @override
  void initState() {
    super.initState();
    _foodNameController.text = widget.ingredientName ?? '';

    final category = widget.category;
    if (category == 'Freezer') {
      _storageMethod = 'Freezer';
    } else if (category == 'Pantry' || category == 'Spices') {
      _storageMethod = 'Pantry / room temp';
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _result = null;
    });
  }

  Future<void> _selectPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _purchaseDate = picked;
      _result = null;
    });
  }

  Future<void> _analyzeFreshness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    final input = FreshnessInput(
      foodName: _foodNameController.text.trim(),
      purchaseDate: _purchaseDate,
      storageMethod: _storageMethod,
      smell: _smell,
      texture: _texture,
      appearance: _appearance,
      hasMold: _hasMold,
      hasSlime: _hasSlime,
      imageFile: _imageFile,
    );

    final result = await RoboflowFreshnessService.assessFreshness(input);

    if (!mounted) return;

    setState(() {
      _result = result;
      _isAnalyzing = false;
    });
  }

  Future<void> _updateIngredientExpiry() async {
    final ingredientId = widget.ingredientId;
    final result = _result;

    if (ingredientId == null || result == null || result.isUnsafe) return;

    final estimatedExpiryDate = DateTime.now().add(
      Duration(days: result.estimatedDaysLeft),
    );

    await _dbHelper.updateIngredientExpiry(
      ingredientId,
      estimatedExpiryDate.toIso8601String(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated estimated expiry to ${estimatedExpiryDate.month}/${estimatedExpiryDate.day}/${estimatedExpiryDate.year}',
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    Navigator.pop(context, true);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Fresh':
        return const Color(0xFF2E7D32);
      case 'Use Soon':
        return const Color(0xFFFF8F00);
      case 'Unsafe':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Fresh':
        return Icons.check_circle_rounded;
      case 'Use Soon':
        return Icons.warning_amber_rounded;
      case 'Unsafe':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (newValue) {
        onChanged(newValue);
        setState(() => _result = null);
      },
    );
  }

  Widget _buildImagePickerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a clear photo of the food surface. The app will combine the image result with your answers.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _imageFile!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Freshness Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Food name',
                hintText: 'e.g., banana, chicken, spinach',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the food name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectPurchaseDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _purchaseDate == null
                            ? 'When did you buy it? optional'
                            : 'Bought on ${_formatDate(_purchaseDate!)}',
                        style: TextStyle(
                          color: _purchaseDate == null ? Colors.grey.shade700 : Colors.black,
                        ),
                      ),
                    ),
                    if (_purchaseDate != null)
                      IconButton(
                        onPressed: () => setState(() => _purchaseDate = null),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _dropdownField(
              label: 'Storage method',
              value: _storageMethod,
              items: _storageMethods,
              onChanged: (value) => setState(() => _storageMethod = value ?? _storageMethod),
            ),
            const SizedBox(height: 16),
            _dropdownField(
              label: 'Smell',
              value: _smell,
              items: _smellOptions,
              onChanged: (value) => setState(() => _smell = value ?? _smell),
            ),
            const SizedBox(height: 16),
            _dropdownField(
              label: 'Texture',
              value: _texture,
              items: _textureOptions,
              onChanged: (value) => setState(() => _texture = value ?? _texture),
            ),
            const SizedBox(height: 16),
            _dropdownField(
              label: 'Appearance',
              value: _appearance,
              items: _appearanceOptions,
              onChanged: (value) => setState(() => _appearance = value ?? _appearance),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible mold?'),
              value: _hasMold,
              activeColor: Colors.red,
              onChanged: (value) => setState(() {
                _hasMold = value;
                _result = null;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Slimy surface?'),
              value: _hasSlime,
              activeColor: Colors.red,
              onChanged: (value) => setState(() {
                _hasSlime = value;
                _result = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final color = _statusColor(result.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
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
          Row(
            children: [
              Icon(_statusIcon(result.status), color: color, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.status,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      'Score ${result.score}/100 • ${result.confidence} confidence',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!result.isUnsafe)
            Text(
              'Estimated days left: ${result.estimatedDaysLeft}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'Recommendation: do not eat this item.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
            ),
          const SizedBox(height: 12),
          const Text(
            'Why:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...result.reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(reason, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Food safety note: this is only an estimate. When in doubt, throw it out.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (widget.ingredientId != null && !result.isUnsafe) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateIngredientExpiry,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Update Estimated Expiry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text('AI Freshness Check'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32).withOpacity(0.08),
                    const Color(0xFFFF8F00).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'This feature combines a Roboflow image model with a few condition questions to estimate whether food is fresh, should be used soon, or may be unsafe. Currently supports Apples, Bananas, Tomatoes, and Oranges. More coming soon!',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            _buildImagePickerCard(),
            const SizedBox(height: 20),
            _buildQuestionsCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeFreshness,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Assess Freshness'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildResultCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
