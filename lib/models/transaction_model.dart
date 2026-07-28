// Ek income/expense entry cha model
class TransactionModel {
  final String id;
  final String type; // 'income' ki 'expense'
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String paymentMode; // Cash, Bank, UPI, Card

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.paymentMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'paymentMode': paymentMode,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      note: map['note'] ?? '',
      date: DateTime.parse(map['date']),
      paymentMode: map['paymentMode'] ?? 'Cash',
    );
  }
}

// Predefined categories
class Categories {
  static const List<String> income = [
    'Salary',
    'Business',
    'Freelance',
    'Interest',
    'Gift',
    'Other Income',
  ];

  static const List<String> expense = [
    'Food',
    'Transport',
    'Rent',
    'Groceries',
    'Utilities',
    'Shopping',
    'Medical',
    'Education',
    'Entertainment',
    'EMI/Loan',
    'Other Expense',
  ];

  static const List<String> paymentModes = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Card',
  ];
}
