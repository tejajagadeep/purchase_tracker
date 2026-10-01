import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/categories.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../repositories/purchase_repository.dart';

class BackupService {
  final IPurchaseRepository _repository = PurchaseRepository();

  Future<String> createBackupJson() async {
    final groups = await _repository.getGroups();
    final items = await _repository.getItems();
    final categories = await CategoryManager.loadCategories();

    final Map<String, dynamic> backupData = {
      'app': 'Purchase Tracker',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groups.map((g) => g.toMap()).toList(),
      'categories': categories,
      'items': items.map((i) => i.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<bool> exportBackup() async {
    try {
      final jsonString = await createBackupJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      final xFile = XFile.fromData(
        bytes,
        name: 'Purchase_Tracker_Backup_${DateTime.now().millisecondsSinceEpoch}.json',
        mimeType: 'application/json',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Purchase Tracker Backup Data',
        subject: 'Purchase Tracker Backup',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreFromRawJson(String jsonString, {bool merge = false}) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);

      List<PurchaseGroup> newGroups = [];
      if (decoded['groups'] != null) {
        final List<dynamic> gList = decoded['groups'];
        newGroups = gList.map((g) => PurchaseGroup.fromMap(g)).toList();
      }

      List<String> newCategories = [];
      if (decoded['categories'] != null) {
        final List<dynamic> cList = decoded['categories'];
        newCategories = cList.map((c) => c.toString()).toList();
      }

      List<PurchaseItem> newItems = [];
      if (decoded['items'] != null) {
        final List<dynamic> iList = decoded['items'];
        newItems = iList.map((i) => PurchaseItem.fromMap(i)).toList();
      }

      if (merge) {
        final existingGroups = await _repository.getGroups();
        final existingItems = await _repository.getItems();
        final existingCategories = await CategoryManager.loadCategories();

        final mergedGroupsMap = {for (var g in existingGroups) g.id: g};
        for (var g in newGroups) {
          mergedGroupsMap[g.id] = g;
        }

        final mergedItemsMap = {for (var i in existingItems) i.id: i};
        for (var i in newItems) {
          mergedItemsMap[i.id] = i;
        }

        final mergedCategories = {...existingCategories, ...newCategories}.toList();

        await _repository.saveGroups(mergedGroupsMap.values.toList());
        await _repository.saveItems(mergedItemsMap.values.toList());
        await CategoryManager.saveCategories(mergedCategories);
      } else {
        if (newGroups.isNotEmpty) {
          await _repository.saveGroups(newGroups);
        }
        if (newItems.isNotEmpty) {
          await _repository.saveItems(newItems);
        }
        if (newCategories.isNotEmpty) {
          await CategoryManager.saveCategories(newCategories);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> importFromFile({bool merge = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String jsonString = '';

        if (file.bytes != null) {
          jsonString = utf8.decode(file.bytes!);
        }
        if (jsonString.isNotEmpty) {
          return await restoreFromRawJson(jsonString, merge: merge);
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
