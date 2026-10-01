import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_item.dart';
import '../models/purchase_group.dart';
import '../data/sample_data.dart';

abstract class IPurchaseRepository {
  Future<List<PurchaseItem>> getItems({String? groupId});
  Future<void> saveItems(List<PurchaseItem> items);
  Future<void> saveItemsForGroup(String groupId, List<PurchaseItem> groupItems);
  Future<List<PurchaseGroup>> getGroups();
  Future<void> saveGroups(List<PurchaseGroup> groups);
  Future<void> deleteGroup(String groupId);
}

class PurchaseRepository implements IPurchaseRepository {
  static const String _itemsStorageKey = 'purchase_items_v1';
  static const String _groupsStorageKey = 'purchase_groups_v1';

  @override
  Future<List<PurchaseItem>> getItems({String? groupId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_itemsStorageKey);

      List<PurchaseItem> allItems = [];
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isNotEmpty) {
          allItems = decoded.map((item) => PurchaseItem.fromMap(item)).toList();
        } else {
          allItems = getInitialSampleData();
          await saveItems(allItems);
        }
      } else {
        allItems = getInitialSampleData();
        await saveItems(allItems);
      }

      if (groupId != null) {
        return allItems.where((i) => i.groupId == groupId).toList();
      }
      return allItems;
    } catch (_) {
      final initial = getInitialSampleData();
      if (groupId != null) {
        return initial.where((i) => i.groupId == groupId).toList();
      }
      return initial;
    }
  }

  @override
  Future<void> saveItems(List<PurchaseItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(items.map((item) => item.toMap()).toList());
      await prefs.setString(_itemsStorageKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> saveItemsForGroup(String groupId, List<PurchaseItem> groupItems) async {
    try {
      final allItems = await getItems();
      allItems.removeWhere((item) => item.groupId == groupId);
      allItems.addAll(groupItems);
      await saveItems(allItems);
    } catch (_) {}
  }

  @override
  Future<List<PurchaseGroup>> getGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_groupsStorageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isNotEmpty) {
          return decoded.map((g) => PurchaseGroup.fromMap(g)).toList();
        }
      }
    } catch (_) {}

    // Default Group for Version 1
    final defaultGroup = PurchaseGroup(
      id: 'bike_touring',
      name: 'Bike Touring Accessories',
      description: 'Touring accessories and gear purchases',
      iconName: 'two_wheeler',
    );
    final initialGroups = [defaultGroup];
    await saveGroups(initialGroups);
    return initialGroups;
  }

  @override
  Future<void> saveGroups(List<PurchaseGroup> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(groups.map((g) => g.toMap()).toList());
      await prefs.setString(_groupsStorageKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      final groups = await getGroups();
      groups.removeWhere((g) => g.id == groupId);
      await saveGroups(groups);

      final allItems = await getItems();
      allItems.removeWhere((i) => i.groupId == groupId);
      await saveItems(allItems);
    } catch (_) {}
  }
}
