import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../utils/formatters.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = CurrencyManager.currentSymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide & Feature Help'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner Card
            Card(
              elevation: 2,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Purchase Tracker!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Learn how to plan budgets, track partial purchases, manage templates, and calculate savings easily. You can tap the Help (?) Icon in the top right corner beside Search anytime to open this guide.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Guide Topics
            _buildGuideCategory(
              context,
              icon: Icons.folder_special_outlined,
              color: Colors.blue,
              title: '1. Groups & Sub-Groups (Months / Trips)',
              description: 'Organize your purchases by main trips or events and break them down into monthly or categorical sub-groups.',
              items: [
                _GuideStep(
                  title: 'Create Main Groups',
                  detail: 'Tap "Switch Group" in the top menu or top bar to create new groups (e.g. "Bike Touring", "Home Expenses"). You can set a target budget and an optional description.',
                ),
                _GuideStep(
                  title: 'Add Sub-Groups / Months',
                  detail: 'Tap "+ Add Sub-Group / Month" on the dashboard to create sub-groups (e.g. "October 2026", "Camping Gear").',
                ),
                _GuideStep(
                  title: 'Pin & Complete Toggles',
                  detail: 'Tap the pin icon on any group or sub-group card to pin it to the top. Tap the edit or delete button on sub-group cards to manage them.',
                ),
                _GuideStep(
                  title: 'Sub-Group Card Metrics',
                  detail: 'Sub-group cards display Target Budget, Spent, Remaining, and Saved metrics along with a bought items counter.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideCategory(
              context,
              icon: Icons.add_shopping_cart_outlined,
              color: Colors.green,
              title: '2. Adding & Editing Purchases',
              description: 'Plan item quantities and prices, and record unit-by-unit purchases with custom dates and actual prices paid.',
              items: [
                _GuideStep(
                  title: 'Add New Purchase (+)',
                  detail:
                      'Tap the "+ Add Purchase" floating action button. Enter Item Name, Planned Quantity, and Planned Price ($symbol). Max 12-digit prices supported with full decimal precision (e.g., ${symbol}49.50).',
                ),
                _GuideStep(
                  title: 'Duplicate Name Protection',
                  detail: 'You cannot add, rename, or move an item to a name that already exists in the same Group or Sub-Group list. Same item names are allowed in different sub-groups!',
                ),
                _GuideStep(
                  title: 'Multi-Quantity Unit Purchases',
                  detail:
                      'When quantity > 1 (e.g., 30 Coffee), check off individual units as you buy them. You can enter specific actual prices ($symbol) for each bought unit.',
                ),
                _GuideStep(
                  title: 'Quick +1 Unit Bought Button',
                  detail: 'Tap the blue "+" button on any dashboard item tile to record 1 unit as bought today with a single tap!',
                ),
                _GuideStep(
                  title: 'Selection & Date Preservation',
                  detail: 'Unselecting a checked item keeps all your recorded purchase dates and custom unit prices safely in memory so re-selecting restores them instantly.',
                ),
                _GuideStep(
                  title: 'Auto-Check Completion Rules',
                  detail: 'Single-quantity items auto-check when "Mark as Purchased" is ON. Multi-quantity items auto-check on save ONLY when ALL quantity units are checked/bought.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideCategory(
              context,
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.purple,
              title: '3. Budgets, Spent & Savings Metrics',
              description: 'Monitor total planned costs, actual spending, remaining budget, and exact money saved.',
              items: [
                _GuideStep(
                  title: 'Dashboard Summary Card & Group Overview',
                  detail:
                      'Shows Total Group Budget, Items Planned, Actual Spent, Remaining Budget, and Total Saved ($symbol). Tap the Group Title (with ℹ️ info icon) to open a full Read-Only Financial Summary overview.',
                ),
                _GuideStep(
                  title: 'Items Planned Remaining Metric',
                  detail:
                      'In the Read-Only Financial Summary, "Items Planned Remaining" calculates the exact remaining planned cost ($symbol) needed to purchase all unbought / pending items.',
                ),
                _GuideStep(
                  title: 'Unplanned Spent Metric',
                  detail:
                      'In the Read-Only Financial Summary, "Unplanned Spent" tracks the exact total spent ($symbol) on impulse or unexpected purchases where planned cost was 0 (${symbol}0).',
                ),
                _GuideStep(
                  title: 'Over Spent Amount',
                  detail:
                      'In the Read-Only Financial Summary, "Over Spent Amount" tracks the total amount ($symbol) over-spent on items where actual cost exceeded the planned price.',
                ),
                _GuideStep(
                  title: 'Items Saved Amount',
                  detail:
                      'In the Read-Only Financial Summary, "Items Saved Amount" tracks the total money ($symbol) saved on checked items where actual cost was lower than planned.',
                ),
                _GuideStep(
                  title: 'Exact 2 Decimal Precision',
                  detail:
                      'All figures in the Read-Only Financial Summary display exact 2 decimal places (e.g. ${symbol}50,000.00, ${symbol}0.00) for complete financial accuracy.',
                ),
                _GuideStep(
                  title: 'Immediate Spent Calculation',
                  detail: 'Recording unit purchases or entering actual prices updates Spent and Remaining Budget amounts immediately.',
                ),
                _GuideStep(
                  title: 'Saved Amount Rule',
                  detail:
                      'Saved Amount ($symbol) is calculated ONLY when the item card checkmark is CHECKED (isPurchased = true). Unchecked items do not add to Saved until marked completed.',
                ),
                _GuideStep(
                  title: 'Progress Bar Completion',
                  detail:
                      'The progress bar fills dynamically based on your Actual Spent vs. Total Planned Budget (e.g., spending ${symbol}50,000 out of ${symbol}1,00,000 fills the bar 50%).',
                ),
                _GuideStep(
                  title: 'Over-Budget Warning Highlight',
                  detail: 'If planned items cost exceeds your set group budget, the Items Planned label turns Amber/Gold with a ⚠️ warning icon.',
                ),
                _GuideStep(
                  title: 'Currency Settings',
                  detail:
                      'Go to Menu > Currency Settings to change your currency symbol anytime ($symbol, \$, €, £, ¥, AED, etc.). Input field icons update dynamically to match.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideCategory(
              context,
              icon: Icons.calendar_month_outlined,
              color: Colors.orange,
              title: '4. Monthly Expense Calendar',
              description: 'View your daily purchase totals on an interactive monthly calendar.',
              items: [
                _GuideStep(
                  title: 'Open Calendar View',
                  detail: 'Tap the Calendar icon in the top app bar or top menu to open the Monthly Expense Calendar.',
                ),
                _GuideStep(
                  title: 'Daily Spending Breakdown',
                  detail: 'Days with purchases display the exact amount spent in green using your selected currency symbol. Tap any date on the grid to inspect itemized purchases bought on that day.',
                ),
                _GuideStep(
                  title: 'Clean Calendar Item Tiles',
                  detail: 'Expense items listed under a date show category names and quantities (e.g. Food & Dining x 2).',
                ),
                _GuideStep(
                  title: 'Read-Only Calendar Item Overview',
                  detail: 'Tap any expense item in the calendar day list to open its Read-Only Item Overview sheet, showing parent Group/Trip, Sub-Group/Month, unit purchase dates, and Money Saved (calculated only when item is checked as completed).',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideCategory(
              context,
              icon: Icons.copy_outlined,
              color: Colors.teal,
              title: '5. Reusable Master Templates',
              description: 'Create master item catalogs and copy them into any active group or month in one tap.',
              items: [
                _GuideStep(
                  title: 'Manage Master Templates',
                  detail: 'Go to Menu > Manage Master Templates to create master template presets (e.g., "Camping Trip Checklist", "Monthly Grocery List").',
                ),
                _GuideStep(
                  title: 'Copy Items from Template',
                  detail: 'Tap "Copy Items from Template" in the top menu or on a sub-group card. Select items and tap Copy to copy them into your active group or sub-group. Duplicate item names are automatically skipped!',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideCategory(
              context,
              icon: Icons.import_export,
              color: Colors.indigo,
              title: '6. Backup, Restore & Data Privacy',
              description: '100% offline local privacy with full JSON Backup and Restore.',
              items: [
                _GuideStep(
                  title: 'Export Backup',
                  detail: 'Go to Menu > Backup & Restore Data > Save Backup File to prompt location selection and save a JSON backup file on your device or Google Drive.',
                ),
                _GuideStep(
                  title: 'Merge Backup Data',
                  detail: 'Select "Merge Data" when importing a backup file to seamlessly combine new groups, sub-groups, items, and custom categories with your current data without deleting anything!',
                ),
                _GuideStep(
                  title: 'Replace Backup Data',
                  detail: 'Select "Replace Data" to overwrite current data with a backup file. A safety warning dialog prompts you to confirm before replacing any data.',
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    AppConstants.versionDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '100% Offline, Private & Secure',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCategory(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<_GuideStep> items,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
            fontSize: 11,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: items.map((step) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right_rounded, color: color, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GuideStep {
  final String title;
  final String detail;

  _GuideStep({required this.title, required this.detail});
}
