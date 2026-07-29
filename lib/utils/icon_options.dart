import 'package:flutter/material.dart';
import '../models/category_model.dart';

// Category sathi nivadnyasathi icons cha curated set (kuthlihi extra package nahi lagat,
// Flutter cha built-in Material icons vaparto)
class IconOptions {
  static const List<IconData> expenseIcons = [
    Icons.restaurant,        // Food
    Icons.local_taxi,        // Transport
    Icons.house,             // Rent
    Icons.shopping_cart,     // Groceries
    Icons.bolt,              // Utilities
    Icons.shopping_bag,      // Shopping
    Icons.medical_services,  // Medical
    Icons.school,            // Education
    Icons.movie,             // Entertainment
    Icons.account_balance,   // EMI/Loan
    Icons.checkroom,         // Clothes
    Icons.local_drink,       // Drinks
    Icons.local_gas_station, // Fuel
    Icons.celebration,       // Fun
    Icons.local_hospital,    // Health
    Icons.directions_car,    // Highway/Travel
    Icons.hotel,             // Hotel
    Icons.inventory_2,       // Merchandise
    Icons.pets,              // Pets
    Icons.person,            // Personal
    Icons.restaurant_menu,   // Restaurant
    Icons.card_giftcard,     // Tips/Gifts
    Icons.phone_android,     // Mobile/Recharge
    Icons.wifi,              // Internet
    Icons.sports_esports,    // Games
    Icons.fitness_center,    // Gym
    Icons.flight,            // Travel/Flight
    Icons.local_pharmacy,    // Pharmacy
    Icons.child_care,        // Baby/Kids
    Icons.book,              // Books
    Icons.tv,                // Subscriptions/TV
    Icons.coffee,            // Coffee/Cafe
    Icons.local_laundry_service, // Laundry
    Icons.build,             // Repairs/Maintenance
    Icons.credit_card,       // Card payments
    Icons.spa,               // Salon/Spa
    Icons.beach_access,      // Vacation
    Icons.pedal_bike,        // Cycle/Bike
    Icons.electric_bolt,     // Electricity
    Icons.water_drop,        // Water bill
    Icons.local_florist,     // Gardening/Flowers
    Icons.cake,              // Celebration/Cake
    Icons.smoking_rooms,     // Habits
    Icons.currency_rupee,    // Generic money
    Icons.receipt_long,      // Bills
    Icons.category,          // Other
  ];

  static const List<IconData> incomeIcons = [
    Icons.work,              // Salary
    Icons.business_center,   // Business
    Icons.laptop_mac,        // Freelance
    Icons.percent,           // Interest
    Icons.card_giftcard,     // Gift
    Icons.trending_up,       // Investment
    Icons.storefront,        // Sales
    Icons.two_wheeler,       // Delivery/Swiggy type
    Icons.account_balance_wallet, // Loan received
    Icons.attach_money,      // Other Income
    Icons.savings,           // Savings/Interest
    Icons.real_estate_agent, // Rent received
    Icons.currency_rupee,    // Generic money
    Icons.redeem,            // Rewards/Cashback
    Icons.handshake,         // Deal/Partnership
    Icons.emoji_events,      // Bonus/Prize
    Icons.family_restroom,   // Family support
  ];

  static const List<Color> colorPalette = [
    Color(0xFF5C6BC0), // indigo
    Color(0xFFFFA726), // orange
    Color(0xFF42A5F5), // blue
    Color(0xFF66BB6A), // green
    Color(0xFF26A69A), // teal
    Color(0xFFAB47BC), // purple
    Color(0xFFEF5350), // red
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF29B6F6), // light blue
    Color(0xFFFFCA28), // amber
    Color(0xFF78909C), // blue grey
  ];
}

// App पहिल्यांदा उघडल्यावर या default categories DB मध्ये टाकल्या जातात
class DefaultCategories {
  static List<CategoryModel> seed() {
    final expense = <Map<String, dynamic>>[
      {'name': 'Food', 'icon': Icons.restaurant, 'color': 0xFF66BB6A},
      {'name': 'Transport', 'icon': Icons.local_taxi, 'color': 0xFFFFA726},
      {'name': 'Rent', 'icon': Icons.house, 'color': 0xFF5C6BC0},
      {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': 0xFF26A69A},
      {'name': 'Utilities', 'icon': Icons.bolt, 'color': 0xFFFFCA28},
      {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': 0xFFEC407A},
      {'name': 'Medical', 'icon': Icons.medical_services, 'color': 0xFFEF5350},
      {'name': 'Education', 'icon': Icons.school, 'color': 0xFF42A5F5},
      {'name': 'Entertainment', 'icon': Icons.movie, 'color': 0xFFAB47BC},
      {'name': 'EMI/Loan', 'icon': Icons.account_balance, 'color': 0xFF8D6E63},
      {'name': 'Fuel', 'icon': Icons.local_gas_station, 'color': 0xFF78909C},
      {'name': 'Other Expense', 'icon': Icons.category, 'color': 0xFF78909C},
    ];
    final income = <Map<String, dynamic>>[
      {'name': 'Salary', 'icon': Icons.work, 'color': 0xFF42A5F5},
      {'name': 'Business', 'icon': Icons.business_center, 'color': 0xFF66BB6A},
      {'name': 'Freelance', 'icon': Icons.laptop_mac, 'color': 0xFF29B6F6},
      {'name': 'Interest', 'icon': Icons.percent, 'color': 0xFFFFCA28},
      {'name': 'Gift', 'icon': Icons.card_giftcard, 'color': 0xFFEC407A},
      {'name': 'Other Income', 'icon': Icons.attach_money, 'color': 0xFF78909C},
    ];

    final List<CategoryModel> all = [];
    int counter = 0;
    for (final e in expense) {
      all.add(CategoryModel(
        id: 'seed_exp_${counter++}',
        name: e['name'],
        type: 'expense',
        iconCodePoint: (e['icon'] as IconData).codePoint,
        colorValue: e['color'],
      ));
    }
    for (final i in income) {
      all.add(CategoryModel(
        id: 'seed_inc_${counter++}',
        name: i['name'],
        type: 'income',
        iconCodePoint: (i['icon'] as IconData).codePoint,
        colorValue: i['color'],
      ));
    }
    return all;
  }
}
