import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/routine_dao.dart';
import 'package:hevy_app/main.dart';

/// Provides the RoutineDao instance.
final routineDaoProvider = Provider<RoutineDao>((ref) {
  return ref.watch(databaseProvider).routineDao;
});

/// Watch all routines (reactive).
final routinesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  final dao = ref.watch(routineDaoProvider);
  return dao.watchAllRoutines();
});

/// Get routine detail (template + exercises).
final routineDetailProvider =
    FutureProvider.family<RoutineDetailData, int>((ref, templateId) async {
  final dao = ref.watch(routineDaoProvider);
  final template = await dao.getRoutineById(templateId);
  final exercises = await dao.getRoutineExercises(templateId);
  return RoutineDetailData(template: template, exercises: exercises);
});

class RoutineDetailData {
  final WorkoutTemplate template;
  final List<RoutineExerciseWithDetails> exercises;

  const RoutineDetailData({required this.template, required this.exercises});
}
