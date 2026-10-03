import 'package:shared_preferences/shared_preferences.dart';

class CurrencyManager {
  static const String _currencyKey = 'app_currency_symbol_v1';
  static String _currentSymbol = '₹';

  static String get currentSymbol => _currentSymbol;

  static const List<Map<String, String>> supportedCurrencies = [
    {'symbol': '₹', 'name': 'Indian Rupee (₹)', 'code': 'INR'},
    {'symbol': '\$', 'name': 'US Dollar (\$)', 'code': 'USD'},
    {'symbol': '€', 'name': 'Euro (€)', 'code': 'EUR'},
    {'symbol': '£', 'name': 'British Pound (£)', 'code': 'GBP'},
    {'symbol': '¥', 'name': 'Japanese Yen (¥)', 'code': 'JPY'},
    {'symbol': 'A\$', 'name': 'Australian Dollar (A\$)', 'code': 'AUD'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar (C\$)', 'code': 'CAD'},
    {'symbol': 'AED', 'name': 'UAE Dirham (AED)', 'code': 'AED'},
  ];

  static Future<String> loadCurrencySymbol() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSymbol = prefs.getString(_currencyKey) ?? '₹';
    } catch (_) {}
    return _currentSymbol;
  }

  static Future<void> saveCurrencySymbol(String symbol) async {
    try {
      _currentSymbol = symbol;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, symbol);
    } catch (_) {}
  }
}

/// Helper function to format currency according to selected currency symbol notation.
String formatCurrency(double amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final intPart = absAmount.truncate();
  final decimalPart = absAmount - intPart;

  final integerPart = intPart.toString();

  String result = '';
  int len = integerPart.length;
  if (len > 3) {
    result = integerPart.substring(len - 3);
    int pos = len - 3;
    while (pos > 0) {
      if (pos >= 2) {
        result = '${integerPart.substring(pos - 2, pos)},$result';
        pos -= 2;
      } else {
        result = '${integerPart.substring(0, pos)},$result';
        pos = 0;
      }
    }
  } else {
    result = integerPart;
  }

  // Include decimal part if present (e.g. .50 or .75)
  if (decimalPart > 0.001) {
    final decStr = absAmount.toStringAsFixed(2).split('.').last;
    result = '$result.$decStr';
  }

  final symbol = CurrencyManager.currentSymbol;
  return '${isNegative ? '- ' : ''}$symbol$result';
}

/// Helper function to format numbers for form text inputs without rounding off decimals.
String formatPriceForInput(double price) {
  if (price == price.truncateToDouble()) {
    return price.truncate().toString();
  }
  return price
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

/// Helper function to format DateTime to readable string (e.g. 28 Sep 2026)
String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
