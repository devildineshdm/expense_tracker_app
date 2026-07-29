import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../utils/app_state.dart';
import '../utils/app_language.dart';

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
  String? _receiptPath; // Bill/receipt cha local photo path (optional)
  String? _receiptDriveId;

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
      _receiptPath = t.receiptLocalPath;
      _receiptDriveId = t.receiptDriveId;
    }
  }

  Future<void> _pickReceiptPhoto() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('फोटो काढा (Camera)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery मधून निवडा'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final picked = await picker.pickImage(source: choice, imageQuality: 70);
    if (picked == null) return;

    // Photo la app cha permanent folder madhe copy karto
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile =
        await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() {
      _receiptPath = savedFile.path;
      _receiptDriveId = null; // navin photo, Drive var punha upload hoil
    });
  }

  void _removeReceiptPhoto() {
    setState(() {
      _receiptPath = null;
      _receiptDriveId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final appState = Provider.of<AppState>(context);
    final categories = appState.categoriesFor(_type);

    if (_category != null && !categories.any((c) => c.name == _category)) {
      _category = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? lang.t('edit_entry') : lang.t('new_entry')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'expense',
                    label: Text(lang.t('expense')),
                    icon: const Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: 'income',
                    label: Text(lang.t('income')),
                    icon: const Icon(Icons.arrow_downward)),
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
              decoration: InputDecoration(
                labelText: lang.t('amount'),
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'रक्कम टाका';
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return 'बरोबर रक्कम टाका';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text(lang.t('category'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final selected = cat.name == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.name),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: selected
                            ? cat.color
                            : cat.color.withOpacity(0.35),
                        child: Icon(cat.icon,
                            color: Colors.white,
                            size: selected ? 24 : 20),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 64,
                        child: Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (_category == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Category निवडा',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: InputDecoration(
                labelText: lang.t('payment_mode'),
                border: const OutlineInputBorder(),
              ),
              items: ['Cash', 'Bank Transfer', 'UPI', 'Card']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _paymentMode = val!),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(lang.t('date')),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
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
              decoration: InputDecoration(
                labelText: lang.t('note'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Text('Bill / Receipt फोटो (optional)',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_receiptPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_receiptPath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                        onPressed: _removeReceiptPhoto,
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickReceiptPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Bill चा फोटो जोडा'),
              ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? lang.t('update') : lang.t('save')),
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
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया Category निवडा')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final txn = TransactionModel(
      id: isEditing ? widget.existingTransaction!.id : const Uuid().v4(),
      type: _type,
      amount: double.parse(_amountController.text),
      category: _category!,
      note: _noteController.text.trim(),
      date: _date,
      paymentMode: _paymentMode,
      receiptLocalPath: _receiptPath,
      receiptDriveId: _receiptDriveId,
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
