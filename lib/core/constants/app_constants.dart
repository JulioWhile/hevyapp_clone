/// App-wide constants.
library;

abstract final class AppConstants {
  /// Default rest timer duration in seconds.
  static const int defaultRestTimerSeconds = 90;

  /// Available rest timer presets (seconds).
  static const List<int> restTimerPresets = [30, 60, 90, 120, 150, 180, 240, 300];

  /// Maximum weight value allowed.
  static const double maxWeight = 9999.0;

  /// Maximum reps value allowed.
  static const int maxReps = 9999;

  /// RPE scale range.
  static const double minRpe = 1.0;
  static const double maxRpe = 10.0;

  /// RIR scale range.
  static const int minRir = 0;
  static const int maxRir = 10;

  /// Database name.
  static const String databaseName = 'hevy_app.db';
}
