import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_tracker/main.dart';

void main() {
  testWidgets('Purchase Tracker app loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PurchaseTrackerApp());

    // Verify that Purchase Tracker app title exists
    expect(find.text('Purchase Tracker'), findsWidgets);
  });
}
