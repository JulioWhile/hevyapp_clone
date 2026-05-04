import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/exercise_dao.dart';
import 'package:hevy_app/main.dart';

/// Provides the ExerciseDao instance.
final exerciseDaoProvider = Provider<ExerciseDao>((ref) {
  return ref.watch(databaseProvider).exerciseDao;
});

/// State for exercise search/filter.
class ExerciseFilter {
  final String query;
  final String? muscleGroup;

  const ExerciseFilter({this.query = '', this.muscleGroup});

  ExerciseFilter copyWith({String? query, String? Function()? muscleGroup}) {
    return ExerciseFilter(
      query: query ?? this.query,
      muscleGroup: muscleGroup != null ? muscleGroup() : this.muscleGroup,
    );
  }
}

/// Current filter state.
final exerciseFilterProvider = StateProvider<ExerciseFilter>((ref) {
  return const ExerciseFilter();
});

/// Filtered exercise list — reacts to filter changes.
final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final dao = ref.watch(exerciseDaoProvider);
  final filter = ref.watch(exerciseFilterProvider);

  if (filter.query.isNotEmpty && filter.muscleGroup != null) {
    return dao.searchByAnyMuscleGroup(filter.query, filter.muscleGroup!);
  } else if (filter.query.isNotEmpty) {
    return dao.searchExercises(filter.query);
  } else if (filter.muscleGroup != null) {
    return dao.getByAnyMuscleGroup(filter.muscleGroup!);
  } else {
    return dao.getAllExercises();
  }
});

/// Available muscle groups for filter chips.
final muscleGroupsProvider = FutureProvider<List<String>>((ref) async {
  final dao = ref.watch(exerciseDaoProvider);
  return dao.getDistinctMuscleGroups();
});
