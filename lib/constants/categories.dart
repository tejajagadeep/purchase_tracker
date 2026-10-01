import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryConstants {
  static const String all = 'All';

  static const List<String> defaultCategories = [
    'Riding Gear',
    'Camping',
    'Camera / Electronics',
    'Luggage & Bags',
    'Bike Tools & Parts',
    'Bike Accessories',
    'Safety & Protection',
    'Food & Dining',
    'Groceries & Supplies',
    'Fuel & Petrol',
    'Travel & Hotels',
    'Clothing & Fashion',
    'Health & Medical',
    'Bills & Utilities',
    'Rent & Housing',
    'Entertainment',
    'Gifts & Donations',
    'Sports & Fitness',
    'Education & Books',
    'Services & Repair',
    'Other',
  ];

  static const Map<String, IconData> predefinedIcons = {
    'Riding Gear': Icons.sports_motorsports,
    'Camping': Icons.other_houses,
    'Camera / Electronics': Icons.photo_camera,
    'Luggage & Bags': Icons.work,
    'Bike Tools & Parts': Icons.build,
    'Bike Accessories': Icons.two_wheeler,
    'Safety & Protection': Icons.security,
    'Food & Dining': Icons.restaurant,
    'Groceries & Supplies': Icons.shopping_cart,
    'Fuel & Petrol': Icons.local_gas_station,
    'Travel & Hotels': Icons.hotel,
    'Clothing & Fashion': Icons.checkroom,
    'Health & Medical': Icons.medical_services,
    'Bills & Utilities': Icons.receipt_long,
    'Rent & Housing': Icons.home,
    'Entertainment': Icons.movie,
    'Gifts & Donations': Icons.card_giftcard,
    'Sports & Fitness': Icons.fitness_center,
    'Education & Books': Icons.school,
    'Services & Repair': Icons.construction,
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
    Icons.category_outlined,
  ];

  static Map<String, int> _customIconsMap = {};

  static void setCustomIcons(Map<String, int> map) {
    _customIconsMap = map;
  }

  static IconData getIcon(String category) {
    if (_customIconsMap.containsKey(category)) {
      // ignore: non_const_argument_for_const_parameter
      return IconData(_customIconsMap[category]!, fontFamily: 'MaterialIcons');
    }
    if (predefinedIcons.containsKey(category)) {
      return predefinedIcons[category]!;
    }
    // Keyword match
    final lower = category.toLowerCase();
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

      final mergedList = mergedSet.toList();
      await saveCategories(mergedList);
      return mergedList;
    } catch (_) {}
    return List<String>.from(CategoryConstants.defaultCategories);
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
