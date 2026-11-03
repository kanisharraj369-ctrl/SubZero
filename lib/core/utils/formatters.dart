import 'package:intl/intl.dart';

class AppFormatters {
  static String currency(double value, String code) {
    try {
      return NumberFormat.currency(name: code, symbol: _symbol(code), decimalDigits: 2).format(value);
    } catch (_) {
      return '${value.toStringAsFixed(2)} $code';
    }
  }

  static String _symbol(String code) => switch (code.toUpperCase()) {
        'USD' => r'$',
        'EUR' => '€',
        'GBP' => '£',
        'INR' => '₹',
        'JPY' => '¥',
        _ => '$code ',
      };

  static String date(DateTime value) => DateFormat('MMM d, yyyy').format(value);
}
