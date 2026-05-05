import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/core/database/app_database.dart';

import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';

/// Watch completed workouts (reactive).
final workoutHistoryProvider = StreamProvider<List<Workout>>((ref) {
  final dao = ref.watch(workoutDaoProvider);
  return dao.watchCompletedWorkouts();
});

/// Get workout detail (exercises + sets) for a specific workout.
final workoutDetailProvider = FutureProvider.family<WorkoutDetailData, int>((
  ref,
  workoutId,
) async {
  final dao = ref.watch(workoutDaoProvider);
  final workout = await dao.getWorkoutById(workoutId);
  final exercisesWithDetails = await dao.getWorkoutExercises(workoutId);

  final exerciseDetails = <ExerciseWithSets>[];
  for (final ewd in exercisesWithDetails) {
    final sets = await dao.getSetsForExercise(ewd.workoutExercise.id);
    exerciseDetails.add(
      ExerciseWithSets(
        exercise: ewd.exercise,
        workoutExercise: ewd.workoutExercise,
        sets: sets,
      ),
    );
  }

  return WorkoutDetailData(workout: workout, exercises: exerciseDetails);
});

class WorkoutDetailData {
  final Workout workout;
  final List<ExerciseWithSets> exercises;

  const WorkoutDetailData({required this.workout, required this.exercises});

  double get totalVolume {
    double vol = 0;
    for (final e in exercises) {
      for (final s in e.sets) {
        if (s.isCompleted) {
          vol += s.weight * s.reps;
        }
      }
    }
    return vol;
  }

  int get totalSets {
    int count = 0;
    for (final e in exercises) {
      count += e.sets.where((s) => s.isCompleted).length;
    }
    return count;
  }

  List<MuscleSplitEntry> get muscleSplit {
    final counts = <String, int>{};
    for (final exercise in exercises) {
      final completedSets = exercise.sets
          .where((set) => set.isCompleted)
          .length;
      if (completedSets == 0) continue;

      final group = _muscleSplitLabel(exercise.exercise.primaryMuscleGroup);
      counts[group] = (counts[group] ?? 0) + completedSets;
    }

    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return const [];

    final entries =
        counts.entries
            .map(
              (entry) => MuscleSplitEntry(
                label: entry.key,
                setCount: entry.value,
                fraction: entry.value / total,
              ),
            )
            .toList()
          ..sort((a, b) => b.setCount.compareTo(a.setCount));
    return entries;
  }
}

class MuscleSplitEntry {
  final String label;
  final int setCount;
  final double fraction;

  const MuscleSplitEntry({
    required this.label,
    required this.setCount,
    required this.fraction,
  });

  int get percent => (fraction * 100).round();
}

String _muscleSplitLabel(String value) {
  return switch (value.toLowerCase()) {
    'biceps' || 'triceps' || 'forearms' => 'Arms',
    'quads' || 'hamstrings' || 'glutes' || 'calves' => 'Legs',
    'core' || 'abs' => 'Core',
    'cardio' => 'Cardio',
    'back' => 'Back',
    'chest' => 'Chest',
    'shoulders' => 'Shoulders',
    _ =>
      value.isEmpty
          ? 'Other'
          : '${value[0].toUpperCase()}${value.substring(1)}',
  };
}

class ExerciseWithSets {
  final Exercise exercise;
  final WorkoutExercise workoutExercise;
  final List<WorkoutSet> sets;

  const ExerciseWithSets({
    required this.exercise,
    required this.workoutExercise,
    required this.sets,
  });
}
