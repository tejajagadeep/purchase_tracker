import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final double? groupTargetBudget;
  final double itemsPlannedTotal;
  final double totalActualSpent;
  final double remainingBudget;
  final double totalSaved;
  final int purchasedCount;
  final int totalCount;
  final String title;
  final VoidCallback? onEditBudget;
  final VoidCallback? onTapTitle;

  const SummaryCard({
    super.key,
    this.groupTargetBudget,
    required this.itemsPlannedTotal,
    required this.totalActualSpent,
    required this.remainingBudget,
    required this.totalSaved,
    required this.purchasedCount,
    required this.totalCount,
    this.title = 'PURCHASE TRACKER',
    this.onEditBudget,
    this.onTapTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasValidGroupBudget =
        groupTargetBudget != null && groupTargetBudget! > 0;
    final effectiveBudget =
        hasValidGroupBudget ? groupTargetBudget! : itemsPlannedTotal;
    final double budgetForProgress =
        effectiveBudget > 0 ? effectiveBudget : itemsPlannedTotal;
    final double progress = budgetForProgress <= 0
        ? 0.0
        : (totalActualSpent / budgetForProgress).clamp(0.0, 1.0);
    final bool isOverBudgetPlanned =
        hasValidGroupBudget && itemsPlannedTotal > groupTargetBudget!;

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
          // Header Title & Bought Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTapTitle,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onTapTitle != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$purchasedCount of $totalCount bought',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Budget & Items Planned Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasValidGroupBudget
                          ? 'Total Group Budget'
                          : 'Items Planned Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatCurrency(effectiveBudget),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (onEditBudget != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onEditBudget,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color:
                                    theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (hasValidGroupBudget) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOverBudgetPlanned) ...[
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'Items Planned',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverBudgetPlanned
                                ? Colors.amberAccent
                                : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            fontWeight: isOverBudgetPlanned
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatCurrency(itemsPlannedTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isOverBudgetPlanned
                              ? Colors.amberAccent
                              : theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
                          color:
                              theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Spent',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatCurrency(totalActualSpent),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
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
              const SizedBox(width: 8),

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
                          color:
                              theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Remaining',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatCurrency(remainingBudget),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
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
              const SizedBox(width: 8),

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
                          color:
                              theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Saved',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatCurrency(totalSaved),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: totalSaved >= 0
                              ? Colors.greenAccent.shade100
                              : Colors.orangeAccent.shade100,
                          fontWeight: FontWeight.bold,
                        ),
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
              backgroundColor:
                  theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
