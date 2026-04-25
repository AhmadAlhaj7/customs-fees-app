import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/database_model.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'customs_fees.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Table for databases (each imported Excel file)
    await db.execute('''
      CREATE TABLE databases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        fileName TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        itemCount INTEGER DEFAULT 0
      )
    ''');

    // Table for products (linked to a database by databaseId)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        databaseId INTEGER NOT NULL,
        itemNumber TEXT NOT NULL,
        itemName TEXT NOT NULL,
        description TEXT NOT NULL,
        importFee REAL NOT NULL,
        serviceFee REAL NOT NULL,
        totalFee REAL NOT NULL,
        commercialName TEXT NOT NULL,
        imagePath TEXT,
        FOREIGN KEY (databaseId) REFERENCES databases (id)
      )
    ''');
  }

  // ─── DATABASE OPERATIONS ───────────────────────────────

  static Future<int> insertDatabase(DatabaseModel dbModel) async {
    final db = await getDatabase();
    return await db.insert('databases', dbModel.toMap());
  }

  static Future<List<DatabaseModel>> getAllDatabases() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'databases',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => DatabaseModel.fromMap(map)).toList();
  }

  static Future<void> updateDatabaseItemCount(int databaseId) async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE databaseId = ?',
      [databaseId],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    await db.update(
      'databases',
      {'itemCount': count},
      where: 'id = ?',
      whereArgs: [databaseId],
    );
  }

  static Future<void> deleteDatabase(int databaseId) async {
    final db = await getDatabase();
    await db.delete('products', where: 'databaseId = ?', whereArgs: [databaseId]);
    await db.delete('databases', where: 'id = ?', whereArgs: [databaseId]);
  }

  // ─── PRODUCT OPERATIONS ────────────────────────────────

  static Future<void> insertProducts(List<Product> products) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (final product in products) {
      batch.insert('products', product.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<int> insertProduct(Product product) async {
    final db = await getDatabase();
    final id = await db.insert('products', product.toMap());
    await updateDatabaseItemCount(product.databaseId);
    return id;
  }

  static Future<List<Product>> getProductsByDatabase(int databaseId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'databaseId = ?',
      whereArgs: [databaseId],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<List<Product>> searchProducts(
      int databaseId, String query) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'databaseId = ? AND (itemNumber LIKE ? OR commercialName LIKE ?)',
      whereArgs: [databaseId, '%$query%', '%$query%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<int> updateProduct(Product product) async {
    final db = await getDatabase();
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<void> deleteProduct(int id, int databaseId) async {
    final db = await getDatabase();
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await updateDatabaseItemCount(databaseId);
  }
}