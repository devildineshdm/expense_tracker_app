import 'dart:io';
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/drive_service.dart';

// He app cha central state ahe - sagle screens ithun data ghetat
class AppState extends ChangeNotifier {
  final DBHelper _db = DBHelper();
  final DriveService driveService = DriveService();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool isLoading = true;
  bool isSyncing = false;
  DateTime? lastBackupTime;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;

  List<CategoryModel> categoriesFor(String type) =>
      type == 'income' ? _incomeCategories : _expenseCategories;

  // Transaction cha category name varun tyachi icon/color shodhnyasathi
  CategoryModel? findCategory(String type, String name) {
    final list = categoriesFor(type);
    for (final c in list) {
      if (c.name == name) return c;
    }
    return null;
  }

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  // App suru zalyavar data load karto (local DB + silent Drive sign-in)
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await loadLocalData();
    await loadCategories();

    // Aadhi kadhi login kela asel tar automatically sign-in karto
    final user = await driveService.trySilentSignIn();
    if (user != null) {
      await syncFromDrive();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadLocalData() async {
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _expenseCategories = await _db.getCategories('expense');
    _incomeCategories = await _db.getCategories('income');
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel txn) async {
    var finalTxn = txn;
    // Jar receipt photo asel ani Drive la login asel, tar photo upload karto
    if (txn.receiptLocalPath != null && driveService.isSignedIn) {
      try {
        final file = File(txn.receiptLocalPath!);
        final bytes = await file.readAsBytes();
        final driveId = await driveService.uploadReceiptImage(
            bytes, '${txn.id}_receipt.jpg');
        finalTxn = txn.copyWith(receiptDriveId: driveId);
      } catch (e) {
        debugPrint('Receipt upload error: $e');
      }
    }
    await _db.insertTransaction(finalTxn);
    await loadLocalData();
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    var finalTxn = txn;
    if (txn.receiptLocalPath != null &&
        txn.receiptDriveId == null &&
        driveService.isSignedIn) {
      try {
        final file = File(txn.receiptLocalPath!);
        final bytes = await file.readAsBytes();
        final driveId = await driveService.uploadReceiptImage(
            bytes, '${txn.id}_receipt.jpg');
        finalTxn = txn.copyWith(receiptDriveId: driveId);
      } catch (e) {
        debugPrint('Receipt upload error: $e');
      }
    }
    await _db.updateTransaction(finalTxn);
    await loadLocalData();
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final txn = _transactions.firstWhere((t) => t.id == id,
        orElse: () => TransactionModel(
            id: '',
            type: 'expense',
            amount: 0,
            category: '',
            note: '',
            date: DateTime.now(),
            paymentMode: 'Cash'));
    if (txn.receiptDriveId != null && driveService.isSignedIn) {
      driveService.deleteReceiptImage(txn.receiptDriveId!);
    }
    await _db.deleteTransaction(id);
    await loadLocalData();
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  // ---------- CATEGORY MANAGEMENT ----------

  Future<void> addCategory(CategoryModel cat) async {
    await _db.insertCategory(cat);
    await loadCategories();
    if (driveService.isSignedIn) backupToDrive();
  }

  Future<void> updateCategory(CategoryModel cat) async {
    await _db.updateCategory(cat);
    await loadCategories();
    if (driveService.isSignedIn) backupToDrive();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
    if (driveService.isSignedIn) backupToDrive();
  }

  // ---------- GOOGLE DRIVE SYNC ----------

  // Gmail ne login karnyasathi - login zalyavar Drive varcha data automatically yeto
  // Return: null = success, nahi tar error cha message (debug sathi upyogi)
  Future<String?> signInWithGoogle() async {
    try {
      final user = await driveService.signIn();
      if (user == null) return 'Sign-in cancel zala';
      await syncFromDrive();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await driveService.signOut();
    notifyListeners();
  }

  // Drive var data pathvnyasathi (backup) - transactions + categories dohnihi
  Future<void> backupToDrive() async {
    if (!driveService.isSignedIn) return;
    isSyncing = true;
    notifyListeners();
    try {
      final payload = {
        'transactions': await _db.exportAllAsJson(),
        'categories': await _db.exportCategoriesAsJson(),
      };
      await driveService.backupData(payload);
      lastBackupTime = DateTime.now();
    } catch (e) {
      debugPrint('Backup error: $e');
    }
    isSyncing = false;
    notifyListeners();
  }

  // Drive varun data parat aananyasathi (restore) - login nantar call hoto
  Future<void> syncFromDrive() async {
    isSyncing = true;
    notifyListeners();
    try {
      final driveData = await driveService.restoreData();
      if (driveData != null &&
          ((driveData['transactions'] as List?)?.isNotEmpty ?? false)) {
        final txns =
            (driveData['transactions'] as List).cast<Map<String, dynamic>>();
        await _db.replaceAllData(txns);

        final cats = (driveData['categories'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (cats.isNotEmpty) {
          await _db.replaceAllCategories(cats);
        }
        await loadLocalData();
        await loadCategories();
      } else {
        // Drive var kahi backup nasel tar, sध्याचा local data pahilyanda upload karto
        final localTxns = await _db.exportAllAsJson();
        if (localTxns.isNotEmpty) {
          await backupToDrive();
        }
      }
      lastBackupTime = await driveService.getLastBackupTime();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
    isSyncing = false;
    notifyListeners();
  }
}
