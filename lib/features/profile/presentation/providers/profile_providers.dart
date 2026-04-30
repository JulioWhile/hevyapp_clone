import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/settings_dao.dart';
import 'package:hevy_app/main.dart';

/// Provides the SettingsDao instance.
final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(databaseProvider).settingsDao;
});

/// Watch user settings (reactive).
final userSettingsProvider = StreamProvider<UserSetting>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return dao.watchSettings();
});

/// All-time PR list for profile screen.
final allPRsProvider = FutureProvider<List<PRWithExercise>>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return dao.getAllLatestPRs();
});

/// Total workout count.
final workoutCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final workouts = await db.workoutDao.getCompletedWorkouts();
  return workouts.length;
});
