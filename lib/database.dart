import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    final path = join(await getDatabasesPath(), 'fridge2feast.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE INDEX idx_ingredients_user_name_category
      ON ingredients(userID, name, category)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_ingredients_user_name_category
        ON ingredients(userID, name, category)
      ''');
    }
  }

  Future<List<Map<String, dynamic>>> getUserIngredients(String userID) async {
    final db = await database;
    return db.query(
      'ingredients',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'category ASC, name COLLATE NOCASE ASC',
    );
  }

  Future<void> addOrUpdateIngredient({
    required String userID,
    required String name,
    required double quantity,
    required String unit,
    required String category,
    String? expiryDate,
  }) async {
    final cleanName = name.trim();
    final cleanUnit = unit.trim();
    final cleanCategory = category.trim().isEmpty ? 'Fridge' : category.trim();
    final safeQuantity = quantity <= 0 ? 1.0 : quantity;

    if (userID.trim().isEmpty || cleanName.isEmpty) return;

    final db = await database;

    final existing = await db.query(
      'ingredients',
      where: 'userID = ? AND lower(name) = lower(?) AND category = ?',
      whereArgs: [userID, cleanName, cleanCategory],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final current = existing.first['quantity'];
      final existingQuantity = current is num
          ? current.toDouble()
          : double.tryParse('$current') ?? 0.0;

      await db.update(
        'ingredients',
        {
          'quantity': existingQuantity + safeQuantity,
          'unit': cleanUnit.isNotEmpty ? cleanUnit : existing.first['unit'],
          'expiryDate': expiryDate ?? existing.first['expiryDate'],
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('ingredients', {
        'userID': userID,
        'name': cleanName,
        'quantity': safeQuantity,
        'unit': cleanUnit,
        'category': cleanCategory,
        'expiryDate': expiryDate,
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> decrementIngredient(int id, double currentQuantity) async {
    final db = await database;

    if (currentQuantity > 1) {
      await db.update(
        'ingredients',
        {'quantity': currentQuantity - 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return false;
    }

    await deleteIngredient(id);
    return true;
  }

  Future<void> deleteIngredient(int id) async {
    final db = await database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }


  Future<void> updateIngredientExpiry(int id, String? expiryDate) async {
    final db = await database;
    await db.update(
      'ingredients',
      {'expiryDate': expiryDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearUserIngredients(String userID) async {
    final db = await database;
    await db.delete('ingredients', where: 'userID = ?', whereArgs: [userID]);
  }

  Future<void> clearCategory(String userID, String category) async {
    final db = await database;
    await db.delete(
      'ingredients',
      where: 'userID = ? AND category = ?',
      whereArgs: [userID, category],
    );
  }

  Future<int> getIngredientCount(String userID) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ingredients WHERE userID = ?',
      [userID],
    );
    final count = result.first['count'];
    return count is int ? count : int.tryParse('$count') ?? 0;
  }
}
