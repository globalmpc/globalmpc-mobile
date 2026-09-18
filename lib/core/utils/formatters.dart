import 'package:intl/intl.dart';

/// Display formatting helpers. Kept pure and dependency-light so they are
/// trivially testable and reusable across features.
class Fmt {
  const Fmt._();

  static final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');
  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');
  static final NumberFormat _token = NumberFormat('#,##0.####', 'en_US');

  /// 10000000000 -> "10B"
  static String compact(num value) => _compact.format(value);

  /// 10000000000 -> "10,000,000,000"
  static String grouped(num value) => _grouped.format(value);

  /// Token amount with up to 4 decimals, trailing zeros trimmed.
  static String token(num value) => _token.format(value);

  /// 0.42 -> "42%"
  static String percent(double fraction, {int decimals = 0}) =>
      '${(fraction * 100).toStringAsFixed(decimals)}%';

  /// 0x1234567890abcdef1234567890abcdef12345678 -> "0x1234…5678"
  static String shortAddress(String address, {int lead = 6, int tail = 4}) {
    if (address.length <= lead + tail + 1) return address;
    return '${address.substring(0, lead)}…${address.substring(address.length - tail)}';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy · HH:mm').format(d);
}
