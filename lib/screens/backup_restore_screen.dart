import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  final VoidCallback onDataRestored;

  const BackupRestoreScreen({
    super.key,
    required this.onDataRestored,
  });

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;

  Future<void> _saveToLocalStorage() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isProcessing = true;
    });

    final savedPath = await _backupService.saveBackupToLocalFile();

    setState(() {
      _isProcessing = false;
    });

    if (savedPath != null && savedPath.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('Saved to: $savedPath'),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to save file to local storage.'),
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
    });

    await _backupService.exportBackup();

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _copyJsonToClipboard() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isProcessing = true;
    });

    final jsonString = await _backupService.createBackupJson();
    await Clipboard.setData(ClipboardData(text: jsonString));

    setState(() {
      _isProcessing = false;
    });

    messenger.showSnackBar(
      const SnackBar(content: Text('Backup JSON copied to clipboard!')),
    );
  }

  Future<void> _importFromFile({required bool merge}) async {
    if (!merge) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace All App Data?'),
          content: const Text(
            'Warning: Restoring backup data in Replace mode will overwrite and replace all your current groups, sub-groups, purchases, and custom categories.\n\nIt is strongly recommended to save a backup of your current data before proceeding.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Replace All Data'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isProcessing = true;
    });

    final success = await _backupService.importFromFile(merge: merge);

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      widget.onDataRestored();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            merge
                ? 'Data merged successfully!'
                : 'Data restored successfully!',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to import backup file or cancelled.'),
        ),
      );
    }
  }

  void _showPasteJsonDialog() {
    final controller = TextEditingController();
    bool merge = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Paste Backup JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Paste backup JSON string here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Merge with current data'),
                    subtitle: const Text('Check to keep existing purchases'),
                    value: merge,
                    onChanged: (val) {
                      setDialogState(() {
                        merge = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  if (!merge) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Replace All App Data?'),
                        content: const Text(
                          'Warning: Restoring backup data in Replace mode will overwrite and replace all your current groups, sub-groups, purchases, and custom categories.\n\nIt is strongly recommended to save a backup of your current data before proceeding.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Replace All Data'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  nav.pop();
                  setState(() {
                    _isProcessing = true;
                  });
                  final success = await _backupService.restoreFromRawJson(
                    text,
                    merge: merge,
                  );
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    if (success) {
                      widget.onDataRestored();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Data restored successfully!'),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Invalid JSON format.'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Export Section Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.file_upload_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Export Data',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Export all your purchases, groups, and categories as a JSON backup file to local storage, share sheet, or clipboard.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saveToLocalStorage,
                            icon: const Icon(Icons.download_for_offline_outlined),
                            label: const Text('Save to Local Device Storage'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exportBackup,
                                icon: const Icon(Icons.share),
                                label: const Text('Share File'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              onPressed: _copyJsonToClipboard,
                              tooltip: 'Copy JSON Text',
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Import Section Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              child: Icon(
                                Icons.file_download_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Import & Restore Data',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select a previously saved JSON file from local storage to restore your purchases, groups, and categories anytime.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _importFromFile(merge: false),
                            icon: const Icon(Icons.restore),
                            label: const Text('Import File (Replace Data)'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _importFromFile(merge: true),
                            icon: const Icon(Icons.merge_type),
                            label: const Text('Import File (Merge Data)'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _showPasteJsonDialog,
                            icon: const Icon(Icons.paste, size: 18),
                            label: const Text('Paste JSON Text Directly'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
