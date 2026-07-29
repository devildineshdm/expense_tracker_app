import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/app_language.dart';
import '../utils/export_service.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_screen.dart';
import 'reports_screen.dart';
import 'categories_screen.dart';
import 'pin_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final lang = Provider.of<AppLanguage>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('app_title')),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) {
              if (appState.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: Icon(appState.driveService.isSignedIn
                    ? Icons.cloud_done
                    : Icons.cloud_off),
                tooltip: appState.driveService.isSignedIn
                    ? 'Google Drive shी connect ahe'
                    : 'Google Drive backup suru kara',
                onPressed: () => _handleDriveTap(context, appState),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: lang.t('reports'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenu(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'categories',
                child: Row(children: [
                  const Icon(Icons.category, size: 20),
                  const SizedBox(width: 10),
                  Text(lang.t('manage_categories')),
                ]),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(children: [
                  Icon(Icons.file_download, size: 20),
                  SizedBox(width: 10),
                  Text('Excel मध्ये Export करा'),
                ]),
              ),
              const PopupMenuItem(
                value: 'pin',
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 10),
                  Text('App PIN Lock सेट करा'),
                ]),
              ),
              PopupMenuItem(
                value: 'language',
                child: Row(children: [
                  const Icon(Icons.language, size: 20),
                  const SizedBox(width: 10),
                  Text('${lang.t('language')}: ${lang.code == 'mr' ? 'मराठी' : 'English'}'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildSummaryCard(context, appState, currencyFormat, lang),
              const SizedBox(height: 8),
              Expanded(
                child: appState.transactions.isEmpty
                    ? Center(
                        child: Text(
                          lang.t('no_entries'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: appState.transactions.length,
                        itemBuilder: (context, index) {
                          final txn = appState.transactions[index];
                          return TransactionTile(transaction: txn);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddEditScreen()));
        },
        icon: const Icon(Icons.add),
        label: Text(lang.t('add_entry')),
      ),
    );
  }

  void _handleMenu(BuildContext context, String value) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = Provider.of<AppLanguage>(context, listen: false);

    switch (value) {
      case 'categories':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoriesScreen()));
        break;
      case 'export':
        if (appState.transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export करण्यासाठी आधी entries टाका.')));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel file तयार होतोय...')));
        await ExportService.exportToExcel(appState.transactions);
        break;
      case 'pin':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SetPinScreen()));
        break;
      case 'language':
        final newCode = lang.code == 'mr' ? 'en' : 'mr';
        lang.setLanguage(newCode);
        break;
    }
  }

  Widget _buildSummaryCard(BuildContext context, AppState appState,
      NumberFormat fmt, AppLanguage lang) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              lang.t('balance'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              fmt.format(appState.balance),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: appState.balance >= 0 ? Colors.green.shade700 : Colors.red,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryItem(
                    lang.t('income'), appState.totalIncome, Colors.green, fmt),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _summaryItem(
                    lang.t('expense'), appState.totalExpense, Colors.red, fmt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      String label, double amount, Color color, NumberFormat fmt) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          fmt.format(amount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Future<void> _handleDriveTap(BuildContext context, AppState appState) async {
    if (appState.driveService.isSignedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Google Drive'),
          content: Text(
              '${appState.driveService.currentUser?.email} sobat connect ahe.\nData automatically backup hoto.'),
          actions: [
            TextButton(
              onPressed: () async {
                await appState.signOut();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Sign Out'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Band kara'),
            ),
          ],
        ),
      );
    } else {
      final error = await appState.signInWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error == null
                ? 'Google Drive shी jodla gela! Data automatically backup hoil.'
                : 'Sign-in fail: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
