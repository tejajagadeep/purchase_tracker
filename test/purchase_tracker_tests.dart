import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_tracker/models/purchase_item.dart';
import 'package:purchase_tracker/models/sub_group.dart';
import 'package:purchase_tracker/utils/formatters.dart';

void main() {
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

    test('Copying and Toggle Selection Preserves Dates', () {
      final dates = [DateTime(2026, 10, 12)];
      final item = PurchaseItem(
        id: '4',
        name: 'Gloves',
        quantity: 1,
        plannedPrice: 500.0,
        purchaseDates: dates,
        isCompleted: true,
      );

      // Toggle off / unselect
      final unselected = item.copyWith(isCompleted: false);
      expect(unselected.isPurchased, isFalse);
      expect(unselected.purchaseDates.length, equals(1)); // Dates preserved!

      // Toggle on / re-select
      final reselected = unselected.copyWith(isCompleted: true);
      expect(reselected.isPurchased, isTrue);
      expect(reselected.purchaseDates, equals(dates)); // Original date restored!
    });
  });

  group('2. Group & Sub-Group Budget Calculations', () {
    test('SubGroup Budget and Remaining Calculation', () {
      final sg = SubGroup(
        id: 'sg1',
        groupId: 'bike_touring',
        name: 'October 2026',
        targetBudget: 50000.0,
      );

      final items = [
        PurchaseItem(
          id: 'i1',
          name: 'Jacket',
          quantity: 1,
          plannedPrice: 8000.0,
          actualPrice: 7500.0,
          category: 'Riding Gear',
          purchaseDates: [DateTime(2026, 10, 1)],
          isCompleted: true,
        ),
        PurchaseItem(
          id: 'i2',
          name: 'Helmet',
          quantity: 1,
          plannedPrice: 5000.0,
          category: 'Safety & Protection',
        ),
      ];

      final double planned = items.fold(0.0, (sum, i) => sum + i.plannedTotal); // 13,000
      final double effectiveBudget = sg.targetBudget ?? planned; // 50,000
      final double spent = items
          .where((i) => i.purchasedQuantity > 0)
          .fold(0.0, (sum, i) => sum + i.actualTotal); // 7,500
      final double remaining = effectiveBudget - spent; // 42,500

      expect(effectiveBudget, equals(50000.0));
      expect(spent, equals(7500.0));
      expect(remaining, equals(42500.0));
    });
  });

  group('3. Formatters & Currency Manager Tests', () {
    test('formatCurrency with Rupee and Decimals', () {
      expect(formatCurrency(50.0), equals('₹50'));
      expect(formatCurrency(49.50), equals('₹49.50'));
      expect(formatCurrency(250000.0), equals('₹2,50,000'));
      expect(formatCurrency(0.0), equals('₹0'));
    });

    test('formatPriceForInput prevents rounding off decimals', () {
      expect(formatPriceForInput(50.0), equals('50'));
      expect(formatPriceForInput(49.50), equals('49.5'));
      expect(formatPriceForInput(12.75), equals('12.75'));
    });
  });
}
