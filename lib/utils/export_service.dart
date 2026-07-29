import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

// Ha service sagla transactions cha data ek Excel (.xlsx) file madhe
// convert karto, ani mobile chya share sheet ne user la share/save karnyasathi deto
// (WhatsApp, Google Drive, Gmail, Files app - kuthehi save karta yeto)
class ExportService {
  static Future<void> exportToExcel(
      List<TransactionModel> transactions) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    excel.setDefaultSheet('Transactions');

    // Header row
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Note'),
    ]);

    final dateFmt = DateFormat('dd-MM-yyyy');
    // Latest aadhi dakhvto ahot tar file madhe date-wise (junat aadhi) taknyasathi reverse
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in sorted) {
      sheet.appendRow([
        TextCellValue(dateFmt.format(t.date)),
        TextCellValue(t.type == 'income' ? 'Income' : 'Expense'),
        TextCellValue(t.category),
        DoubleCellValue(t.amount),
        TextCellValue(t.paymentMode),
        TextCellValue(t.note),
      ]);
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    // Summary rows shevti
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Total Income'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalIncome),
    ]);
    sheet.appendRow([
      TextCellValue('Total Expense'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalExpense),
    ]);
    sheet.appendRow([
      TextCellValue('Balance'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalIncome - totalExpense),
    ]);

    // Column widths jara vaढवतो, readable disण्यासाठी
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 24);

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final fileName =
        'expense_tracker_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(filePath)],
        text: 'माझा Expense Tracker data (Excel file)');
  }
}
