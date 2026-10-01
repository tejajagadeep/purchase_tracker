import 'package:flutter/material.dart';
import '../models/purchase_item.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedMonth.year, _focusedMonth.month, _focusedMonth.day);
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _repository.getItems();
    setState(() {
      _allItems = items;
      _isLoading = false;
    });
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
      for (final pDate in item.purchaseDates) {
        if (pDate.year == day.year &&
            pDate.month == day.month &&
            pDate.day == day.day) {
          final pricePerUnit = item.actualPrice ?? item.plannedPrice;
          total += pricePerUnit;
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
      for (final pDate in item.purchaseDates) {
        if (pDate.year == day.year &&
            pDate.month == day.month &&
            pDate.day == day.day) {
          countOnDay++;
        }
      }
      if (countOnDay > 0) {
        final unitPrice = item.actualPrice ?? item.plannedPrice;
        list.add({
          'item': item,
          'quantity': countOnDay,
          'total': countOnDay * unitPrice,
        });
      }
    }
    return list;
  }

  /// Calculates monthly summary metrics
  double get _monthlyTotalSpent {
    double total = 0.0;
    for (final item in _allItems) {
      for (final pDate in item.purchaseDates) {
        if (pDate.year == _focusedMonth.year &&
            pDate.month == _focusedMonth.month) {
          final pricePerUnit = item.actualPrice ?? item.plannedPrice;
          total += pricePerUnit;
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                if (daySpent > 0)
                                  FittedBox(
                                    child: Text(
                                      '₹${daySpent.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 10),
                              ],
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
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
              '$qty unit${qty > 1 ? 's' : ''} • ${item.category}',
            ),
            trailing: Text(
              formatCurrency(total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
                fontSize: 16,
              ),
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
