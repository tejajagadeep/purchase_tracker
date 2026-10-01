import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/purchase_item.dart';
import '../utils/formatters.dart';

class PurchaseItemTile extends StatelessWidget {
  final PurchaseItem item;
  final VoidCallback onTap;
  final VoidCallback onTogglePurchased;

  const PurchaseItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onTogglePurchased,
  });

  String _formatDatesSummary() {
    if (item.purchaseDates.isEmpty) return 'Pending';
    if (item.quantity == 1) {
      return formatDate(item.purchaseDates.first);
    }
    // Multiple quantities
    final datesStr = item.purchaseDates.map((d) => '${d.day}/${d.month}').join(', ');
    return '${item.purchasedQuantity}/${item.quantity} bought ($datesStr)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              // Checkbox to mark as purchased
              Checkbox(
                value: item.isPurchased,
                activeColor: theme.colorScheme.primary,
                onChanged: (_) => onTogglePurchased(),
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
                          : (item.purchasedQuantity > 0
                              ? Colors.blue.shade50
                              : Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.isPurchased
                            ? Colors.green.shade300
                            : (item.purchasedQuantity > 0
                                ? Colors.blue.shade300
                                : Colors.orange.shade300),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      item.isPurchased
                          ? 'Purchased'
                          : (item.purchasedQuantity > 0
                              ? '${item.purchasedQuantity}/${item.quantity} Bought'
                              : 'Pending'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.isPurchased
                            ? Colors.green.shade800
                            : (item.purchasedQuantity > 0
                                ? Colors.blue.shade900
                                : Colors.orange.shade900),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (item.purchaseDates.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDatesSummary(),
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
