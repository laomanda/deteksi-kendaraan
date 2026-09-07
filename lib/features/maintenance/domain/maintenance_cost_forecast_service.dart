import 'package:intl/intl.dart';
import 'maintenance_prediction_service.dart';

/// DTO representing a budget forecast horizon (e.g. Next 30 Days, Next 90 Days, Next 180 Days)
class BudgetForecastHorizon {
  final int days;
  final String title;
  final double minTotal;
  final double maxTotal;
  final List<MaintenancePrediction> items;

  const BudgetForecastHorizon({
    required this.days,
    required this.title,
    required this.minTotal,
    required this.maxTotal,
    required this.items,
  });

  bool get hasItems => items.isNotEmpty;

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String get formattedRange {
    if (!hasItems) return 'Rp0';
    return '${_currencyFormat.format(minTotal)} - ${_currencyFormat.format(maxTotal)}';
  }

  String get formattedCompactRange {
    if (!hasItems) return 'Rp0';
    return '${_formatCompact(minTotal)} - ${_formatCompact(maxTotal)}';
  }

  static String _formatCompact(double amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)}K';
    }
    return _currencyFormat.format(amount);
  }
}

/// Service calculating upcoming cost aggregates and budget forecasts
class MaintenanceCostForecastService {
  MaintenanceCostForecastService._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Calculates total cost range for an individual maintenance item
  static ({double totalMin, double totalMax}) calculateItemCost({
    required double partMin,
    required double partMax,
    required double laborMin,
    required double laborMax,
  }) {
    return (
      totalMin: partMin + laborMin,
      totalMax: partMax + laborMax,
    );
  }

  /// Calculates total estimated cost for a given list of predictions
  /// Total min = sum of all minimums
  /// Total max = sum of all maximums
  static ({
    double minTotal,
    double maxTotal,
    int count,
    String formattedRange,
    String formattedCompactRange,
  }) calculateTotalCost(List<MaintenancePrediction> predictions) {
    double minSum = 0.0;
    double maxSum = 0.0;

    for (final p in predictions) {
      minSum += p.totalMin;
      maxSum += p.totalMax;
    }

    String formatted;
    String compact;

    if (predictions.isEmpty) {
      formatted = 'Rp0';
      compact = 'Rp0';
    } else {
      formatted =
          '${_currencyFormat.format(minSum)} - ${_currencyFormat.format(maxSum)}';
      compact =
          '${_formatCompact(minSum)} - ${_formatCompact(maxSum)}';
    }

    return (
      minTotal: minSum,
      maxTotal: maxSum,
      count: predictions.length,
      formattedRange: formatted,
      formattedCompactRange: compact,
    );
  }

  /// Calculates budget forecast by horizon: Next 30 Days, Next 90 Days, Next 180 Days
  static Map<int, BudgetForecastHorizon> calculateBudgetForecast(
    List<MaintenancePrediction> predictions,
  ) {
    const horizons = [
      (days: 30, title: 'Next 30 Days'),
      (days: 90, title: 'Next 90 Days'),
      (days: 180, title: 'Next 180 Days'),
    ];

    final Map<int, BudgetForecastHorizon> result = {};

    for (final h in horizons) {
      // Include only maintenance predicted within the horizon days
      final matchedItems =
          predictions.where((p) => p.isDueWithinDays(h.days)).toList();

      double minSum = 0.0;
      double maxSum = 0.0;
      for (final it in matchedItems) {
        minSum += it.totalMin;
        maxSum += it.totalMax;
      }

      result[h.days] = BudgetForecastHorizon(
        days: h.days,
        title: h.title,
        minTotal: minSum,
        maxTotal: maxSum,
        items: matchedItems,
      );
    }

    return result;
  }

  static String _formatCompact(double amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)}K';
    }
    return _currencyFormat.format(amount);
  }
}
