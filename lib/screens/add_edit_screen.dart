import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../utils/app_state.dart';

class AddEditScreen extends StatefulWidget {
  final TransactionModel? existingTransaction;
  const AddEditScreen({super.key, this.existingTransaction});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _category;
  String _paymentMode = 'Cash';
  DateTime _date = DateTime.now();

  bool get isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.existingTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toStringAsFixed(2);
      _noteController.text = t.note;
      _category = t.category;
      _paymentMode = t.paymentMode;
      _date = t.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _type == 'income' ? Categories.income : Categories.expense;
    if (_category != null && !categories.contains(_category)) {
      _category = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'नोंद edit करा' : 'नवीन नोंद'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Income / Expense toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: 'income',
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (val) {
                setState(() {
                  _type = val.first;
                  _category = null;
                });
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'रक्कम (Amount)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'रक्कम टाका';
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return 'बरोबर रक्कम टाका';
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val),
              validator: (val) => val == null ? 'Category निवडा' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
                border: OutlineInputBorder(),
              ),
              items: Categories.paymentModes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _paymentMode = val!),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                  '${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? 'Update करा' : 'Save करा'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final txn = TransactionModel(
      id: isEditing ? widget.existingTransaction!.id : const Uuid().v4(),
      type: _type,
      amount: double.parse(_amountController.text),
      category: _category!,
      note: _noteController.text.trim(),
      date: _date,
      paymentMode: _paymentMode,
    );

    if (isEditing) {
      appState.updateTransaction(txn);
    } else {
      appState.addTransaction(txn);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
