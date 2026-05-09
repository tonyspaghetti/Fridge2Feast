import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fridge2feast.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userID TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT,
        category TEXT NOT NULL,
        expiryDate TEXT,
        addedAt TEXT NOT NULL
      )
    ''');
  }

  // Get all ingredients for a user
  Future<List<Map<String, dynamic>>> getUserIngredients(String userID) async {
    final db = await database;
    return await db.query(
      'ingredients',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'name ASC',
    );
  }

  // Add or update ingredient (if exists, add to quantity)
  Future<void> addOrUpdateIngredient({
    required String userID,
    required String name,
    required double quantity,
    required String unit,
    required String category,
    String? expiryDate,
  }) async {
    final db = await database;
    
    // Check if ingredient already exists
    final existing = await db.query(
      'ingredients',
      where: 'userID = ? AND name = ? AND category = ?',
      whereArgs: [userID, name, category],
    );
    
    if (existing.isNotEmpty) {
      // Update: add to existing quantity
      final existingQuantity = existing.first['quantity'] as double;
      final newQuantity = existingQuantity + quantity;
      await db.update(
        'ingredients',
        {
          'quantity': newQuantity,
          'unit': unit.isNotEmpty ? unit : existing.first['unit'],
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Insert new ingredient
      await db.insert('ingredients', {
        'userID': userID,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'expiryDate': expiryDate,
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Decrement ingredient quantity by 1 (or remove if becomes 0)
  Future<bool> decrementIngredient(int id, double currentQuantity) async {
    final db = await database;
    
    if (currentQuantity > 1) {
      // Decrease by 1
      await db.update(
        'ingredients',
        {'quantity': currentQuantity - 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return false; // Not removed, just decreased
    } else {
      // Remove completely
      await db.delete(
        'ingredients',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true; // Was removed
    }
  }

  // Remove ingredient completely
  Future<void> deleteIngredient(int id) async {
    final db = await database;
    await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all ingredients for a user
  Future<void> clearUserIngredients(String userID) async {
    final db = await database;
    await db.delete(
      'ingredients',
      where: 'userID = ?',
      whereArgs: [userID],
    );
  }

  // Get ingredient count for a user
  Future<int> getIngredientCount(String userID) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ingredients WHERE userID = ?',
      [userID],
    );
    return result.first['count'] as int;
  }
}