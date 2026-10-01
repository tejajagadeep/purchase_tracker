/// Helper function to format currency according to Indian Rupees notation.
String formatCurrency(double amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final integerPart = absAmount.truncate().toString();

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

  return '${isNegative ? '- ' : ''}₹$result';
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
