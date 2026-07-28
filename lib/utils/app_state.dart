import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../services/drive_service.dart';

// He app cha central state ahe - sagle screens ithun data ghetat
class AppState extends ChangeNotifier {
  final DBHelper _db = DBHelper();
  final DriveService driveService = DriveService();

  List<TransactionModel> _transactions = [];
  bool isLoading = true;
  bool isSyncing = false;
  DateTime? lastBackupTime;

  List<TransactionModel> get transactions => _transactions;

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

  Future<void> addTransaction(TransactionModel txn) async {
    await _db.insertTransaction(txn);
    await loadLocalData();
    // Navin entry add zali ki automatically Drive var backup karto (jar login asel tar)
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    await _db.updateTransaction(txn);
    await loadLocalData();
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadLocalData();
    if (driveService.isSignedIn) {
      backupToDrive();
    }
  }

  // Gmail ne login karnyasathi - login zalyavar Drive varcha data automatically yeto
  Future<bool> signInWithGoogle() async {
    try {
      final user = await driveService.signIn();
      if (user == null) return false;
      await syncFromDrive();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await driveService.signOut();
    notifyListeners();
  }

  // Drive var data pathvnyasathi (backup)
  Future<void> backupToDrive() async {
    if (!driveService.isSignedIn) return;
    isSyncing = true;
    notifyListeners();
    try {
      final allData = await _db.exportAllAsJson();
      await driveService.backupData(allData);
      lastBackupTime = DateTime.now();
    } catch (e) {
      // Backup fail zala tar silently ignore karto, user la app vaparayla adchan nahi
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
      if (driveData != null && driveData.isNotEmpty) {
        await _db.replaceAllData(driveData);
        await loadLocalData();
      } else {
        // Drive var kahi backup nasel tar, sध्याचा local data pahilyanda upload karto
        final localData = await _db.exportAllAsJson();
        if (localData.isNotEmpty) {
          await driveService.backupData(localData);
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
