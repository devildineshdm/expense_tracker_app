import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('माझा हिशोब'),
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
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
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
              _buildSummaryCard(context, appState, currencyFormat),
              const SizedBox(height: 8),
              Expanded(
                child: appState.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'अजून कुठलीही नोंद नाही.\n+ बटण दाबून पहिली entry टाका.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey),
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
        label: const Text('नोंद करा'),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, AppState appState, NumberFormat fmt) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'सध्याची शिल्लक (Balance)',
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
                _summaryItem('Income', appState.totalIncome, Colors.green, fmt),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _summaryItem('Expense', appState.totalExpense, Colors.red, fmt),
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
      final success = await appState.signInWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Google Drive shी jodla gela! Data automatically backup hoil.'
                : 'Sign-in fail jhala, parat try kara.'),
          ),
        );
      }
    }
  }
}
