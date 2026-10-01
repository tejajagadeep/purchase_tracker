import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryConstants {
  static const String all = 'All';

  static const List<String> defaultCategories = [
    'Riding Gear',
    'Camping',
    'Camera / Electronics',
    'Luggage',
    'Bike Tools',
    'Bike Accessories',
    'Safety',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Riding Gear':
        return Icons.sports_motorsports;
      case 'Camping':
        return Icons.other_houses;
      case 'Camera / Electronics':
        return Icons.photo_camera;
      case 'Luggage':
        return Icons.work;
      case 'Bike Tools':
        return Icons.build;
      case 'Bike Accessories':
        return Icons.two_wheeler;
      case 'Safety':
        return Icons.security;
      default:
        return Icons.category_outlined;
    }
  }
}

class CategoryManager {
  static const String _categoriesKey = 'custom_categories_v1';

  static Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_categoriesKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isNotEmpty) {
          return decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return List<String>.from(CategoryConstants.defaultCategories);
  }

  static Future<void> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(categories);
      await prefs.setString(_categoriesKey, encoded);
    } catch (_) {}
  }
}
