import 'package:intl/intl.dart';

/// Formatter utilities for RideCare metrics and timestamps
class DateFormatter {
  DateFormatter._();

  static final NumberFormat _kmFormat = NumberFormat('#,##0.#', 'id_ID');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Formats odometer value e.g. "14.250 km"
  static String formatKm(double km, {bool includeUnit = true}) {
    final formatted = _kmFormat.format(km);
    return includeUnit ? '$formatted km' : formatted;
  }

  /// Formats currency e.g. "Rp 75.000"
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Formats duration in seconds to "16 dtk", "34 mnt 12 dtk", or "1 jam 15 mnt"
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds dtk';
    }
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    if (minutes < 60) {
      if (remainingSecs == 0) return '$minutes mnt';
      return '$minutes mnt $remainingSecs dtk';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return '$hours jam';
    return '$hours jam $remainingMins mnt';
  }

  /// Digital stopwatch format e.g. "00:16", "34:12", "01:15:30"
  static String formatStopwatch(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats date e.g. "2 Sep 2026"
  static String formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  /// Formats date and time e.g. "2 Sep 2026, 08:30"
  static String formatDateTime(DateTime date) {
    final timeStr = DateFormat('HH:mm').format(date);
    return '${formatDate(date)}, $timeStr';
  }
}
