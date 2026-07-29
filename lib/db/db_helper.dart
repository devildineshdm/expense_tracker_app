import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/icon_options.dart';

// Ha class local phone storage (SQLite) sathi ahe
// App band jhala tari data ithe safe rahto
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_tracker.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            paymentMode TEXT,
            receiptLocalPath TEXT,
            receiptDriveId TEXT
          )
        ''');
        await _createCategoriesTable(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
          await _seedDefaultCategories(db);
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN receiptLocalPath TEXT');
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN receiptDriveId TEXT');
        }
      },
    );
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaults = DefaultCategories.seed();
    for (final c in defaults) {
      await db.insert('categories', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ---------- CATEGORY METHODS ----------

  Future<List<CategoryModel>> getCategories(String type) async {
    final db = await database;
    final maps =
        await db.query('categories', where: 'type = ?', whereArgs: [type]);
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<void> insertCategory(CategoryModel cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(CategoryModel cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Google Drive backup madhye categories pan samaviष्ट karnyasathi
  Future<List<Map<String, dynamic>>> exportCategoriesAsJson() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<void> replaceAllCategories(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      for (final row in rows) {
        await txn.insert('categories', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Navin entry add karnyasathi
  Future<void> insertTransaction(TransactionModel txn) async {
    final db = await database;
    await db.insert(
      'transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Sagli entries get karnyasathi (latest first)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // Entry update karnyasathi
  Future<void> updateTransaction(TransactionModel txn) async {
    final db = await database;
    await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  // Entry delete karnyasathi
  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Google Drive backup sathi - sagla data JSON list mhanun kadhto
  Future<List<Map<String, dynamic>>> exportAllAsJson() async {
    final db = await database;
    return await db.query('transactions');
  }

  // Google Drive restore sathi - sagla purva data delete karun navin taknyasathi
  Future<void> replaceAllData(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      for (final row in rows) {
        await txn.insert('transactions', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
