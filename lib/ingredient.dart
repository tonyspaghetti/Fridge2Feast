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
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiryDate': expiryDate?.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      userID: map['userID'],
      name: map['name'],
      quantity: map['quantity'] is int 
          ? (map['quantity'] as int).toDouble() 
          : map['quantity'],
      unit: map['unit'] ?? '',
      category: map['category'],
      expiryDate: map['expiryDate'] != null 
          ? DateTime.parse(map['expiryDate']) 
          : null,
      addedAt: DateTime.parse(map['addedAt']),
    );
  }
}