import 'package:flutter/material.dart';
import '../models/purchase_item.dart';
import '../models/sub_group.dart';
import '../utils/formatters.dart';

class SubGroupCard extends StatelessWidget {
  final SubGroup subGroup;
  final List<PurchaseItem> items;
  final VoidCallback onTap;
  final VoidCallback? onEditSubGroup;
  final VoidCallback? onPinSubGroup;

  const SubGroupCard({
    super.key,
    required this.subGroup,
    required this.items,
    required this.onTap,
    this.onEditSubGroup,
    this.onPinSubGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double planned = items.fold(0.0, (sum, i) => sum + i.plannedTotal);
    final double effectiveBudget = subGroup.targetBudget ?? planned;
    final double spent = items
        .where((i) => i.isPurchased)
        .fold(0.0, (sum, i) => sum + i.actualTotal);
    final double remaining = effectiveBudget - spent;
    final int boughtCount = items.where((i) => i.isPurchased).length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.folder_special,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (subGroup.isPinned) ...[
                                const Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                subGroup.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (subGroup.targetBudget != null)
                            Text(
                              'Target Budget: ${formatCurrency(subGroup.targetBudget!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$boughtCount of ${items.length} bought',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (onPinSubGroup != null) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          icon: Icon(
                            subGroup.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 18,
                            color: subGroup.isPinned ? Colors.orange : null,
                          ),
                          tooltip: subGroup.isPinned
                              ? 'Unpin Sub-Group'
                              : 'Pin Sub-Group to Top',
                          onPressed: onPinSubGroup,
                        ),
                      ],
                      if (onEditSubGroup != null) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Sub-Group',
                          onPressed: onEditSubGroup,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subGroup.targetBudget != null ? 'Sub Budget' : 'Planned',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(effectiveBudget),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(spent),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(remaining),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
