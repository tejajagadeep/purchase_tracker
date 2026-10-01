import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_item.dart';
import '../models/purchase_group.dart';
import '../models/sub_group.dart';
import '../data/sample_data.dart';

abstract class IPurchaseRepository {
  Future<List<PurchaseItem>> getItems({String? groupId, String? subGroupId});
  Future<void> saveItems(List<PurchaseItem> items);
  Future<void> saveItemsForGroup(String groupId, List<PurchaseItem> groupItems);
  Future<List<PurchaseGroup>> getGroups({bool includeTemplates = false});
  Future<List<PurchaseGroup>> getTemplateGroups();
  Future<List<PurchaseItem>> getTemplateItems({String? templateGroupId});
  Future<void> saveGroups(List<PurchaseGroup> groups);
  Future<void> deleteGroup(String groupId);
  Future<List<SubGroup>> getSubGroups({String? groupId});
  Future<void> saveSubGroups(List<SubGroup> subGroups);
}

class PurchaseRepository implements IPurchaseRepository {
  static const String _itemsStorageKey = 'purchase_items_v1';
  static const String _groupsStorageKey = 'purchase_groups_v1';
  static const String _subGroupsStorageKey = 'purchase_subgroups_v1';

  @override
  Future<List<PurchaseItem>> getItems({String? groupId, String? subGroupId}) async {
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

      if (subGroupId != null) {
        return allItems.where((i) => i.subGroupId == subGroupId).toList();
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
  Future<List<PurchaseGroup>> getGroups({bool includeTemplates = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_groupsStorageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isNotEmpty) {
          final list = decoded.map((g) => PurchaseGroup.fromMap(g)).toList();
          if (!includeTemplates) {
            return list.where((g) => !g.isTemplate).toList();
          }
          return list;
        }
      }
    } catch (_) {}

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
  Future<List<PurchaseGroup>> getTemplateGroups() async {
    final allGroups = await getGroups(includeTemplates: true);
    final templates = allGroups.where((g) => g.isTemplate).toList();
    if (templates.isEmpty) {
      final defaults = getInitialTemplateGroups();
      final updatedGroups = [...allGroups, ...defaults];
      await saveGroups(updatedGroups);

      // Save template items
      final currentItems = await getItems();
      final templateItems = getInitialTemplateItems();
      await saveItems([...currentItems, ...templateItems]);

      return defaults;
    }
    return templates;
  }

  @override
  Future<List<PurchaseItem>> getTemplateItems({String? templateGroupId}) async {
    final allItems = await getItems();
    final templateGroups = await getTemplateGroups();
    final templateGroupIds = templateGroups.map((g) => g.id).toSet();

    final items = allItems.where((i) => templateGroupIds.contains(i.groupId)).toList();

    if (items.isEmpty) {
      final defaultTemplateItems = getInitialTemplateItems();
      await saveItems([...allItems, ...defaultTemplateItems]);
      if (templateGroupId != null) {
        return defaultTemplateItems.where((i) => i.groupId == templateGroupId).toList();
      }
      return defaultTemplateItems;
    }

    if (templateGroupId != null) {
      return items.where((i) => i.groupId == templateGroupId).toList();
    }
    return items;
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
      final groups = await getGroups(includeTemplates: true);
      groups.removeWhere((g) => g.id == groupId);
      await saveGroups(groups);

      final allItems = await getItems();
      allItems.removeWhere((i) => i.groupId == groupId);
      await saveItems(allItems);

      final subGroups = await getSubGroups();
      subGroups.removeWhere((sg) => sg.groupId == groupId);
      await saveSubGroups(subGroups);
    } catch (_) {}
  }

  @override
  Future<List<SubGroup>> getSubGroups({String? groupId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_subGroupsStorageKey);

      List<SubGroup> allSubGroups = [];
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        allSubGroups = decoded.map((sg) => SubGroup.fromMap(sg)).toList();
      }

      if (groupId != null) {
        return allSubGroups.where((sg) => sg.groupId == groupId).toList();
      }
      return allSubGroups;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSubGroups(List<SubGroup> subGroups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(subGroups.map((sg) => sg.toMap()).toList());
      await prefs.setString(_subGroupsStorageKey, encoded);
    } catch (_) {}
  }
}
