import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('infoma.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users Table (Profile)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        profile_picture TEXT,
        role TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Residences Table
    await db.execute('''
      CREATE TABLE residences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        rental_period TEXT NOT NULL,
        price REAL NOT NULL,
        capacity INTEGER NOT NULL,
        available_slots INTEGER NOT NULL,
        facilities TEXT NOT NULL,
        images TEXT NOT NULL,
        discount_type TEXT,
        discount_value REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Activities Table
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        event_date TEXT NOT NULL,
        registration_deadline TEXT NOT NULL,
        price REAL NOT NULL,
        capacity INTEGER NOT NULL,
        available_slots INTEGER NOT NULL,
        images TEXT NOT NULL,
        discount_type TEXT,
        discount_value REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE marketplace (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seller_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        condition TEXT NOT NULL,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        images TEXT NOT NULL,
        tags TEXT,
        status TEXT NOT NULL,
        views_count INTEGER NOT NULL DEFAULT 0,
        sold_at TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Bookmarks Table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        bookmarkable_type TEXT NOT NULL,
        bookmarkable_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, bookmarkable_type, bookmarkable_id)
      )
    ''');

    print('✅ Database tables created successfully');
  }

  // Generic CRUD Operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update with explicit ID parameter
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Query with where clause
  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('residences');
    await db.delete('activities');
    await db.delete('products');
    print('🗑️ All data cleared');
  }

  // Get database info
  Future<Map<String, int>> getDatabaseInfo() async {
    final db = await database;
    final residencesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM residences'),
    );
    final activitiesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM activities'),
    );
    final productsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );

    return {
      'residences': residencesCount ?? 0,
      'activities': activitiesCount ?? 0,
      'products': productsCount ?? 0,
    };
  }
}
