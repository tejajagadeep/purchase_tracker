import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/categories.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../models/sub_group.dart';
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
    final groups = await _repository.getGroups(includeTemplates: true);
    final subGroups = await _repository.getSubGroups();
    final items = await _repository.getItems();
    final categories = await CategoryManager.loadCategories();

    final Map<String, dynamic> backupData = {
      'app': 'Purchase Tracker',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groups.map((g) => g.toMap()).toList(),
      'subGroups': subGroups.map((sg) => sg.toMap()).toList(),
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
          'Purchase_Tracker_Backup_${DateTime.now().millisecondsSinceEpoch}.json';

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
    } catch (_) {
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
          'Purchase_Tracker_Backup_${DateTime.now().millisecondsSinceEpoch}.json';

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
        } catch (_) {}
      }

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

      List<PurchaseGroup> newGroups = [];
      List<SubGroup> newSubGroups = [];
      List<PurchaseItem> newItems = [];
      List<String> newCategories = [];

      if (decoded is Map<String, dynamic>) {
        if (decoded['groups'] != null && decoded['groups'] is List) {
          for (final g in decoded['groups']) {
            if (g is Map) newGroups.add(PurchaseGroup.fromMap(Map<String, dynamic>.from(g)));
          }
        }

        if (decoded['subGroups'] != null && decoded['subGroups'] is List) {
          for (final sg in decoded['subGroups']) {
            if (sg is Map) newSubGroups.add(SubGroup.fromMap(Map<String, dynamic>.from(sg)));
          }
        }

        if (decoded['items'] != null && decoded['items'] is List) {
          for (final i in decoded['items']) {
            if (i is Map) newItems.add(PurchaseItem.fromMap(Map<String, dynamic>.from(i)));
          }
        }

        if (decoded['categories'] != null && decoded['categories'] is List) {
          for (final c in decoded['categories']) {
            newCategories.add(c.toString());
          }
        }
      } else if (decoded is List) {
        for (final i in decoded) {
          if (i is Map) newItems.add(PurchaseItem.fromMap(Map<String, dynamic>.from(i)));
        }
      }

      if (newGroups.isEmpty && newSubGroups.isEmpty && newItems.isEmpty && newCategories.isEmpty) {
        return false;
      }

      if (merge) {
        final existingGroups = await _repository.getGroups(includeTemplates: true);
        final existingSubGroups = await _repository.getSubGroups();
        final existingItems = await _repository.getItems();
        final existingCategories = await CategoryManager.loadCategories();

        final mergedGroupsMap = {for (final g in existingGroups) g.id: g};
        for (final g in newGroups) {
          mergedGroupsMap[g.id] = g;
        }

        final mergedSubGroupsMap = {for (final sg in existingSubGroups) sg.id: sg};
        for (final sg in newSubGroups) {
          mergedSubGroupsMap[sg.id] = sg;
        }

        final mergedItemsMap = {for (final i in existingItems) i.id: i};
        for (final i in newItems) {
          mergedItemsMap[i.id] = i;
        }

        final mergedCategories = {...existingCategories, ...newCategories}.toList();

        await _repository.saveGroups(mergedGroupsMap.values.toList());
        await _repository.saveSubGroups(mergedSubGroupsMap.values.toList());
        await _repository.saveItems(mergedItemsMap.values.toList());
        await CategoryManager.saveCategories(mergedCategories);
      } else {
        if (newGroups.isNotEmpty) {
          await _repository.saveGroups(newGroups);
        }
        if (newSubGroups.isNotEmpty) {
          await _repository.saveSubGroups(newSubGroups);
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

      if (Platform.isAndroid) {
        try {
          jsonString = await _fileChannel.invokeMethod<String>('pickJsonFile');
        } catch (_) {}
      } else if (Platform.isWindows) {
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
              jsonFiles.sort(
                (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
              );
              jsonString = await jsonFiles.first.readAsString();
            }
          }
        }
      }

      if (jsonString == null || jsonString.isEmpty) {
        return false;
      }

      return await restoreFromRawJson(jsonString, merge: merge);
    } catch (_) {
      return false;
    }
  }
}
