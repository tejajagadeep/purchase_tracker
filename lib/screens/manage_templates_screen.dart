import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../repositories/purchase_repository.dart';
import '../utils/formatters.dart';

class ManageTemplatesScreen extends StatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  State<ManageTemplatesScreen> createState() => _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState extends State<ManageTemplatesScreen> {
  final IPurchaseRepository _repository = PurchaseRepository();

  List<PurchaseGroup> _templateGroups = [];
  PurchaseGroup? _selectedTemplate;
  List<PurchaseItem> _templateItems = [];
  List<String> _categories = List<String>.from(CategoryConstants.defaultCategories);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final loadedCategories = await CategoryManager.loadCategories();
    final groups = await _repository.getTemplateGroups();
    final activeTemplate = groups.firstWhere(
      (g) => g.id == (_selectedTemplate?.id ?? groups.first.id),
      orElse: () => groups.first,
    );
    final items = await _repository.getTemplateItems(templateGroupId: activeTemplate.id);

    setState(() {
      _categories = loadedCategories;
      _templateGroups = groups;
      _selectedTemplate = activeTemplate;
      _templateItems = items;
      _isLoading = false;
    });
  }

  Future<void> _selectTemplate(PurchaseGroup group) async {
    setState(() {
      _isLoading = true;
    });
    final items = await _repository.getTemplateItems(templateGroupId: group.id);
    setState(() {
      _selectedTemplate = group;
      _templateItems = items;
      _isLoading = false;
    });
  }

  Future<void> _saveTemplateItems() async {
    if (_selectedTemplate == null) return;
    await _repository.saveItemsForGroup(_selectedTemplate!.id, _templateItems);
  }

  void _showAddOrEditTemplateItemDialog({PurchaseItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final qtyController = TextEditingController(
      text: (existingItem?.quantity ?? 1).toString(),
    );
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.plannedPrice.toStringAsFixed(0) : '',
    );
    final notesController = TextEditingController(text: existingItem?.notes ?? '');

    String category = (existingItem != null && _categories.contains(existingItem.category))
        ? existingItem.category
        : _categories.first;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingItem == null ? 'Add Template Item' : 'Edit Template Item'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Gym Fee, Dosa, Fuel',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          if (n == null || n < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Planned Price (₹) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final p = double.tryParse(value ?? '');
                          if (p == null || p < 0) return 'Invalid price';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
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
              if (formKey.currentState!.validate() && _selectedTemplate != null) {
                final qty = int.parse(qtyController.text.trim());
                final price = double.parse(priceController.text.trim());
                final notesText = notesController.text.trim();

                final newItem = PurchaseItem(
                  id: existingItem?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                  groupId: _selectedTemplate!.id,
                  name: nameController.text.trim(),
                  quantity: qty,
                  plannedPrice: price,
                  category: category,
                  notes: notesText.isEmpty ? null : notesText,
                );

                setState(() {
                  if (existingItem == null) {
                    _templateItems.add(newItem);
                  } else {
                    final idx = _templateItems.indexWhere((i) => i.id == existingItem.id);
                    if (idx != -1) _templateItems[idx] = newItem;
                  }
                });

                _saveTemplateItems();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplateItem(PurchaseItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _templateItems.removeWhere((i) => i.id == item.id);
    });
    await _saveTemplateItems();
    messenger.showSnackBar(
      SnackBar(content: Text('Removed "${item.name}" from template.')),
    );
  }

  void _showAddTemplateGroupDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Template Preset'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Template Name *',
              hintText: 'e.g. Camping Trip Template',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter template name';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newGroup = PurchaseGroup(
                  id: 'template_${DateTime.now().millisecondsSinceEpoch}',
                  name: controller.text.trim(),
                  description: 'Custom master template',
                  isTemplate: true,
                );

                setState(() {
                  _templateGroups.add(newGroup);
                });

                _repository.getGroups(includeTemplates: true).then((allGroups) {
                  allGroups.add(newGroup);
                  _repository.saveGroups(allGroups);
                });

                Navigator.pop(context);
                _selectTemplate(newGroup);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Master Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'New Template Preset',
            onPressed: _showAddTemplateGroupDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Template Group Selector Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTemplate?.id,
                    decoration: const InputDecoration(
                      labelText: 'Select Master Template Preset',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.copy_outlined),
                    ),
                    items: _templateGroups.map((tg) {
                      return DropdownMenuItem(
                        value: tg.id,
                        child: Text(tg.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final selected = _templateGroups.firstWhere((g) => g.id == val);
                        _selectTemplate(selected);
                      }
                    },
                  ),
                ),

                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Template Items (${_templateItems.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddOrEditTemplateItemDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Items List
                Expanded(
                  child: _templateItems.isEmpty
                      ? Center(
                          child: Text(
                            'No items in this template.\nTap + Add Item to add master items.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _templateItems.length,
                          itemBuilder: (context, index) {
                            final item = _templateItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    CategoryConstants.getIcon(item.category),
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Qty: ${item.quantity} • ${formatCurrency(item.plannedPrice)} • ${item.category}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Edit Item',
                                      onPressed: () =>
                                          _showAddOrEditTemplateItemDialog(existingItem: item),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: theme.colorScheme.error,
                                      ),
                                      tooltip: 'Delete Item',
                                      onPressed: () => _deleteTemplateItem(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTemplateItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Template Item'),
      ),
    );
  }
}
