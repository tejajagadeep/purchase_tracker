import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../data/sample_data.dart';
import '../models/purchase_item.dart';
import '../models/purchase_group.dart';
import '../models/sub_group.dart';
import '../repositories/purchase_repository.dart';
import '../widgets/purchase_form_bottom_sheet.dart';
import '../widgets/purchase_item_tile.dart';
import '../widgets/summary_card.dart';
import 'backup_restore_screen.dart';
import 'calendar_expense_screen.dart';
import 'manage_categories_screen.dart';
import '../utils/formatters.dart';

enum SortOption {
  nameAsc,
  priceHighToLow,
  priceLowToHigh,
  status,
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
  SortOption _sortOption = SortOption.nameAsc;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

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
      _activeSubGroup = null;
      _items = items;
      _isLoading = false;
    });
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
                        title: Text(
                          group.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          group.targetBudget != null
                              ? 'Budget: ${formatCurrency(group.targetBudget!)}'
                              : (group.description ?? 'No target budget set'),
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
                                if (action == 'edit') {
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
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Group Budget (₹) (Optional)',
                  hintText: 'e.g. 250000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
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

                final newGroup = PurchaseGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
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
    final budgetController = TextEditingController(
      text: group.targetBudget != null ? group.targetBudget!.toStringAsFixed(0) : '',
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
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Group Budget (₹) (Optional)',
                  hintText: 'e.g. 250000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
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

                final updatedGroup = group.copyWith(
                  name: newName,
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
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Month / Sub-Group'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Sub-Group / Month Name',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate() && _activeGroup != null) {
                final newSubGroup = SubGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupId: _activeGroup!.id,
                  name: controller.text.trim(),
                );
                setState(() {
                  _subGroups.add(newSubGroup);
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
              initialValue: selectedParentGroupId,
              decoration: const InputDecoration(
                labelText: 'Target Parent Group',
                border: OutlineInputBorder(),
              ),
              items: otherGroups.map((g) {
                return DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name),
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

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Sample Data'),
        content: const Text(
          'This will reset your purchases list back to the default touring accessories list. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final initial = getInitialSampleData();
      setState(() {
        _items = initial;
      });
      await _saveItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample data restored!')),
        );
      }
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
    return _activeGroup?.targetBudget ?? itemsPlannedTotal;
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
    return totalPurchasedPlanned - totalActualSpent;
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
        switch (_sortOption) {
          case SortOption.nameAsc:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.priceHighToLow:
            return b.plannedTotal.compareTo(a.plannedTotal);
          case SortOption.priceLowToHigh:
            return a.plannedTotal.compareTo(b.plannedTotal);
          case SortOption.status:
            if (a.isPurchased == b.isPurchased) {
              return a.name.compareTo(b.name);
            }
            return a.isPurchased ? 1 : -1;
        }
      });
  }

  void _togglePurchased(PurchaseItem item) {
    final updatedIndex = _items.indexWhere((element) => element.id == item.id);
    if (updatedIndex != -1) {
      final isNowPurchased = !item.isPurchased;
      final updatedItem = item.copyWith(
        purchaseDates: isNowPurchased
            ? List.generate(item.quantity, (_) => DateTime.now())
            : [],
      );
      setState(() {
        _items[updatedIndex] = updatedItem;
      });
      _saveItems();
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

    return Scaffold(
      appBar: AppBar(
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
                  children: [
                    Flexible(
                      child: Text(
                        _activeGroup?.name ?? 'Purchase Tracker',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
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
              if (value == 'reset') {
                _resetToDefaults();
              } else if (value == 'calendar') {
                _openCalendarView();
              } else if (value == 'manage_categories') {
                _openManageCategories();
              } else if (value == 'backup_restore') {
                _openBackupRestore();
              } else if (value == 'switch_group') {
                _openGroupSelector();
              } else if (value == 'clear_search') {
                setState(() {
                  _selectedCategory = CategoryConstants.all;
                  _statusFilter = StatusFilter.all;
                  _searchQuery = '';
                  _searchController.clear();
                });
              }
            },
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'clear_search',
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_off_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Filters'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Load Sample Data'),
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
                  // Sub-Groups / Months Horizontal Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _subGroups.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final isSelected = _activeSubGroup == null;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        label: const Text('All Months/Items'),
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
                                      label: Text(sg.name),
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

                  // Dashboard Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SummaryCard(
                        groupTargetBudget: _activeGroup?.targetBudget,
                        itemsPlannedTotal: itemsPlannedTotal,
                        totalActualSpent: totalActualSpent,
                        remainingBudget: remainingBudget,
                        totalSaved: totalSaved,
                        purchasedCount: purchasedCount,
                        totalCount: _effectiveGroupItems.length,
                        title: _activeSubGroup != null
                            ? '${_activeGroup?.name ?? 'PURCHASES'} • ${_activeSubGroup!.name}'
                            : (_activeGroup?.name ?? 'PURCHASE TRACKER'),
                        onEditBudget: _showEditGroupBudgetDialog,
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

                              const SizedBox(width: 8),

                              // Sort Button
                              PopupMenuButton<SortOption>(
                                tooltip: 'Sort Items',
                                icon: const Icon(Icons.sort),
                                onSelected: (option) {
                                  setState(() {
                                    _sortOption = option;
                                  });
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: SortOption.nameAsc,
                                    child: Text('Sort by Name'),
                                  ),
                                  const PopupMenuItem(
                                    value: SortOption.priceHighToLow,
                                    child: Text('Price: High to Low'),
                                  ),
                                  const PopupMenuItem(
                                    value: SortOption.priceLowToHigh,
                                    child: Text('Price: Low to High'),
                                  ),
                                  const PopupMenuItem(
                                    value: SortOption.status,
                                    child: Text('Sort by Status'),
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

                  // List Header
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
                            'Your Purchases (${displayedItems.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap item to edit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Items List or Empty View
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
                                ),
                              );
                            },
                            childCount: displayedItems.length,
                          ),
                        ),

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
