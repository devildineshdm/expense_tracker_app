import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_state.dart';
import '../screens/add_edit_screen.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat('dd MMM yyyy');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('नोंद delete करायची?'),
            content: const Text('ही entry कायमची delete होईल.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('नको')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('हो, delete करा')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        Provider.of<AppState>(context, listen: false)
            .deleteTransaction(transaction.id);
      },
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEditScreen(existingTransaction: transaction)),
          );
        },
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        title: Text(transaction.category,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${dateFmt.format(transaction.date)} • ${transaction.paymentMode}'
          '${transaction.note.isNotEmpty ? '\n${transaction.note}' : ''}',
        ),
        isThreeLine: transaction.note.isNotEmpty,
        trailing: Text(
          '${isIncome ? '+' : '-'} ${fmt.format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}
