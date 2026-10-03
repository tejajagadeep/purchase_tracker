import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/categories.dart';
import '../data/sample_data.dart';
import '../models/purchase_item.dart';
import '../models/purchase_group.dart';
import '../models/sub_group.dart';
import '../repositories/purchase_repository.dart';
import '../widgets/purchase_form_bottom_sheet.dart';
import '../widgets/purchase_item_tile.dart';
import '../widgets/sub_group_card.dart';
import '../widgets/summary_card.dart';
import 'backup_restore_screen.dart';
import 'calendar_expense_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_templates_screen.dart';
import '../utils/formatters.dart';

enum SortOption {
  name,
  price,
  status,
  category,
}

enum StatusFilter {
  all,
  purchased,
  pending,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IPurchaseRepository _repository = PurchaseRepository();

  List<PurchaseItem> _items = [];
  List<PurchaseGroup> _groups = [];
  PurchaseGroup? _activeGroup;
  List<SubGroup> _subGroups = [];
  SubGroup? _activeSubGroup;

  List<String> _categories = List<String>.from(CategoryConstants.defaultCategories);
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategory = CategoryConstants.all;
  StatusFilter _statusFilter = StatusFilter.all;
  SortOption _sortOption = SortOption.name;
  bool _isSortAscending = true;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final _priceInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,12}(\.\d{0,2})?'),
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await CurrencyManager.loadCurrencySymbol();
      final loadedCategories = await CategoryManager.loadCategories();
      final loadedGroups = await _repository.getGroups();
      final activeGroup = loadedGroups.firstWhere(
        (g) => g.id == (_activeGroup?.id ?? loadedGroups.first.id),
        orElse: () => loadedGroups.first,
      );

      final loadedSubGroups = await _repository.getSubGroups(groupId: activeGroup.id);
      final loadedItems = await _repository.getItems(groupId: activeGroup.id);

      setState(() {
        _categories = loadedCategories;
        _groups = loadedGroups;
        _activeGroup = activeGroup;
        _subGroups = loadedSubGroups;
        _sortSubGroups();
        _activeSubGroup = null;
        _items = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _items = getInitialSampleData();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectGroup(PurchaseGroup group) async {
    setState(() {
      _isLoading = true;
    });
    final subGroups = await _repository.getSubGroups(groupId: group.id);
    final items = await _repository.getItems(groupId: group.id);
    setState(() {
      _activeGroup = group;
      _subGroups = subGroups;
      _sortSubGroups();
      _activeSubGroup = null;
      _items = items;
      _isLoading = false;
    });
  }

  void _sortSubGroups() {
    _subGroups.sort((a, b) {
      if (a.isPinned == b.isPinned) {
        return a.createdAt.compareTo(b.createdAt);
      }
      return a.isPinned ? -1 : 1;
    });
  }

  void _togglePinSubGroup(SubGroup subGroup) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedSubGroup = subGroup.copyWith(isPinned: !subGroup.isPinned);

    final idx = _subGroups.indexWhere((sg) => sg.id == subGroup.id);
    if (idx != -1) {
      setState(() {
        _subGroups[idx] = updatedSubGroup;
        if (_activeSubGroup?.id == subGroup.id) {
          _activeSubGroup = updatedSubGroup;
        }
        _sortSubGroups();
      });

      final allSubs = await _repository.getSubGroups();
      final allIdx = allSubs.indexWhere((sg) => sg.id == subGroup.id);
      if (allIdx != -1) {
        allSubs[allIdx] = updatedSubGroup;
        await _repository.saveSubGroups(allSubs);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            updatedSubGroup.isPinned
                ? 'Pinned "${subGroup.name}" to top!'
                : 'Unpinned "${subGroup.name}"',
          ),
        ),
      );
    }
  }

  void _confirmDeleteSubGroup(SubGroup subGroup) async {
    final messenger = ScaffoldMessenger.of(context);
    final subGroupItems = _items.where((i) => i.subGroupId == subGroup.id).toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Sub-Group "${subGroup.name}"?'),
        content: Text(
          subGroupItems.isEmpty
              ? 'Are you sure you want to delete this sub-group?'
              : 'Are you sure you want to delete "${subGroup.name}" and all ${subGroupItems.length} purchase items inside it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _subGroups.removeWhere((sg) => sg.id == subGroup.id);
        if (_activeSubGroup?.id == subGroup.id) {
          _activeSubGroup = null;
        }
        // Remove all items belonging to this deleted sub-group
        _items.removeWhere((i) => i.subGroupId == subGroup.id);
      });

      final allSubs = await _repository.getSubGroups();
      allSubs.removeWhere((sg) => sg.id == subGroup.id);
      await _repository.saveSubGroups(allSubs);

      if (_activeGroup != null) {
        await _repository.saveItemsForGroup(_activeGroup!.id, _items);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted Sub-Group "${subGroup.name}" and its items.'),
        ),
      );
    }
  }

  void _togglePinGroup(PurchaseGroup group) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedGroup = group.copyWith(isPinned: !group.isPinned);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = updatedGroup;
      _groups.sort((a, b) {
        if (a.isPinned == b.isPinned) {
          return a.createdAt.compareTo(b.createdAt);
        }
        return a.isPinned ? -1 : 1;
      });
      setState(() {});
      await _repository.saveGroups(_groups);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            updatedGroup.isPinned
                ? 'Pinned "${group.name}" to top!'
                : 'Unpinned "${group.name}"',
          ),
        ),
      );
    }
  }

  void _openGroupSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Purchase Group',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Group',
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddGroupDialog();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final isSelected = group.id == _activeGroup?.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            isSelected ? Icons.check : Icons.folder_outlined,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Row(
                          children: [
                            if (group.isPinned) ...[
                              const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                group.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          group.description != null && group.description!.isNotEmpty
                              ? '${group.description!} • ${group.targetBudget != null ? 'Budget: ${formatCurrency(group.targetBudget!)}' : 'No target budget set'}'
                              : (group.targetBudget != null
                                  ? 'Budget: ${formatCurrency(group.targetBudget!)}'
                                  : 'No target budget set'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.blue, size: 20),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (action) {
                                if (action == 'pin') {
                                  Navigator.pop(context);
                                  _togglePinGroup(group);
                                } else if (action == 'edit') {
                                  Navigator.pop(context);
                                  _showEditGroupDialog(group);
                                } else if (action == 'move') {
                                  Navigator.pop(context);
                                  _showMoveGroupDialog(group);
                                } else if (action == 'delete') {
                                  Navigator.pop(context);
                                  _confirmDeleteGroup(group);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'pin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        group.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(group.isPinned ? 'Unpin Group' : 'Pin Group to Top'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Group'),
                                    ],
                                  ),
                                ),
                                if (_groups.length > 1)
                                  const PopupMenuItem(
                                    value: 'move',
                                    child: Row(
                                      children: [
                                        Icon(Icons.drive_file_move_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Move Group To...'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Group', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _selectGroup(group);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Purchase Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'e.g. Car Touring, Monthly Expenses',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Group Description (Optional)',
                  hintText: 'e.g. Trip to Leh & Ladakh',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_priceInputFormatter],
                decoration: InputDecoration(
                  labelText: 'Target Group Budget (${CurrencyManager.currentSymbol}) (Optional)',
                  hintText: 'e.g. 250000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
            ],
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
                final budgetText = budgetController.text.trim();
                final double? budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;
                final descText = descriptionController.text.trim();

                final newGroup = PurchaseGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descText.isNotEmpty ? descText : null,
                  targetBudget: budget,
                );
                setState(() {
                  _groups.add(newGroup);
                });
                _repository.saveGroups(_groups);
                Navigator.pop(context);
                _selectGroup(newGroup);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(PurchaseGroup group) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(text: group.description ?? '');
    final budgetController = TextEditingController(
      text: group.targetBudget != null ? formatPriceForInput(group.targetBudget!) : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Purchase Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Group Description (Optional)',
                  hintText: 'e.g. Trip to Leh & Ladakh',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_priceInputFormatter],
                decoration: InputDecoration(
                  labelText: 'Target Group Budget (${CurrencyManager.currentSymbol}) (Optional)',
                  hintText: 'e.g. 250000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
            ],
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
                final newName = nameController.text.trim();
                final budgetText = budgetController.text.trim();
                final double? budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;
                final descText = descriptionController.text.trim();

                final updatedGroup = group.copyWith(
                  name: newName,
                  description: descText.isNotEmpty ? descText : null,
                  targetBudget: budget,
                );
                final index = _groups.indexWhere((g) => g.id == group.id);
                if (index != -1) {
                  setState(() {
                    _groups[index] = updatedGroup;
                    if (_activeGroup?.id == group.id) {
                      _activeGroup = updatedGroup;
                    }
                  });
                  _repository.saveGroups(_groups);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupBudgetDialog() {
    if (_activeGroup == null) return;
    _showEditGroupDialog(_activeGroup!);
  }

  void _showAddSubGroupDialog() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Month / Sub-Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Sub-Group / Month Name *',
                  hintText: 'e.g. October 2026, November 2026',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_priceInputFormatter],
                decoration: InputDecoration(
                  labelText: 'Target Sub-Group Budget (${CurrencyManager.currentSymbol}) (Optional)',
                  hintText: 'e.g. 50000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate() && _activeGroup != null) {
                final budgetText = budgetController.text.trim();
                final double? budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

                final newSubGroup = SubGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupId: _activeGroup!.id,
                  name: nameController.text.trim(),
                  targetBudget: budget,
                );
                setState(() {
                  _subGroups.add(newSubGroup);
                  _sortSubGroups();
                  _activeSubGroup = newSubGroup;
                });
                _repository.getSubGroups().then((allSubGroups) {
                  allSubGroups.add(newSubGroup);
                  _repository.saveSubGroups(allSubGroups);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditSubGroupDialog(SubGroup subGroup) {
    final nameController = TextEditingController(text: subGroup.name);
    final budgetController = TextEditingController(
      text: subGroup.targetBudget != null ? formatPriceForInput(subGroup.targetBudget!) : '',
    );
    bool isPinned = subGroup.isPinned;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit "${subGroup.name}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Sub-Group Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Sub-Group Budget (₹) (Optional)',
                    hintText: 'e.g. 50000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Pin Sub-Group to Top'),
                  subtitle: const Text('Keep this sub-group at the top of the list'),
                  value: isPinned,
                  secondary: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? Colors.orange : null,
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      isPinned = val;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final budgetText = budgetController.text.trim();
                  final double? budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

                  final updatedSubGroup = subGroup.copyWith(
                    name: nameController.text.trim(),
                    targetBudget: budget,
                    isPinned: isPinned,
                  );

                  final idx = _subGroups.indexWhere((sg) => sg.id == subGroup.id);
                  if (idx != -1) {
                    setState(() {
                      _subGroups[idx] = updatedSubGroup;
                      if (_activeSubGroup?.id == subGroup.id) {
                        _activeSubGroup = updatedSubGroup;
                      }
                      _sortSubGroups();
                    });
                    _repository.getSubGroups().then((allSubs) {
                      final allIdx = allSubs.indexWhere((sg) => sg.id == subGroup.id);
                      if (allIdx != -1) {
                        allSubs[allIdx] = updatedSubGroup;
                        _repository.saveSubGroups(allSubs);
                      }
                    });
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySettingsDialog() {
    String current = CurrencyManager.currentSymbol;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.currency_exchange, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select Currency Symbol',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: CurrencyManager.supportedCurrencies.map((c) {
                final symbol = c['symbol']!;
                final name = c['name']!;
                final isSelected = current == symbol;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  onTap: () {
                    setDialogState(() {
                      current = symbol;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await CurrencyManager.saveCurrencySymbol(current);
                if (context.mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency symbol updated to "${CurrencyManager.currentSymbol}"'),
                    ),
                  );
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyFromTemplateDialog({String? preSelectedSubGroupId}) async {
    await CurrencyManager.loadCurrencySymbol();
    final templateGroups = await _repository.getTemplateGroups();
    if (templateGroups.isEmpty) return;

    String selectedTemplateId = templateGroups.first.id;
    String? targetSubGroupId = preSelectedSubGroupId ?? _activeSubGroup?.id;

    List<PurchaseItem> templateItems = await _repository.getTemplateItems(
      templateGroupId: selectedTemplateId,
    );
    Set<String> selectedItemIds = templateItems.map((i) => i.id).toSet();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Copy from Template',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: 'Manage Templates',
                onPressed: () {
                  Navigator.pop(context);
                  _openManageTemplates();
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select template preset to copy items into "${_activeGroup?.name}":',
                ),
                const SizedBox(height: 12),

                // Template Group Selector Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Template Preset',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.copy),
                  ),
                  items: templateGroups.map((tg) {
                    return DropdownMenuItem(
                      value: tg.id,
                      child: Text(tg.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      selectedTemplateId = val;
                      final newItems = await _repository.getTemplateItems(
                        templateGroupId: selectedTemplateId,
                      );
                      setDialogState(() {
                        templateItems = newItems;
                        selectedItemIds = newItems.map((i) => i.id).toSet();
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Target Sub-Group Dropdown Selector
                if (_subGroups.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: targetSubGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Target Month / Sub-Group',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_special_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Main Group (All Months/Items)', overflow: TextOverflow.ellipsis),
                      ),
                      ..._subGroups.map((sg) {
                        return DropdownMenuItem<String?>(
                          value: sg.id,
                          child: Text(sg.name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        targetSubGroupId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Items (${selectedItemIds.length}/${templateItems.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          if (selectedItemIds.length == templateItems.length) {
                            selectedItemIds.clear();
                          } else {
                            selectedItemIds = templateItems.map((i) => i.id).toSet();
                          }
                        });
                      },
                      child: Text(
                        selectedItemIds.length == templateItems.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: templateItems.length,
                    itemBuilder: (context, index) {
                      final item = templateItems[index];
                      final isSelected = selectedItemIds.contains(item.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty: ${item.quantity} • ${formatCurrency(item.plannedPrice)} • ${item.category}',
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedItemIds.add(item.id);
                            } else {
                              selectedItemIds.remove(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: selectedItemIds.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _copyTemplateItemsToActiveGroup(
                        templateItems
                            .where((i) => selectedItemIds.contains(i.id))
                            .toList(),
                        targetSubGroupId,
                      );
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Selected Sub-Group'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTemplateItemsToActiveGroup(
    List<PurchaseItem> itemsToCopy,
    String? targetSubGroupId,
  ) async {
    if (_activeGroup == null || itemsToCopy.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final List<String> newlyAddedIds = [];

    final copiedItems = itemsToCopy.map((item) {
      final newId = '${DateTime.now().microsecondsSinceEpoch}_${newlyAddedIds.length}';
      newlyAddedIds.add(newId);
      return item.copyWith(
        id: newId,
        groupId: _activeGroup!.id,
        subGroupId: targetSubGroupId,
        purchaseDates: [], // Reset to pending for fresh list
      );
    }).toList();

    setState(() {
      _items.addAll(copiedItems);
    });
    await _saveItems();

    String destName = _activeGroup!.name;
    if (targetSubGroupId != null) {
      final match = _subGroups.where((sg) => sg.id == targetSubGroupId);
      if (match.isNotEmpty) {
        destName = match.first.name;
      }
    }

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('Copied ${copiedItems.length} template items into "$destName"!'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            setState(() {
              _items.removeWhere((item) => newlyAddedIds.contains(item.id));
            });
            await _saveItems();
            messenger.showSnackBar(
              const SnackBar(content: Text('Reverted template copy!')),
            );
          },
        ),
      ),
    );
  }

  void _showMoveGroupDialog(PurchaseGroup sourceGroup) {
    final otherGroups = _groups.where((g) => g.id != sourceGroup.id).toList();
    if (otherGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other groups available to move into.')),
      );
      return;
    }

    String selectedParentGroupId = otherGroups.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${sourceGroup.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Convert "${sourceGroup.name}" into a Sub-Group under:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedParentGroupId,
              decoration: const InputDecoration(
                labelText: 'Target Parent Group',
                border: OutlineInputBorder(),
              ),
              items: otherGroups.map((g) {
                return DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  selectedParentGroupId = val;
                }
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
              Navigator.pop(context);
              await _moveGroupToParent(sourceGroup, selectedParentGroupId);
            },
            child: const Text('Move Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveGroupToParent(PurchaseGroup sourceGroup, String targetGroupId) async {
    final targetGroup = _groups.firstWhere((g) => g.id == targetGroupId);
    final messenger = ScaffoldMessenger.of(context);

    // 1. Create a new SubGroup under targetGroup
    final newSubGroup = SubGroup(
      id: sourceGroup.id,
      groupId: targetGroupId,
      name: sourceGroup.name,
      targetBudget: sourceGroup.targetBudget,
    );

    final allSubGroups = await _repository.getSubGroups();
    allSubGroups.add(newSubGroup);
    await _repository.saveSubGroups(allSubGroups);

    // 2. Update all purchase items in sourceGroup to targetGroupId & newSubGroup.id
    final sourceItems = await _repository.getItems(groupId: sourceGroup.id);
    final updatedSourceItems = sourceItems.map((item) {
      return item.copyWith(
        groupId: targetGroupId,
        subGroupId: newSubGroup.id,
      );
    }).toList();

    final targetItems = await _repository.getItems(groupId: targetGroupId);
    targetItems.addAll(updatedSourceItems);
    await _repository.saveItemsForGroup(targetGroupId, targetItems);

    // 3. Delete sourceGroup
    await _repository.deleteGroup(sourceGroup.id);

    // 4. Reload UI data and select targetGroup
    final updatedGroups = await _repository.getGroups();
    setState(() {
      _groups = updatedGroups;
    });
    await _selectGroup(targetGroup);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Moved "${sourceGroup.name}" into "${targetGroup.name}" as a Sub-Group!',
        ),
      ),
    );
  }

  void _confirmDeleteGroup(PurchaseGroup group) {
    if (_groups.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one group must remain.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${group.name}"?'),
        content: const Text(
          'This will permanently delete this group and all purchase items inside it. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.deleteGroup(group.id);
              final updatedGroups = await _repository.getGroups();
              setState(() {
                _groups = updatedGroups;
              });
              final nextGroup = _groups.first;
              await _selectGroup(nextGroup);
              messenger.showSnackBar(
                SnackBar(content: Text('Group "${group.name}" deleted.')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveItems() async {
    if (_activeGroup != null) {
      await _repository.saveItemsForGroup(_activeGroup!.id, _items);
    }
  }

  void _openManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageCategoriesScreen(
          currentCategories: _categories,
          onCategoriesUpdated: (updatedCategories, oldName, newName) {
            setState(() {
              _categories = updatedCategories;

              if (oldName != null && newName != null) {
                _items = _items.map((item) {
                  if (item.category == oldName) {
                    return item.copyWith(category: newName);
                  }
                  return item;
                }).toList();
              }

              if (_selectedCategory != CategoryConstants.all &&
                  !_categories.contains(_selectedCategory)) {
                _selectedCategory = CategoryConstants.all;
              }
            });
            _saveItems();
          },
        ),
      ),
    );
  }

  void _openManageTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageTemplatesScreen(),
      ),
    );
  }

  void _openBackupRestore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupRestoreScreen(
          onDataRestored: () {
            _loadData();
          },
        ),
      ),
    );
  }

  void _openCalendarView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarExpenseScreen(),
      ),
    );
  }

  // Calculations
  List<PurchaseItem> get _effectiveGroupItems {
    if (_activeSubGroup == null) return _items;
    return _items.where((i) => i.subGroupId == _activeSubGroup!.id).toList();
  }

  double get itemsPlannedTotal {
    return _effectiveGroupItems.fold(0.0, (sum, item) => sum + item.plannedTotal);
  }

  double get effectiveGroupBudget {
    if (_activeSubGroup != null) {
      if (_activeSubGroup!.targetBudget != null && _activeSubGroup!.targetBudget! > 0) {
        return _activeSubGroup!.targetBudget!;
      }
      return itemsPlannedTotal;
    }
    // Main Group View
    if (_activeGroup?.targetBudget != null && _activeGroup!.targetBudget! > 0) {
      return _activeGroup!.targetBudget!;
    }
    if (_subGroups.isNotEmpty) {
      double totalBudget = 0.0;
      // 1. Sum sub-groups target budgets (or sub-groups planned items)
      for (final sg in _subGroups) {
        final sgItems = _items.where((i) => i.subGroupId == sg.id).toList();
        final sgPlanned = sgItems.fold(0.0, (sum, i) => sum + i.plannedTotal);
        if (sg.targetBudget != null && sg.targetBudget! > 0) {
          totalBudget += sg.targetBudget!;
        } else {
          totalBudget += sgPlanned;
        }
      }
      // 2. Add unassigned main group items planned total
      final unassignedItems = _items.where((i) => i.subGroupId == null).toList();
      final unassignedPlanned = unassignedItems.fold(0.0, (sum, i) => sum + i.plannedTotal);
      totalBudget += unassignedPlanned;

      return totalBudget;
    }
    return itemsPlannedTotal;
  }

  double get totalActualSpent {
    return _effectiveGroupItems.where((item) => item.isPurchased).fold(
          0.0,
          (sum, item) => sum + item.actualTotal,
        );
  }

  double get totalPurchasedPlanned {
    return _effectiveGroupItems.where((item) => item.isPurchased).fold(
          0.0,
          (sum, item) => sum + item.plannedTotal,
        );
  }

  double get totalSaved {
    double saved = 0.0;
    for (final item in _effectiveGroupItems) {
      if (item.isPurchased) {
        saved += (item.plannedTotal - item.actualTotal);
      }
    }
    return saved;
  }

  double get remainingBudget {
    return effectiveGroupBudget - totalActualSpent;
  }

  int get purchasedCount {
    return _effectiveGroupItems.where((item) => item.isPurchased).length;
  }

  List<PurchaseItem> get _filteredAndSortedItems {
    return _effectiveGroupItems.where((item) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesCategory = item.category.toLowerCase().contains(query);
        final matchesNotes =
            item.notes != null && item.notes!.toLowerCase().contains(query);
        if (!matchesName && !matchesCategory && !matchesNotes) {
          return false;
        }
      }

      if (_selectedCategory != CategoryConstants.all &&
          item.category != _selectedCategory) {
        return false;
      }

      if (_statusFilter == StatusFilter.purchased && !item.isPurchased) {
        return false;
      }
      if (_statusFilter == StatusFilter.pending && item.isPurchased) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        int comp = 0;
        switch (_sortOption) {
          case SortOption.name:
            comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case SortOption.price:
            comp = a.plannedTotal.compareTo(b.plannedTotal);
            break;
          case SortOption.status:
            if (a.isPurchased == b.isPurchased) {
              comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            } else {
              comp = a.isPurchased ? 1 : -1;
            }
            break;
          case SortOption.category:
            comp = a.category.toLowerCase().compareTo(b.category.toLowerCase());
            break;
        }
        return _isSortAscending ? comp : -comp;
      });
  }

  void _togglePurchased(PurchaseItem item) async {
    final updatedIndex = _items.indexWhere((element) => element.id == item.id);
    if (updatedIndex == -1) return;

    final isNowPurchased = !item.isPurchased;

    if (!isNowPurchased) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unselect "${item.name}"?'),
          content: const Text(
            'Are you sure you want to unselect this purchase item?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Unselect'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    // Preserve purchase dates across selecting and unselecting
    List<DateTime> newDates = item.purchaseDates;
    if (isNowPurchased && newDates.isEmpty) {
      newDates = List.generate(item.quantity, (_) => DateTime.now());
    }

    final updatedItem = item.copyWith(
      purchaseDates: newDates,
      isCompleted: isNowPurchased,
    );
    setState(() {
      _items[updatedIndex] = updatedItem;
    });
    _saveItems();
  }

  void _addUnitBoughtToday(PurchaseItem item) {
    if (item.isPurchased) return;
    final updatedIndex = _items.indexWhere((element) => element.id == item.id);
    if (updatedIndex != -1) {
      final messenger = ScaffoldMessenger.of(context);
      final newDates = List<DateTime>.from(item.purchaseDates)..add(DateTime.now());
      final updatedItem = item.copyWith(
        purchaseDates: newDates,
      );
      setState(() {
        _items[updatedIndex] = updatedItem;
      });
      _saveItems();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Recorded 1 unit of "${item.name}" bought today!'),
        ),
      );
    }
  }

  void _addOrEditItem({PurchaseItem? existingItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return PurchaseFormBottomSheet(
          existingItem: existingItem,
          categories: _categories,
          groups: _groups,
          allSubGroups: _subGroups,
          groupId: _activeGroup?.id ?? 'bike_touring',
          subGroupId: _activeSubGroup?.id,
          onSave: (newItem) async {
            final itemWithSubGroup = newItem.copyWith(
              subGroupId: newItem.groupId == _activeGroup?.id
                  ? (newItem.subGroupId ?? _activeSubGroup?.id)
                  : newItem.subGroupId,
            );

            if (_activeGroup != null && itemWithSubGroup.groupId != _activeGroup!.id) {
              // Item was moved to another group!
              final messenger = ScaffoldMessenger.of(context);
              setState(() {
                _items.removeWhere((item) => item.id == itemWithSubGroup.id);
              });
              await _saveItems();

              // Save item to target group
              final targetItems = await _repository.getItems(groupId: itemWithSubGroup.groupId);
              targetItems.add(itemWithSubGroup);
              await _repository.saveItemsForGroup(itemWithSubGroup.groupId, targetItems);

              final targetGroup = _groups.firstWhere(
                (g) => g.id == itemWithSubGroup.groupId,
                orElse: () => _activeGroup!,
              );

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Moved "${itemWithSubGroup.name}" to ${targetGroup.name}'),
                ),
              );
            } else {
              // Item remains in active group
              setState(() {
                if (existingItem == null) {
                  _items.add(itemWithSubGroup);
                } else {
                  final index =
                      _items.indexWhere((item) => item.id == existingItem.id);
                  if (index != -1) {
                    _items[index] = itemWithSubGroup;
                  }
                }
              });
              await _saveItems();
            }
          },
          onDelete: existingItem != null
              ? () {
                  setState(() {
                    _items.removeWhere((item) => item.id == existingItem.id);
                  });
                  _saveItems();
                }
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedItems = _filteredAndSortedItems;
    final bool showSubGroupCardsView =
        _subGroups.isNotEmpty && _activeSubGroup == null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search purchases...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : InkWell(
                onTap: _openGroupSelector,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _activeGroup?.name ?? 'Purchase Tracker',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Expense Calendar',
            onPressed: _openCalendarView,
          ),
          IconButton(
            icon: const Icon(Icons.folder_copy_outlined),
            tooltip: 'Switch Group',
            onPressed: _openGroupSelector,
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'currency_settings') {
                _showCurrencySettingsDialog();
              } else if (value == 'calendar') {
                _openCalendarView();
              } else if (value == 'copy_template') {
                _showCopyFromTemplateDialog();
              } else if (value == 'manage_templates') {
                _openManageTemplates();
              } else if (value == 'manage_categories') {
                _openManageCategories();
              } else if (value == 'backup_restore') {
                _openBackupRestore();
              } else if (value == 'switch_group') {
                _openGroupSelector();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'currency_settings',
                child: Row(
                  children: [
                    Icon(Icons.currency_exchange, size: 20),
                    SizedBox(width: 8),
                    Text('Currency Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_template',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Copy Items from Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage_templates',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Master Templates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Monthly Calendar View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'switch_group',
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Switch Group'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage_categories',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Categories'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'backup_restore',
                child: Row(
                  children: [
                    Icon(Icons.import_export, size: 20),
                    SizedBox(width: 8),
                    Text('Backup & Restore Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Sub-Groups / Months Horizontal Choice Bar
                  if (_subGroups.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        margin: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _subGroups.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final isSelected = _activeSubGroup == null;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        labelPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        label: const Text(
                                          'All Months/Groups',
                                          textAlign: TextAlign.center,
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) {
                                          setState(() {
                                            _activeSubGroup = null;
                                          });
                                        },
                                      ),
                                    );
                                  }

                                  final sg = _subGroups[index - 1];
                                  final isSelected = _activeSubGroup?.id == sg.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      showCheckmark: false,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 0,
                                      ),
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (sg.isPinned) ...[
                                            const Icon(
                                              Icons.push_pin,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            sg.name,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setState(() {
                                          _activeSubGroup = sg;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, size: 20),
                              tooltip: 'Copy Template into Sub-Group',
                              onPressed: () => _showCopyFromTemplateDialog(
                                preSelectedSubGroupId: _activeSubGroup?.id,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22),
                              tooltip: 'Add Sub-Group / Month',
                              onPressed: _showAddSubGroupDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _showAddSubGroupDialog,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Add Sub-Group / Month'),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Dashboard Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SummaryCard(
                        groupTargetBudget: _activeSubGroup != null
                            ? _activeSubGroup!.targetBudget
                            : _activeGroup?.targetBudget,
                        itemsPlannedTotal: itemsPlannedTotal,
                        totalActualSpent: totalActualSpent,
                        remainingBudget: remainingBudget,
                        totalSaved: totalSaved,
                        purchasedCount: purchasedCount,
                        totalCount: _effectiveGroupItems.length,
                        title: _activeSubGroup != null
                            ? '${_activeGroup?.name ?? 'PURCHASES'} • ${_activeSubGroup!.name}'
                            : (_activeGroup?.name ?? 'PURCHASE TRACKER'),
                        onEditBudget: _activeSubGroup != null
                            ? () => _showEditSubGroupDialog(_activeSubGroup!)
                            : _showEditGroupBudgetDialog,
                      ),
                    ),
                  ),

                  // Search & Category Filter Section
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Horizontal Chips
                        SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length + 1,
                            itemBuilder: (context, index) {
                              final category = index == 0
                                  ? CategoryConstants.all
                                  : _categories[index - 1];
                              final isSelected =
                                  _selectedCategory == category;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(category),
                                  avatar: category != CategoryConstants.all
                                      ? Icon(
                                          CategoryConstants.getIcon(category),
                                          size: 16,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.primary,
                                        )
                                      : null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Status & Sort Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              // Status Segmented Button
                              Expanded(
                                child: SegmentedButton<StatusFilter>(
                                  segments: const [
                                    ButtonSegment(
                                      value: StatusFilter.all,
                                      label: Text('All'),
                                    ),
                                    ButtonSegment(
                                      value: StatusFilter.pending,
                                      label: Text('Pending'),
                                    ),
                                    ButtonSegment(
                                      value: StatusFilter.purchased,
                                      label: Text('Bought'),
                                    ),
                                  ],
                                  selected: {_statusFilter},
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _statusFilter = selection.first;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Sort Direction Toggle Button
                              IconButton(
                                icon: Icon(
                                  _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: _isSortAscending ? 'Ascending Order (Tap to Flip)' : 'Descending Order (Tap to Flip)',
                                onPressed: () {
                                  setState(() {
                                    _isSortAscending = !_isSortAscending;
                                  });
                                },
                              ),

                              // Sort Menu Button
                              PopupMenuButton<SortOption>(
                                tooltip: 'Sort Items',
                                icon: const Icon(Icons.sort),
                                onSelected: (option) {
                                  setState(() {
                                    if (_sortOption == option) {
                                      _isSortAscending = !_isSortAscending;
                                    } else {
                                      _sortOption = option;
                                      _isSortAscending = option == SortOption.price ? false : true;
                                    }
                                  });
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: SortOption.name,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_sortOption == SortOption.name
                                            ? (_isSortAscending ? 'Name (A → Z)' : 'Name (Z → A)')
                                            : 'Sort by Name'),
                                        if (_sortOption == SortOption.name)
                                          Icon(
                                            _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortOption.price,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_sortOption == SortOption.price
                                            ? (_isSortAscending ? 'Price (Low → High)' : 'Price (High → Low)')
                                            : 'Sort by Price'),
                                        if (_sortOption == SortOption.price)
                                          Icon(
                                            _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortOption.category,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Sort by Category'),
                                        if (_sortOption == SortOption.category)
                                          Icon(
                                            _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortOption.status,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Sort by Status'),
                                        if (_sortOption == SortOption.status)
                                          Icon(
                                            _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Header Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            showSubGroupCardsView
                                ? 'Sub-Groups / Months (${_subGroups.length})'
                                : 'Your Purchases (${displayedItems.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            showSubGroupCardsView
                                ? 'Tap to open sub-group'
                                : 'Tap item to edit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SUB-GROUP CARDS VIEW OR ITEMS LIST VIEW
                  if (showSubGroupCardsView) ...[
                    // Display SubGroup Cards
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sg = _subGroups[index];
                            final sgItems = _items.where((i) => i.subGroupId == sg.id).toList();
                            return SubGroupCard(
                              subGroup: sg,
                              items: sgItems,
                              onTap: () {
                                setState(() {
                                  _activeSubGroup = sg;
                                });
                              },
                              onPinSubGroup: () => _togglePinSubGroup(sg),
                              onEditSubGroup: () => _showEditSubGroupDialog(sg),
                              onDeleteSubGroup: () => _confirmDeleteSubGroup(sg),
                            );
                          },
                          childCount: _subGroups.length,
                        ),
                      ),
                    ),

                    // Unassigned Main Items Section (if any exist without subgroup)
                    if (_items.any((i) => i.subGroupId == null)) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Main Unassigned Purchases',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final unassignedItems = _items.where((i) => i.subGroupId == null).toList();
                            final item = unassignedItems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: PurchaseItemTile(
                                item: item,
                                onTap: () => _addOrEditItem(existingItem: item),
                                onTogglePurchased: () => _togglePurchased(item),
                                onAddUnitBought: () => _addUnitBoughtToday(item),
                              ),
                            );
                          },
                          childCount: _items.where((i) => i.subGroupId == null).length,
                        ),
                      ),
                    ],
                  ] else ...[
                    // Display Items List
                    displayedItems.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No purchases found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to add a new purchase or clear filters',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = displayedItems[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: PurchaseItemTile(
                                    item: item,
                                    onTap: () => _addOrEditItem(existingItem: item),
                                    onTogglePurchased: () => _togglePurchased(item),
                                    onAddUnitBought: () => _addUnitBoughtToday(item),
                                  ),
                                );
                              },
                              childCount: displayedItems.length,
                            ),
                          ),
                  ],

                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditItem(),
        icon: const Icon(Icons.add),
        label: const Text('Add Purchase'),
      ),
    );
  }
}
