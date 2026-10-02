import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryConstants {
  static const String all = 'All';

  static const List<String> defaultCategories = [
    'Bike Accessories',
    'Bike Tools & Parts',
    'Bills & Utilities',
    'Camera / Electronics',
    'Camping',
    'Clothing & Fashion',
    'Debt & Repayment',
    'Education & Books',
    'Entertainment',
    'Food & Dining',
    'Fuel & Petrol',
    'Gifts & Donations',
    'Groceries & Supplies',
    'Health & Medical',
    'Loan & EMI',
    'Luggage & Bags',
    'Rent & Housing',
    'Riding Gear',
    'Safety & Protection',
    'Services & Repair',
    'Sports & Fitness',
    'Travel & Hotels',
    'Other',
  ];

  static const Map<String, IconData> predefinedIcons = {
    'Bike Accessories': Icons.two_wheeler,
    'Bike Tools & Parts': Icons.build,
    'Bills & Utilities': Icons.receipt_long,
    'Camera / Electronics': Icons.photo_camera,
    'Camping': Icons.other_houses,
    'Clothing & Fashion': Icons.checkroom,
    'Debt & Repayment': Icons.request_quote,
    'Education & Books': Icons.school,
    'Entertainment': Icons.movie,
    'Food & Dining': Icons.restaurant,
    'Fuel & Petrol': Icons.local_gas_station,
    'Gifts & Donations': Icons.card_giftcard,
    'Groceries & Supplies': Icons.shopping_cart,
    'Health & Medical': Icons.medical_services,
    'Loan & EMI': Icons.account_balance,
    'Luggage & Bags': Icons.work,
    'Rent & Housing': Icons.home,
    'Riding Gear': Icons.sports_motorsports,
    'Safety & Protection': Icons.security,
    'Services & Repair': Icons.construction,
    'Sports & Fitness': Icons.fitness_center,
    'Travel & Hotels': Icons.hotel,
    'Other': Icons.category_outlined,
  };

  static const List<IconData> selectableIcons = [
    Icons.sports_motorsports,
    Icons.other_houses,
    Icons.photo_camera,
    Icons.work,
    Icons.build,
    Icons.two_wheeler,
    Icons.security,
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.local_gas_station,
    Icons.hotel,
    Icons.checkroom,
    Icons.medical_services,
    Icons.receipt_long,
    Icons.home,
    Icons.account_balance,
    Icons.request_quote,
    Icons.credit_card,
    Icons.account_balance_wallet,
    Icons.movie,
    Icons.card_giftcard,
    Icons.fitness_center,
    Icons.school,
    Icons.construction,
    Icons.directions_car,
    Icons.flight,
    Icons.phone_iphone,
    Icons.laptop,
    Icons.pets,
    Icons.child_care,
    Icons.monetization_on,
    Icons.cleaning_services,
    Icons.local_mall,
    Icons.handshake,
    Icons.category_outlined,
  ];

  static Map<String, int> _customIconsMap = {};

  static void setCustomIcons(Map<String, int> map) {
    _customIconsMap = map;
  }

  static IconData getIcon(String category) {
    if (_customIconsMap.containsKey(category)) {
      final code = _customIconsMap[category]!;
      for (final icon in selectableIcons) {
        if (icon.codePoint == code) return icon;
      }
    }
    if (predefinedIcons.containsKey(category)) {
      return predefinedIcons[category]!;
    }
    // Keyword match
    final lower = category.toLowerCase();
    if (lower.contains('loan') || lower.contains('emi') || lower.contains('bank') || lower.contains('mortgage')) {
      return Icons.account_balance;
    }
    if (lower.contains('debt') || lower.contains('repay') || lower.contains('credit') || lower.contains('borrow') || lower.contains('lend')) {
      return Icons.request_quote;
    }
    if (lower.contains('gear') || lower.contains('riding')) return Icons.sports_motorsports;
    if (lower.contains('camp')) return Icons.other_houses;
    if (lower.contains('camera') || lower.contains('phone') || lower.contains('electronic')) return Icons.photo_camera;
    if (lower.contains('luggage') || lower.contains('bag')) return Icons.work;
    if (lower.contains('tool') || lower.contains('repair')) return Icons.build;
    if (lower.contains('bike') || lower.contains('touring')) return Icons.two_wheeler;
    if (lower.contains('car') || lower.contains('auto')) return Icons.directions_car;
    if (lower.contains('food') || lower.contains('eat') || lower.contains('dine')) return Icons.restaurant;
    if (lower.contains('grocery') || lower.contains('supermarket')) return Icons.shopping_cart;
    if (lower.contains('fuel') || lower.contains('petrol') || lower.contains('gas')) return Icons.local_gas_station;
    if (lower.contains('hotel') || lower.contains('stay') || lower.contains('flight')) return Icons.hotel;
    if (lower.contains('cloth') || lower.contains('dress')) return Icons.checkroom;
    if (lower.contains('health') || lower.contains('doctor') || lower.contains('med')) return Icons.medical_services;
    if (lower.contains('bill') || lower.contains('utility')) return Icons.receipt_long;
    if (lower.contains('rent') || lower.contains('home') || lower.contains('house')) return Icons.home;

    return Icons.category_outlined;
  }
}

class CategoryManager {
  static const String _categoriesKey = 'custom_categories_v1';
  static const String _categoryIconsKey = 'custom_category_icons_v1';

  static Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await loadCategoryIcons(prefs);
      final String? jsonString = prefs.getString(_categoriesKey);

      List<String> savedList = [];
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isNotEmpty) {
          savedList = decoded.map((e) => e.toString()).toList();
        }
      }

      final mergedSet = <String>{};
      mergedSet.addAll(CategoryConstants.defaultCategories);
      mergedSet.addAll(savedList);

      final mergedList = mergedSet.toList()
        ..sort((a, b) {
          if (a.toLowerCase() == 'other') return 1;
          if (b.toLowerCase() == 'other') return -1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });

      await saveCategories(mergedList);
      return mergedList;
    } catch (_) {}

    final list = List<String>.from(CategoryConstants.defaultCategories)
      ..sort((a, b) {
        if (a.toLowerCase() == 'other') return 1;
        if (b.toLowerCase() == 'other') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return list;
  }

  static Future<void> loadCategoryIcons(SharedPreferences prefs) async {
    try {
      final String? jsonString = prefs.getString(_categoryIconsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final Map<String, int> map = {};
        decoded.forEach((key, value) {
          if (value is int) {
            map[key] = value;
          }
        });
        CategoryConstants.setCustomIcons(map);
      }
    } catch (_) {}
  }

  static Future<void> saveCategoryIcon(String category, IconData icon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_categoryIconsKey);
      Map<String, dynamic> map = {};
      if (jsonString != null && jsonString.isNotEmpty) {
        map = jsonDecode(jsonString);
      }
      map[category] = icon.codePoint;
      await prefs.setString(_categoryIconsKey, jsonEncode(map));

      final Map<String, int> intMap = {};
      map.forEach((k, v) {
        if (v is int) intMap[k] = v;
      });
      CategoryConstants.setCustomIcons(intMap);
    } catch (_) {}
  }

  static Future<void> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(categories);
      await prefs.setString(_categoriesKey, encoded);
    } catch (_) {}
  }
}
