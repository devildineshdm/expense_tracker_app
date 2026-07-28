import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            paymentMode TEXT
          )
        ''');
      },
    );
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
