import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DBHelper {
  static Database? _database;

  // Get the database (create it if it doesn't exist)
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'customs_fees.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  // Create the products table
  static Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemNumber TEXT NOT NULL,
        itemName TEXT NOT NULL,
        description TEXT NOT NULL,
        importFee REAL NOT NULL,
        serviceFee REAL NOT NULL,
        totalFee REAL NOT NULL,
        commercialName TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  // INSERT a new product
  static Future<int> insertProduct(Product product) async {
    final db = await getDatabase();
    return await db.insert('products', product.toMap());
  }

  // GET all products
  static Future<List<Product>> getAllProducts() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // SEARCH product by item number
  static Future<List<Product>> searchByItemNumber(String itemNumber) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'itemNumber LIKE ?',
      whereArgs: ['%$itemNumber%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // UPDATE an existing product
  static Future<int> updateProduct(Product product) async {
    final db = await getDatabase();
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // DELETE a product
  static Future<int> deleteProduct(int id) async {
    final db = await getDatabase();
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}