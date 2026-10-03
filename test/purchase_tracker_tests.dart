import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:purchase_tracker/constants/app_constants.dart';
import 'package:purchase_tracker/constants/categories.dart';
import 'package:purchase_tracker/models/purchase_group.dart';
import 'package:purchase_tracker/models/purchase_item.dart';
import 'package:purchase_tracker/models/sub_group.dart';
import 'package:purchase_tracker/services/backup_service.dart';
import 'package:purchase_tracker/utils/formatters.dart';
import 'package:purchase_tracker/widgets/purchase_item_tile.dart';
import 'package:purchase_tracker/widgets/sub_group_card.dart';
import 'package:purchase_tracker/widgets/summary_card.dart';
import 'package:purchase_tracker/screens/user_guide_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // 1. MODELS & CALCULATIONS
  // ---------------------------------------------------------------------------
  group('1. PurchaseItem Calculations & Scenarios', () {
    test('Single Quantity Unpurchased Item', () {
      final item = PurchaseItem(
        id: '1',
        name: 'Riding Jacket',
        quantity: 1,
        plannedPrice: 8000.0,
        category: 'Riding Gear',
      );

      expect(item.plannedTotal, equals(8000.0));
      expect(item.purchasedQuantity, equals(0));
      expect(item.isPurchased, isFalse);
      expect(item.actualTotal, equals(0.0));
      expect(item.effectiveTotal, equals(8000.0));
    });

    test('Single Quantity Purchased Item with Custom Price', () {
      final item = PurchaseItem(
        id: '1',
        name: 'Riding Jacket',
        quantity: 1,
        plannedPrice: 8000.0,
        actualPrice: 7500.0,
        category: 'Riding Gear',
        purchaseDates: [DateTime(2026, 10, 12)],
        isCompleted: true,
      );

      expect(item.isPurchased, isTrue);
      expect(item.purchasedQuantity, equals(1));
      expect(item.actualTotal, equals(7500.0));
      expect(item.effectiveTotal, equals(7500.0));
    });

    test('Multi-Quantity Partial Purchase (26 out of 30 Coffee @ 20)', () {
      final dates = List.generate(26, (i) => DateTime(2026, 10, i + 1));
      final item = PurchaseItem(
        id: '2',
        name: 'Coffee',
        quantity: 30,
        plannedPrice: 20.0,
        category: 'Food & Dining',
        purchaseDates: dates,
        isCompleted: false,
      );

      expect(item.plannedTotal, equals(600.0)); // 30 * 20
      expect(item.purchasedQuantity, equals(26));
      expect(item.isPurchased, isFalse); // 26 < 30 and not isCompleted
      expect(item.actualTotal, equals(520.0)); // 26 * 20
      expect(item.effectiveTotal, equals(520.0));
    });

    test('Multi-Quantity Custom Per-Unit Actual Prices (23 @ 20 + 3 @ 18)', () {
      final dates = List.generate(26, (i) => DateTime(2026, 10, i + 1));
      final unitPrices = List<double?>.generate(26, (i) => i < 23 ? 20.0 : 18.0);

      final item = PurchaseItem(
        id: '3',
        name: 'Coffee Discounted',
        quantity: 30,
        plannedPrice: 20.0,
        unitActualPrices: unitPrices,
        category: 'Food & Dining',
        purchaseDates: dates,
        isCompleted: false,
      );

      // 23 * 20 = 460, 3 * 18 = 54 -> Sum = 514
      expect(item.purchasedQuantity, equals(26));
      expect(item.actualTotal, equals(514.0));
    });

    test('Duplicate Name Detection in Same Location vs Different Location', () {
      final items = [
        PurchaseItem(
          id: '1',
          groupId: 'g1',
          subGroupId: 'sg1',
          name: 'Coffee',
          quantity: 10,
          plannedPrice: 20.0,
          category: 'Food & Dining',
        ),
        PurchaseItem(
          id: '2',
          groupId: 'g1',
          subGroupId: 'sg2',
          name: 'Coffee',
          quantity: 10,
          plannedPrice: 20.0,
          category: 'Food & Dining',
        ),
      ];

      bool isDuplicate(String name, String groupId, String? subGroupId, {String? excludeId}) {
        final clean = name.trim().toLowerCase();
        return items.any((i) {
          if (excludeId != null && i.id == excludeId) return false;
          return i.groupId == groupId && i.subGroupId == subGroupId && i.name.trim().toLowerCase() == clean;
        });
      }

      // 1. Same name in same sub-group 'sg1' -> Duplicate!
      expect(isDuplicate('coffee', 'g1', 'sg1'), isTrue);

      // 2. Same name in different sub-group 'sg3' -> Allowed!
      expect(isDuplicate('coffee', 'g1', 'sg3'), isFalse);

      // 3. Same name in different group 'g2' -> Allowed!
      expect(isDuplicate('coffee', 'g2', 'sg1'), isFalse);
    });

    test('PurchaseItem toMap & fromMap Serialization', () {
      final item = PurchaseItem(
        id: '10',
        groupId: 'trip1',
        subGroupId: 'sg1',
        name: 'Helmet',
        quantity: 1,
        plannedPrice: 5000.0,
        actualPrice: 4800.0,
        category: 'Safety & Protection',
        purchaseDates: [DateTime(2026, 10, 15)],
        isCompleted: true,
        notes: 'Bought at discount',
      );

      final map = item.toMap();
      final restored = PurchaseItem.fromMap(map);

      expect(restored.id, equals(item.id));
      expect(restored.name, equals(item.name));
      expect(restored.plannedPrice, equals(item.plannedPrice));
      expect(restored.actualPrice, equals(item.actualPrice));
      expect(restored.isCompleted, isTrue);
      expect(restored.notes, equals('Bought at discount'));
    });
  });

  group('2. PurchaseGroup & SubGroup Models', () {
    test('PurchaseGroup Model & Serialization', () {
      final group = PurchaseGroup(
        id: 'g1',
        name: 'Leh Ladakh Trip',
        description: 'Motorcycle expedition',
        targetBudget: 150000.0,
        isPinned: true,
        isTemplate: false,
      );

      final map = group.toMap();
      final restored = PurchaseGroup.fromMap(map);

      expect(restored.id, equals('g1'));
      expect(restored.name, equals('Leh Ladakh Trip'));
      expect(restored.targetBudget, equals(150000.0));
      expect(restored.isPinned, isTrue);
    });

    test('SubGroup Model & Serialization', () {
      final subGroup = SubGroup(
        id: 'sg1',
        groupId: 'g1',
        name: 'October 2026',
        targetBudget: 50000.0,
        isPinned: true,
      );

      final map = subGroup.toMap();
      final restored = SubGroup.fromMap(map);

      expect(restored.id, equals('sg1'));
      expect(restored.groupId, equals('g1'));
      expect(restored.name, equals('October 2026'));
      expect(restored.targetBudget, equals(50000.0));
      expect(restored.isPinned, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. CATEGORIES & FORMATTERS
  // ---------------------------------------------------------------------------
  group('3. Category & Icon Mapping Tests', () {
    test('CategoryConstants getIcon matching', () {
      expect(CategoryConstants.getIcon('Riding Gear'), equals(Icons.sports_motorsports));
      expect(CategoryConstants.getIcon('Camping'), equals(Icons.other_houses));
      expect(CategoryConstants.getIcon('Camera / Electronics'), equals(Icons.photo_camera));
      expect(CategoryConstants.getIcon('Food & Dining'), equals(Icons.restaurant));
      expect(CategoryConstants.getIcon('Unknown Random Category'), equals(Icons.category_outlined));
    });

    test('CurrencyManager Symbol Selection & Persistence', () async {
      await CurrencyManager.saveCurrencySymbol('\$');
      expect(CurrencyManager.currentSymbol, equals('\$'));
      expect(formatCurrency(100.0), equals('\$100'));

      await CurrencyManager.saveCurrencySymbol('₹');
      expect(CurrencyManager.currentSymbol, equals('₹'));
      expect(formatCurrency(100.0), equals('₹100'));
    });

    test('formatCurrency with decimals and formatting', () {
      expect(formatCurrency(50.0), equals('₹50'));
      expect(formatCurrency(49.50), equals('₹49.50'));
      expect(formatCurrency(250000.0), equals('₹2,50,000'));
      expect(formatCurrency(0.0), equals('₹0'));
    });

    test('formatPriceForInput prevents decimal rounding off', () {
      expect(formatPriceForInput(50.0), equals('50'));
      expect(formatPriceForInput(49.50), equals('49.5'));
      expect(formatPriceForInput(12.75), equals('12.75'));
    });
  });

  // ---------------------------------------------------------------------------
  // 4. BACKUP SERVICE & JSON RESTORE
  // ---------------------------------------------------------------------------
  group('4. BackupService Export & Import Tests', () {
    final backupService = BackupService();

    test('createBackupJson generates valid JSON structure', () async {
      final jsonStr = await backupService.createBackupJson();
      final decoded = jsonDecode(jsonStr);

      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['app'], equals('Purchase Tracker'));
      expect(decoded['groups'], isA<List>());
      expect(decoded['items'], isA<List>());
      expect(decoded['categories'], isA<List>());
    });

    test('restoreFromRawJson parses JSON Map data correctly', () async {
      final sampleBackup = {
        'app': 'Purchase Tracker',
        'version': 2,
        'groups': [
          {
            'id': 'g_test',
            'name': 'Test Group',
            'targetBudget': 20000.0,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'items': [
          {
            'id': 'i_test',
            'groupId': 'g_test',
            'name': 'Test Item',
            'quantity': 1,
            'plannedPrice': 500.0,
            'category': 'Other',
          }
        ],
        'categories': ['Other', 'Custom Category'],
      };

      final jsonString = jsonEncode(sampleBackup);
      final success = await backupService.restoreFromRawJson(jsonString, merge: true);

      expect(success, isTrue);
    });

    test('restoreFromRawJson handles raw List of items gracefully', () async {
      final sampleList = [
        {
          'id': 'i_list_1',
          'groupId': 'bike_touring',
          'name': 'Raw List Item',
          'quantity': 2,
          'plannedPrice': 150.0,
          'category': 'Other',
        }
      ];

      final jsonString = jsonEncode(sampleList);
      final success = await backupService.restoreFromRawJson(jsonString, merge: true);

      expect(success, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. WIDGET TESTS
  // ---------------------------------------------------------------------------
  group('5. UI Widget Tests', () {
    testWidgets('SummaryCard renders title, budget, spent, remaining, and saved',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              groupTargetBudget: 100000.0,
              itemsPlannedTotal: 80000.0,
              totalActualSpent: 30000.0,
              remainingBudget: 70000.0,
              totalSaved: 5000.0,
              purchasedCount: 2,
              totalCount: 5,
              title: 'LEH LADAKH EXPEDITION',
            ),
          ),
        ),
      );

      expect(find.text('LEH LADAKH EXPEDITION'), findsOneWidget);
      expect(find.text('2 of 5 bought'), findsOneWidget);
      expect(find.text('Total Group Budget'), findsOneWidget);
      expect(find.text('₹1,00,000'), findsOneWidget);
      expect(find.text('₹30,000'), findsOneWidget); // Spent
      expect(find.text('₹70,000'), findsOneWidget); // Remaining
      expect(find.text('₹5,000'), findsOneWidget); // Saved
    });

    testWidgets('SubGroupCard renders sub-group name, metrics and bought badge',
        (WidgetTester tester) async {
      final sg = SubGroup(
        id: 'sg_card_1',
        groupId: 'g1',
        name: 'October 2026 Sub-Group',
        targetBudget: 50000.0,
      );

      final items = [
        PurchaseItem(
          id: 'sg_item_1',
          name: 'Camping Tent',
          quantity: 1,
          plannedPrice: 10000.0,
          actualPrice: 9000.0,
          category: 'Camping',
          purchaseDates: [DateTime(2026, 10, 5)],
          isCompleted: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubGroupCard(
              subGroup: sg,
              items: items,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('October 2026 Sub-Group'), findsOneWidget);
      expect(find.text('1 of 1 bought'), findsOneWidget);
      expect(find.text('Sub Budget'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget); // Saved: 10000 - 9000
    });

    testWidgets('PurchaseItemTile renders item details and checkbox',
        (WidgetTester tester) async {
      final item = PurchaseItem(
        id: 'tile_1',
        name: 'Riding Jacket',
        quantity: 1,
        plannedPrice: 8000.0,
        category: 'Riding Gear',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseItemTile(
              item: item,
              onTap: () {},
              onTogglePurchased: () {},
            ),
          ),
        ),
      );

      expect(find.text('Riding Jacket'), findsOneWidget);
      expect(find.text('Riding Gear'), findsOneWidget);
      expect(find.text('₹8,000'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('UserGuideScreen renders header, version display, and help cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UserGuideScreen(),
        ),
      );

      expect(find.text('User Guide & Feature Help'), findsOneWidget);
      expect(find.text('Welcome to Purchase Tracker!'), findsOneWidget);
      expect(find.text(AppConstants.versionDisplay), findsOneWidget);
      expect(find.text('100% Offline, Private & Secure'), findsOneWidget);
    });
  });
}
