import 'package:flutter/material.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../models/sub_group.dart';
import '../repositories/purchase_repository.dart';
import '../utils/formatters.dart';

class CalendarExpenseScreen extends StatefulWidget {
  const CalendarExpenseScreen({super.key});

  @override
  State<CalendarExpenseScreen> createState() => _CalendarExpenseScreenState();
}

class _CalendarExpenseScreenState extends State<CalendarExpenseScreen> {
  final IPurchaseRepository _repository = PurchaseRepository();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<PurchaseItem> _allItems = [];
  List<PurchaseGroup> _allGroups = [];
  List<SubGroup> _allSubGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedMonth.year, _focusedMonth.month, _focusedMonth.day);
    _loadItems();
  }

  Future<void> _loadItems() async {
    await CurrencyManager.loadCurrencySymbol();
    final items = await _repository.getItems();
    final groups = await _repository.getGroups(includeTemplates: true);
    final subGroups = await _repository.getSubGroups();
    setState(() {
      _allItems = items;
      _allGroups = groups;
      _allSubGroups = subGroups;
      _isLoading = false;
    });
  }

  String _getGroupName(String groupId) {
    final match = _allGroups.where((g) => g.id == groupId);
    return match.isNotEmpty ? match.first.name : 'Main Group';
  }

  String? _getSubGroupName(String? subGroupId) {
    if (subGroupId == null) return null;
    final match = _allSubGroups.where((sg) => sg.id == subGroupId);
    return match.isNotEmpty ? match.first.name : null;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Calculates total spent on a specific calendar day
  double _getDaySpent(DateTime day) {
    double total = 0.0;
    for (final item in _allItems) {
      for (int i = 0; i < item.purchaseDates.length; i++) {
        final pDate = item.purchaseDates[i];
        if (pDate.year == day.year &&
            pDate.month == day.month &&
            pDate.day == day.day) {
          double unitPrice = item.plannedPrice;
          if (i < item.unitActualPrices.length && item.unitActualPrices[i] != null) {
            unitPrice = item.unitActualPrices[i]!;
          } else if (item.actualPrice != null) {
            unitPrice = item.actualPrice!;
          }
          total += unitPrice;
        }
      }
    }
    return total;
  }

  /// Get purchase items bought on a specific day
  List<Map<String, dynamic>> _getDayPurchases(DateTime day) {
    final List<Map<String, dynamic>> list = [];
    for (final item in _allItems) {
      int countOnDay = 0;
      double dayTotal = 0.0;
      for (int i = 0; i < item.purchaseDates.length; i++) {
        final pDate = item.purchaseDates[i];
        if (pDate.year == day.year &&
            pDate.month == day.month &&
            pDate.day == day.day) {
          countOnDay++;
          double unitPrice = item.plannedPrice;
          if (i < item.unitActualPrices.length && item.unitActualPrices[i] != null) {
            unitPrice = item.unitActualPrices[i]!;
          } else if (item.actualPrice != null) {
            unitPrice = item.actualPrice!;
          }
          dayTotal += unitPrice;
        }
      }
      if (countOnDay > 0) {
        list.add({
          'item': item,
          'quantity': countOnDay,
          'total': dayTotal,
        });
      }
    }
    return list;
  }

  /// Calculates monthly summary metrics
  double get _monthlyTotalSpent {
    double total = 0.0;
    for (final item in _allItems) {
      for (int i = 0; i < item.purchaseDates.length; i++) {
        final pDate = item.purchaseDates[i];
        if (pDate.year == _focusedMonth.year &&
            pDate.month == _focusedMonth.month) {
          double unitPrice = item.plannedPrice;
          if (i < item.unitActualPrices.length && item.unitActualPrices[i] != null) {
            unitPrice = item.unitActualPrices[i]!;
          } else if (item.actualPrice != null) {
            unitPrice = item.actualPrice!;
          }
          total += unitPrice;
        }
      }
    }
    return total;
  }

  int get _monthlyPurchasesCount {
    int count = 0;
    for (final item in _allItems) {
      for (final pDate in item.purchaseDates) {
        if (pDate.year == _focusedMonth.year &&
            pDate.month == _focusedMonth.month) {
          count++;
        }
      }
    }
    return count;
  }

  void _showReadOnlyItemDetailsSheet(
    PurchaseItem item,
    DateTime day,
    int qtyOnDay,
    double totalOnDay,
  ) {
    final theme = Theme.of(context);
    final groupName = _getGroupName(item.groupId);
    final subGroupName = _getSubGroupName(item.subGroupId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  // BottomSheet Handle
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

                  // Title & Read-Only Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.category,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              'Read-Only',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Calendar Purchase Highlights Card
                  Card(
                    elevation: 1,
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.green.shade800, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bought on ${formatDate(day)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Recorded $qtyOnDay unit${qtyOnDay > 1 ? 's' : ''} purchased on this date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(totalOnDay),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Group & Price Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow('Group', groupName),
                          if (subGroupName != null) ...[
                            const Divider(height: 20),
                            _buildDetailRow('Sub-Group / Month', subGroupName),
                          ],
                          const Divider(height: 20),
                          _buildDetailRow('Total Planned Quantity', '${item.quantity} unit${item.quantity > 1 ? 's' : ''}'),
                          const Divider(height: 20),
                          _buildDetailRow('Planned Price per Unit', formatCurrency(item.plannedPrice)),
                          const Divider(height: 20),
                          _buildDetailRow('Total Planned Cost', formatCurrency(item.plannedTotal)),
                          const Divider(height: 20),
                          _buildDetailRow('Total Purchased Units', '${item.purchasedQuantity} of ${item.quantity} bought'),
                          const Divider(height: 20),
                          _buildDetailRow('Total Actual Amount Paid', formatCurrency(item.actualTotal)),
                          if (item.plannedTotal > item.actualTotal) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              'Money Saved',
                              formatCurrency(item.plannedTotal - item.actualTotal),
                              valueColor: Colors.green.shade700,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes & Fitting Costs',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.note_alt_outlined, color: theme.colorScheme.outline, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.notes!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (item.purchaseDates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Recorded Purchase Dates (${item.purchaseDates.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      child: Column(
                        children: List.generate(item.purchaseDates.length, (index) {
                          final pDate = item.purchaseDates[index];
                          double unitPrice = item.plannedPrice;
                          if (index < item.unitActualPrices.length && item.unitActualPrices[index] != null) {
                            unitPrice = item.unitActualPrices[index]!;
                          } else if (item.actualPrice != null) {
                            unitPrice = item.actualPrice!;
                          }

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            title: Text('Unit ${index + 1}: ${formatDate(pDate)}'),
                            trailing: Text(
                              formatCurrency(unitPrice),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close Overview'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Days calculation for current focused month
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expense Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Month Selector Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),

                // Monthly Summary Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Expenses',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency(_monthlyTotalSpent),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$_monthlyPurchasesCount',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Items Bought',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Calendar Weekday Headers
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _WeekdayHeader('Mon'),
                        _WeekdayHeader('Tue'),
                        _WeekdayHeader('Wed'),
                        _WeekdayHeader('Thu'),
                        _WeekdayHeader('Fri'),
                        _WeekdayHeader('Sat'),
                        _WeekdayHeader('Sun'),
                      ],
                    ),
                  ),
                ),

                // Calendar Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dayOffset = index - (startingWeekday - 1);
                        if (dayOffset < 0 || dayOffset >= daysInMonth) {
                          return const SizedBox(); // Empty cell outside month
                        }

                        final dayNum = dayOffset + 1;
                        final currentDay = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          dayNum,
                        );

                        final daySpent = _getDaySpent(currentDay);
                        final isSelected = _selectedDay != null &&
                            _selectedDay!.year == currentDay.year &&
                            _selectedDay!.month == currentDay.month &&
                            _selectedDay!.day == currentDay.day;

                        final isToday = DateTime.now().year == currentDay.year &&
                            DateTime.now().month == currentDay.month &&
                            DateTime.now().day == currentDay.day;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDay = currentDay;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (daySpent > 0
                                      ? Colors.green.shade50
                                      : (isToday
                                          ? theme.colorScheme.surfaceContainerHighest
                                          : null)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isToday
                                        ? theme.colorScheme.primary
                                        : Colors.grey.shade300),
                                width: isToday ? 1.5 : 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(2.0),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontWeight:
                                            isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : (isToday ? theme.colorScheme.primary : null),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (daySpent > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        formatCurrency(daySpent),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: startingWeekday - 1 + daysInMonth,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Selected Day Header
                if (_selectedDay != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Text(
                        'Expenses on ${formatDate(_selectedDay!)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Selected Day Purchase List
                  SliverToBoxAdapter(
                    child: _buildDayPurchasesList(theme, _selectedDay!),
                  ),
                ],

                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
    );
  }

  Widget _buildDayPurchasesList(ThemeData theme, DateTime day) {
    final dayPurchases = _getDayPurchases(day);

    if (dayPurchases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No expenses recorded on ${formatDate(day)}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      itemCount: dayPurchases.length,
      itemBuilder: (context, index) {
        final entry = dayPurchases[index];
        final PurchaseItem item = entry['item'];
        final int qty = entry['quantity'];
        final double total = entry['total'];

        final groupName = _getGroupName(item.groupId);
        final subGroupName = _getSubGroupName(item.subGroupId);
        final groupInfo = subGroupName != null ? '$groupName ($subGroupName)' : groupName;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            onTap: () => _showReadOnlyItemDetailsSheet(item, day, qty, total),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.check,
                color: Colors.green.shade800,
                size: 18,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              qty > 1 ? '${item.category} x $qty' : item.category,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCurrency(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
