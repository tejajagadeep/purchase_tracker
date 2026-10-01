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

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
    });

    final success = await _backupService.exportBackup();

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully!')),
        );
      }
    }
  }

  Future<void> _copyJsonToClipboard() async {
    setState(() {
      _isProcessing = true;
    });

    final jsonString = await _backupService.createBackupJson();
    await Clipboard.setData(ClipboardData(text: jsonString));

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup JSON copied to clipboard!')),
      );
    }
  }

  Future<void> _importFromFile({required bool merge}) async {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 8,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  setState(() {
                    _isProcessing = true;
                  });
                  final success = await _backupService.restoreFromRawJson(
                    text,
                    merge: merge,
                  );
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
                          'Export all your purchases, groups, and categories as a JSON backup file. You can save it to Drive, files, or share it.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _exportBackup,
                                icon: const Icon(Icons.share),
                                label: const Text('Export JSON File'),
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
                          'Select a previously exported JSON file to restore your purchases, groups, and categories anytime.',
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
