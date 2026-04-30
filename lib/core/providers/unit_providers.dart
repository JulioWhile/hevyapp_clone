import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/features/profile/presentation/providers/profile_providers.dart';

/// Returns "kg" or "lbs" based on user settings.
final unitLabelProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(userSettingsProvider);
  return settingsAsync.when(
    data: (s) => s.unitSystem == 'metric' ? 'kg' : 'lbs',
    loading: () => 'kg',
    error: (_, _) => 'kg',
  );
});

/// Returns "KG" or "LBS" (uppercase) for column headers.
final unitLabelUpperProvider = Provider<String>((ref) {
  final label = ref.watch(unitLabelProvider);
  return label.toUpperCase();
});
