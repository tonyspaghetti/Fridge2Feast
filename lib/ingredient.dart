class Ingredient {
  final int? id;
  final String userID;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final DateTime? expiryDate;
  final DateTime addedAt;

  Ingredient({
    this.id,
    required this.userID,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.expiryDate,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userID': userID,
      'name': name.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'category': category,
      'expiryDate': expiryDate?.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 1.0;
      return 1.0;
    }

    DateTime? asDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return Ingredient(
      id: map['id'] is int ? map['id'] as int : (map['id'] == null ? null : int.tryParse(map['id'].toString())),
      userID: map['userID']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      quantity: asDouble(map['quantity']),
      unit: map['unit']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Fridge',
      expiryDate: asDate(map['expiryDate']),
      addedAt: asDate(map['addedAt']) ?? DateTime.now(),
    );
  }
}
