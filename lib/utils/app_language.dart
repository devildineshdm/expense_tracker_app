import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ha ek halka language system ahe - purna Flutter localization (l10n) na vaparta,
// ek simple strings map vaparun English/Marathi switch karto.
class AppLanguage extends ChangeNotifier {
  String _code = 'mr'; // default Marathi
  String get code => _code;

  static const Map<String, Map<String, String>> _strings = {
    'mr': {
      'app_title': 'माझा हिशोब',
      'balance': 'सध्याची शिल्लक (Balance)',
      'income': 'Income',
      'expense': 'Expense',
      'add_entry': 'नोंद करा',
      'no_entries': 'अजून कुठलीही नोंद नाही.\n+ बटण दाबून पहिली entry टाका.',
      'reports': 'Reports',
      'categories': 'Categories',
      'new_entry': 'नवीन नोंद',
      'edit_entry': 'नोंद edit करा',
      'amount': 'रक्कम (Amount)',
      'category': 'Category',
      'payment_mode': 'Payment Mode',
      'date': 'Date',
      'note': 'Note (optional)',
      'save': 'Save करा',
      'update': 'Update करा',
      'delete': 'Delete',
      'monthly_chart_title': 'महिन्यानुसार Income vs Expense',
      'category_chart_title': 'Category नुसार विभागणी',
      'filter_period': 'कालावधी निवडा',
      'today': 'आज',
      'this_week': 'हा आठवडा',
      'this_month': 'हा महिना',
      'this_year': 'हे वर्ष',
      'all_time': 'सर्व वेळ',
      'custom_range': 'स्वतःची तारीख निवडा',
      'manage_categories': 'Categories manage करा',
      'add_category': 'नवीन Category',
      'edit_category': 'Category edit करा',
      'category_name': 'Category चं नाव',
      'choose_icon': 'Icon निवडा',
      'choose_color': 'Color निवडा',
      'language': 'Language',
    },
    'en': {
      'app_title': 'My Expenses',
      'balance': 'Current Balance',
      'income': 'Income',
      'expense': 'Expense',
      'add_entry': 'Add Entry',
      'no_entries': 'No entries yet.\nTap + to add your first one.',
      'reports': 'Reports',
      'categories': 'Categories',
      'new_entry': 'New Entry',
      'edit_entry': 'Edit Entry',
      'amount': 'Amount',
      'category': 'Category',
      'payment_mode': 'Payment Mode',
      'date': 'Date',
      'note': 'Note (optional)',
      'save': 'Save',
      'update': 'Update',
      'delete': 'Delete',
      'monthly_chart_title': 'Monthly Income vs Expense',
      'category_chart_title': 'Category-wise Breakdown',
      'filter_period': 'Select Period',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'this_year': 'This Year',
      'all_time': 'All Time',
      'custom_range': 'Custom Range',
      'manage_categories': 'Manage Categories',
      'add_category': 'New Category',
      'edit_category': 'Edit Category',
      'category_name': 'Category Name',
      'choose_icon': 'Choose Icon',
      'choose_color': 'Choose Color',
      'language': 'Language',
    },
  };

  String t(String key) {
    return _strings[_code]?[key] ?? _strings['en']![key] ?? key;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString('app_language') ?? 'mr';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _code = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    notifyListeners();
  }
}
