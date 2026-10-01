import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sample_data.dart';
import 'models/purchase_item.dart';
import 'utils/formatters.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PurchaseTrackerApp());
}

class PurchaseTrackerApp extends StatelessWidget {
  const PurchaseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchase Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

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

class CategoryConstants {
  static const String all = 'All';
  static const List<String> categories = [
    'Riding Gear',
    'Camping',
    'Camera / Electronics',
    'Luggage',
    'Bike Tools',
    'Bike Accessories',
    'Safety',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Riding Gear':
        return Icons.sports_motorsports;
      case 'Camping':
        return Icons.other_houses;
      case 'Camera / Electronics':
        return Icons.photo_camera;
      case 'Luggage':
        return Icons.work;
      case 'Bike Tools':
        return Icons.build;
      case 'Bike Accessories':
        return Icons.two_wheeler;
      case 'Safety':
        return Icons.security;
      default:
        return Icons.shopping_bag;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PurchaseItem> _items = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategory = CategoryConstants.all;
  StatusFilter _statusFilter = StatusFilter.all;
  SortOption _sortOption = SortOption.nameAsc;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  static const String _storageKey = 'purchase_items_v1';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        if (decoded.isEmpty) {
          final initialItems = getInitialSampleData();
          setState(() {
            _items = initialItems;
            _isLoading = false;
          });
          await _saveItems();
        } else {
          setState(() {
            _items = decoded.map((item) => PurchaseItem.fromMap(item)).toList();
            _isLoading = false;
          });
        }
      } else {
        // First run - populate initial touring accessories
        final initialItems = getInitialSampleData();
        setState(() {
          _items = initialItems;
          _isLoading = false;
        });
        await _saveItems();
      }
    } catch (e) {
      setState(() {
        _items = getInitialSampleData();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(_items.map((item) => item.toMap()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      // Save error handling
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
      setState(() {
        _items = getInitialSampleData();
      });
      await _saveItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample data restored!')),
        );
      }
    }
  }

  // Calculations
  double get totalPlanned {
    return _items.fold(0.0, (sum, item) => sum + item.plannedTotal);
  }

  double get totalActualSpent {
    return _items.where((item) => item.isPurchased).fold(
          0.0,
          (sum, item) => sum + item.actualTotal,
        );
  }

  double get totalPurchasedPlanned {
    return _items.where((item) => item.isPurchased).fold(
          0.0,
          (sum, item) => sum + item.plannedTotal,
        );
  }

  double get totalSaved {
    return totalPurchasedPlanned - totalActualSpent;
  }

  double get remainingBudget {
    return _items.where((item) => !item.isPurchased).fold(
          0.0,
          (sum, item) => sum + item.plannedTotal,
        );
  }

  int get purchasedCount {
    return _items.where((item) => item.isPurchased).length;
  }

  List<PurchaseItem> get _filteredAndSortedItems {
    return _items.where((item) {
      // Search query filter
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

      // Category filter
      if (_selectedCategory != CategoryConstants.all &&
          item.category != _selectedCategory) {
        return false;
      }

      // Status filter
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
        isPurchased: isNowPurchased,
        datePurchased:
            isNowPurchased ? (item.datePurchased ?? DateTime.now()) : null,
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
        return _PurchaseFormBottomSheet(
          existingItem: existingItem,
          onSave: (newItem) {
            setState(() {
              if (existingItem == null) {
                _items.add(newItem);
              } else {
                final index =
                    _items.indexWhere((item) => item.id == existingItem.id);
                if (index != -1) {
                  _items[index] = newItem;
                }
              }
            });
            _saveItems();
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
            : const Text(
                'Purchase Tracker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
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
              onRefresh: _loadItems,
              child: CustomScrollView(
                slivers: [
                  // Dashboard Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSummaryCard(theme),
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
                            itemCount: CategoryConstants.categories.length + 1,
                            itemBuilder: (context, index) {
                              final category = index == 0
                                  ? CategoryConstants.all
                                  : CategoryConstants.categories[index - 1];
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
                                child: _buildPurchaseItemTile(theme, item),
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

  Widget _buildSummaryCard(ThemeData theme) {
    final double progress =
        _items.isEmpty ? 0.0 : purchasedCount / _items.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PURCHASE TRACKER',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$purchasedCount of ${_items.length} bought',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Planned Amount
          Text(
            'Planned Total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatCurrency(totalPlanned),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Spent, Remaining & Saved Metrics Row
          Row(
            children: [
              // Amount Spent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Spent',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalActualSpent),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 32,
                width: 1,
                color: Colors.white24,
              ),
              const SizedBox(width: 12),

              // Remaining Budget
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(remainingBudget),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 32,
                width: 1,
                color: Colors.white24,
              ),
              const SizedBox(width: 12),

              // Total Saved
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Saved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalSaved),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: totalSaved >= 0
                            ? Colors.greenAccent.shade100
                            : Colors.orangeAccent.shade100,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItemTile(ThemeData theme, PurchaseItem item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addOrEditItem(existingItem: item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              // Checkbox to mark as purchased
              Checkbox(
                value: item.isPurchased,
                activeColor: theme.colorScheme.primary,
                onChanged: (_) => _togglePurchased(item),
              ),

              const SizedBox(width: 8),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isPurchased
                                  ? theme.colorScheme.outline
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Quantity x Price
                        Text(
                          item.quantity > 1
                              ? '${item.quantity} × ${formatCurrency(item.plannedPrice)}'
                              : formatCurrency(item.plannedPrice),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CategoryConstants.getIcon(item.category),
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Price, Status & Purchase Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(item.effectiveTotal),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: item.isPurchased
                          ? Colors.green.shade700
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isPurchased
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.isPurchased
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      item.isPurchased ? 'Purchased' : 'Pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.isPurchased
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (item.isPurchased) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.datePurchased != null
                          ? formatDate(item.datePurchased!)
                          : 'Purchased',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet for Adding / Editing a Purchase Item
class _PurchaseFormBottomSheet extends StatefulWidget {
  final PurchaseItem? existingItem;
  final ValueChanged<PurchaseItem> onSave;
  final VoidCallback? onDelete;

  const _PurchaseFormBottomSheet({
    this.existingItem,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_PurchaseFormBottomSheet> createState() =>
      _PurchaseFormBottomSheetState();
}

class _PurchaseFormBottomSheetState
    extends State<_PurchaseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _plannedPriceController;
  late TextEditingController _actualPriceController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late bool _isPurchased;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController =
        TextEditingController(text: (item?.quantity ?? 1).toString());
    _plannedPriceController = TextEditingController(
      text: item != null ? item.plannedPrice.toStringAsFixed(0) : '',
    );
    _actualPriceController = TextEditingController(
      text: item?.actualPrice != null
          ? item!.actualPrice!.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedCategory = item?.category ?? CategoryConstants.categories.first;
    _isPurchased = item?.isPurchased ?? false;
    _selectedDate =
        item?.datePurchased ?? (_isPurchased ? DateTime.now() : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _plannedPriceController.dispose();
    _actualPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_plannedPriceController.text) ?? 0.0;
    return qty * price;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(_quantityController.text);
      final plannedPrice = double.parse(_plannedPriceController.text);
      final actualPriceText = _actualPriceController.text.trim();
      final actualPrice =
          actualPriceText.isNotEmpty ? double.tryParse(actualPriceText) : null;

      final newItem = PurchaseItem(
        id: widget.existingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        quantity: qty,
        plannedPrice: plannedPrice,
        actualPrice: actualPrice,
        category: _selectedCategory,
        isPurchased: _isPurchased,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        datePurchased:
            _isPurchased ? (_selectedDate ?? DateTime.now()) : null,
      );

      widget.onSave(newItem);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingItem != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottomsheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Purchase' : 'Add New Purchase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Riding Jacket',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Quantity & Planned Price Row
              Row(
                children: [
                  // Quantity
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(value);
                        if (n == null || n < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Planned Price per item
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _plannedPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Planned Price (₹) *',
                        hintText: '8000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        final p = double.tryParse(value);
                        if (p == null || p < 0) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category & Actual Price Row
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: CategoryConstants.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actual Paid Price (Optional)
              TextFormField(
                controller: _actualPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Actual Price Paid per item (Optional)',
                  hintText: 'Leave empty if same as planned',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Fitting Costs (Optional)',
                  hintText: 'e.g. ₹6,000 + ₹250 fitting',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // Purchased Switch
              SwitchListTile(
                title: const Text('Mark as Purchased'),
                subtitle: Text(
                  _isPurchased
                      ? 'Item bought & added to actual spent'
                      : 'Item is still pending',
                ),
                value: _isPurchased,
                onChanged: (val) {
                  setState(() {
                    _isPurchased = val;
                    if (_isPurchased && _selectedDate == null) {
                      _selectedDate =
                          widget.existingItem?.datePurchased ?? DateTime.now();
                    }
                  });
                },
              ),

              // Clear Purchase Date Selector Field when Marked as Purchased
              if (_isPurchased) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      formatDate(_selectedDate ?? DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Total Calculation Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Total:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatCurrency(_calculatedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Add Purchase',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
