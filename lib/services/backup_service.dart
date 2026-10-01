import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/categories.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../repositories/purchase_repository.dart';

class BackupService {
  final IPurchaseRepository _repository = PurchaseRepository();

  // ---------------------------------------------------------------------------
  // Android Native File Picker Channel
  // ---------------------------------------------------------------------------

  static const MethodChannel _fileChannel = MethodChannel(
    'com.pj.purchase_tracker/file_picker',
  );

  // ---------------------------------------------------------------------------
  // CREATE BACKUP JSON
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // EXPORT / SHARE BACKUP
  // ---------------------------------------------------------------------------

  Future<bool> exportBackup() async {
    try {
      final jsonString = await createBackupJson();

      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      final fileName =
          'Purchase_Tracker_Backup_'
          '${DateTime.now().millisecondsSinceEpoch}.json';

      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/json',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Purchase Tracker Backup Data',
          subject: 'Purchase Tracker Backup',
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE BACKUP TO LOCAL FILE
  // ---------------------------------------------------------------------------

  Future<String?> saveBackupToLocalFile() async {
    try {
      final jsonString = await createBackupJson();

      final fileName =
          'Purchase_Tracker_Backup_'
          '${DateTime.now().millisecondsSinceEpoch}.json';

      // -----------------------------------------------------------------------
      // ANDROID
      //
      // Use Android's native "Save File" document picker.
      // -----------------------------------------------------------------------

      if (Platform.isAndroid) {
        try {
          final result = await _fileChannel.invokeMethod<String>('saveFile', {
            'fileName': fileName,
            'content': jsonString,
            'mimeType': 'application/json',
          });

          if (result != null && result.isNotEmpty) {
            return result;
          }
        } catch (_) {
          // Continue to fallback.
        }
      }

      // -----------------------------------------------------------------------
      // WINDOWS
      // -----------------------------------------------------------------------

      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];

        if (userProfile != null) {
          final downloadsDir = Directory('$userProfile\\Downloads');

          if (await downloadsDir.exists()) {
            final file = File('${downloadsDir.path}\\$fileName');

            await file.writeAsString(jsonString);

            return file.path;
          }
        }
      }

      // -----------------------------------------------------------------------
      // GENERIC FALLBACK
      // -----------------------------------------------------------------------

      Directory? directory;

      try {
        directory = await getDownloadsDirectory();
      } catch (_) {
        directory = null;
      }

      directory ??= await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // RESTORE FROM RAW JSON
  // ---------------------------------------------------------------------------

  Future<bool> restoreFromRawJson(
    String jsonString, {
    bool merge = false,
  }) async {
    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      // -----------------------------------------------------------------------
      // GROUPS
      // -----------------------------------------------------------------------

      final List<PurchaseGroup> newGroups = [];

      if (decoded['groups'] != null) {
        final groupsData = decoded['groups'];

        if (groupsData is List) {
          for (final groupData in groupsData) {
            if (groupData is Map) {
              newGroups.add(
                PurchaseGroup.fromMap(Map<String, dynamic>.from(groupData)),
              );
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // CATEGORIES
      // -----------------------------------------------------------------------

      final List<String> newCategories = [];

      if (decoded['categories'] != null) {
        final categoriesData = decoded['categories'];

        if (categoriesData is List) {
          for (final category in categoriesData) {
            newCategories.add(category.toString());
          }
        }
      }

      // -----------------------------------------------------------------------
      // ITEMS
      // -----------------------------------------------------------------------

      final List<PurchaseItem> newItems = [];

      if (decoded['items'] != null) {
        final itemsData = decoded['items'];

        if (itemsData is List) {
          for (final itemData in itemsData) {
            if (itemData is Map) {
              newItems.add(
                PurchaseItem.fromMap(Map<String, dynamic>.from(itemData)),
              );
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // MERGE DATA
      // -----------------------------------------------------------------------

      if (merge) {
        final existingGroups = await _repository.getGroups();

        final existingItems = await _repository.getItems();

        final existingCategories = await CategoryManager.loadCategories();

        // ---------------------------------------------------------------------
        // MERGE GROUPS
        // ---------------------------------------------------------------------

        final mergedGroupsMap = {
          for (final group in existingGroups) group.id: group,
        };

        for (final group in newGroups) {
          mergedGroupsMap[group.id] = group;
        }

        // ---------------------------------------------------------------------
        // MERGE ITEMS
        // ---------------------------------------------------------------------

        final mergedItemsMap = {
          for (final item in existingItems) item.id: item,
        };

        for (final item in newItems) {
          mergedItemsMap[item.id] = item;
        }

        // ---------------------------------------------------------------------
        // MERGE CATEGORIES
        // ---------------------------------------------------------------------

        final mergedCategories = {
          ...existingCategories,
          ...newCategories,
        }.toList();

        // ---------------------------------------------------------------------
        // SAVE MERGED DATA
        // ---------------------------------------------------------------------

        await _repository.saveGroups(mergedGroupsMap.values.toList());

        await _repository.saveItems(mergedItemsMap.values.toList());

        await CategoryManager.saveCategories(mergedCategories);
      }
      // -----------------------------------------------------------------------
      // REPLACE / RESTORE
      // -----------------------------------------------------------------------
      else {
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

  // ---------------------------------------------------------------------------
  // IMPORT JSON FILE
  // ---------------------------------------------------------------------------

  Future<bool> importFromFile({bool merge = false}) async {
    try {
      String? jsonString;

      // -----------------------------------------------------------------------
      // ANDROID
      // -----------------------------------------------------------------------

      if (Platform.isAndroid) {
        jsonString = await _fileChannel.invokeMethod<String>('pickJsonFile');
      }
      // -----------------------------------------------------------------------
      // WINDOWS
      //
      // Without file_picker, we look for JSON files in Downloads.
      // -----------------------------------------------------------------------
      else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];

        if (userProfile != null) {
          final downloadsDir = Directory('$userProfile\\Downloads');

          if (await downloadsDir.exists()) {
            final jsonFiles = downloadsDir
                .listSync()
                .whereType<File>()
                .where((file) => file.path.toLowerCase().endsWith('.json'))
                .toList();

            if (jsonFiles.isNotEmpty) {
              // Sort newest first.
              jsonFiles.sort(
                (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
              );

              jsonString = await jsonFiles.first.readAsString();
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // NO FILE SELECTED
      // -----------------------------------------------------------------------

      if (jsonString == null || jsonString.isEmpty) {
        return false;
      }

      // -----------------------------------------------------------------------
      // RESTORE
      // -----------------------------------------------------------------------

      return await restoreFromRawJson(jsonString, merge: merge);
    } catch (_) {
      return false;
    }
  }
}
