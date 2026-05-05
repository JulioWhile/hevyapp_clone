import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/workout_dao.dart';
import 'package:hevy_app/main.dart';

/// Provides the WorkoutDao instance.
final workoutDaoProvider = Provider<WorkoutDao>((ref) {
  return ref.watch(databaseProvider).workoutDao;
});

// ─── Active Workout State ──────────────────────────────────

/// Represents a set being edited in the active workout.
class ActiveSet {
  final int? dbId; // null if not yet persisted
  final int setNumber;
  final String setType;
  final double weight;
  final int reps;
  final bool isCompleted;
  final double? rpe;
  final int? rir;

  // Previous performance (ghost text)
  final double? previousWeight;
  final int? previousReps;

  const ActiveSet({
    this.dbId,
    required this.setNumber,
    this.setType = 'normal',
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
    this.rpe,
    this.rir,
    this.previousWeight,
    this.previousReps,
  });

  ActiveSet copyWith({
    int? dbId,
    int? setNumber,
    String? setType,
    double? weight,
    int? reps,
    bool? isCompleted,
    double? Function()? rpe,
    int? Function()? rir,
    double? Function()? previousWeight,
    int? Function()? previousReps,
  }) {
    return ActiveSet(
      dbId: dbId ?? this.dbId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      rpe: rpe != null ? rpe() : this.rpe,
      rir: rir != null ? rir() : this.rir,
      previousWeight: previousWeight != null
          ? previousWeight()
          : this.previousWeight,
      previousReps: previousReps != null ? previousReps() : this.previousReps,
    );
  }
}

/// An exercise in the active workout.
class ActiveExercise {
  final int? workoutExerciseId; // null if not yet persisted
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String equipment;
  final int orderIndex;
  final int? supersetGroupId;
  final List<ActiveSet> sets;
  final String? notes;
  final int? restTimerSeconds; // null = OFF, no auto-start on set completion
  final String? gifUrl;

  const ActiveExercise({
    this.workoutExerciseId,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.equipment,
    required this.orderIndex,
    this.supersetGroupId,
    this.sets = const [],
    this.notes,
    this.restTimerSeconds,
    this.gifUrl,
  });

  ActiveExercise copyWith({
    int? workoutExerciseId,
    int? orderIndex,
    int? Function()? supersetGroupId,
    List<ActiveSet>? sets,
    String? Function()? notes,
    int? Function()? restTimerSeconds,
    String? Function()? gifUrl,
  }) {
    return ActiveExercise(
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      equipment: equipment,
      orderIndex: orderIndex ?? this.orderIndex,
      supersetGroupId: supersetGroupId != null
          ? supersetGroupId()
          : this.supersetGroupId,
      sets: sets ?? this.sets,
      notes: notes != null ? notes() : this.notes,
      restTimerSeconds: restTimerSeconds != null
          ? restTimerSeconds()
          : this.restTimerSeconds,
      gifUrl: gifUrl != null ? gifUrl() : this.gifUrl,
    );
  }
}

/// Full active workout state.
class ActiveWorkoutState {
  final int? workoutId; // null until persisted
  final String name;
  final String? notes;
  final DateTime startedAt;
  final List<ActiveExercise> exercises;
  final bool isActive;
  final int elapsedSeconds;

  const ActiveWorkoutState({
    this.workoutId,
    this.name = 'Workout',
    this.notes,
    required this.startedAt,
    this.exercises = const [],
    this.isActive = true,
    this.elapsedSeconds = 0,
  });

  ActiveWorkoutState copyWith({
    int? workoutId,
    String? name,
    String? Function()? notes,
    List<ActiveExercise>? exercises,
    bool? isActive,
    int? elapsedSeconds,
  }) {
    return ActiveWorkoutState(
      workoutId: workoutId ?? this.workoutId,
      name: name ?? this.name,
      notes: notes != null ? notes() : this.notes,
      startedAt: startedAt,
      exercises: exercises ?? this.exercises,
      isActive: isActive ?? this.isActive,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  /// Total volume (weight × reps) for completed sets.
  double get totalVolume {
    double vol = 0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (s.isCompleted) {
          vol += s.weight * s.reps;
        }
      }
    }
    return vol;
  }

  /// Total completed sets count.
  int get completedSets {
    int count = 0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (s.isCompleted) count++;
      }
    }
    return count;
  }
}

/// Active workout state notifier — manages the entire active workout lifecycle.
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final WorkoutDao _workoutDao;
  Timer? _timer;

  ActiveWorkoutNotifier(this._workoutDao) : super(null);

  /// Start a new workout.
  Future<void> startWorkout({String name = 'Workout', int? templateId}) async {
    final workoutId = await _workoutDao.createWorkout(
      name: name,
      templateId: templateId,
    );

    state = ActiveWorkoutState(
      workoutId: workoutId,
      name: name,
      startedAt: DateTime.now(),
    );

    // Start elapsed timer.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null) {
        state = state!.copyWith(
          elapsedSeconds: DateTime.now().difference(state!.startedAt).inSeconds,
        );
      }
    });
  }

  /// Add an exercise to the active workout.
  Future<void> addExercise(Exercise exercise, {int? supersetGroupId}) async {
    if (state == null) return;

    final orderIndex = state!.exercises.length;
    final weId = await _workoutDao.addExerciseToWorkout(
      workoutId: state!.workoutId!,
      exerciseId: exercise.id,
      orderIndex: orderIndex,
      supersetGroupId: supersetGroupId,
    );

    // Fetch previous performance for ghost text.
    final previousSets = await _workoutDao.getPreviousPerformance(exercise.id);

    // Create initial set (pre-filled with 1 empty set).
    final setId = await _workoutDao.addSet(
      workoutExerciseId: weId,
      setNumber: 1,
    );

    final activeExercise = ActiveExercise(
      workoutExerciseId: weId,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.primaryMuscleGroup,
      equipment: exercise.equipment,
      orderIndex: orderIndex,
      supersetGroupId: supersetGroupId,
      gifUrl: exercise.gifUrl,
      sets: [
        ActiveSet(
          dbId: setId,
          setNumber: 1,
          previousWeight: previousSets.isNotEmpty
              ? previousSets[0].weight
              : null,
          previousReps: previousSets.isNotEmpty ? previousSets[0].reps : null,
        ),
      ],
    );

    state = state!.copyWith(exercises: [...state!.exercises, activeExercise]);
  }

  /// Add a new set to an exercise (duplicates last set's weight/reps).
  Future<void> addSet(int exerciseIndex) async {
    if (state == null) return;

    final exercise = state!.exercises[exerciseIndex];
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSetNumber = exercise.sets.length + 1;

    // Get previous performance for this set number.
    final previousSets = await _workoutDao.getPreviousPerformance(
      exercise.exerciseId,
    );
    final prevSet = previousSets.length >= newSetNumber
        ? previousSets[newSetNumber - 1]
        : null;

    final setId = await _workoutDao.addSet(
      workoutExerciseId: exercise.workoutExerciseId!,
      setNumber: newSetNumber,
      weight: lastSet?.weight ?? 0.0,
      reps: lastSet?.reps ?? 0,
    );

    final newSet = ActiveSet(
      dbId: setId,
      setNumber: newSetNumber,
      weight: lastSet?.weight ?? 0.0,
      reps: lastSet?.reps ?? 0,
      previousWeight: prevSet?.weight,
      previousReps: prevSet?.reps,
    );

    final updatedSets = [...exercise.sets, newSet];
    _updateExercise(exerciseIndex, exercise.copyWith(sets: updatedSets));
  }

  /// Update a set's values and persist to DB.
  Future<void> updateSet(
    int exerciseIndex,
    int setIndex, {
    double? weight,
    int? reps,
    String? setType,
    bool? isCompleted,
    double? rpe,
    int? rir,
  }) async {
    if (state == null) return;

    final exercise = state!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    // Auto-calculate warmup weight from normal sets when switching to warmup.
    double? resolvedWeight = weight;
    if (setType == 'warmup' && set.setType != 'warmup' && set.weight == 0.0) {
      final maxNormal = exercise.sets
          .where((s) => s.setType == 'normal' && s.weight > 0)
          .fold<double>(0, (max, s) => s.weight > max ? s.weight : max);
      if (maxNormal > 0) {
        resolvedWeight = double.parse((maxNormal * 0.5).toStringAsFixed(1));
      }
    }

    final updatedSet = set.copyWith(
      weight: resolvedWeight ?? set.weight,
      reps: reps ?? set.reps,
      setType: setType ?? set.setType,
      isCompleted: isCompleted ?? set.isCompleted,
      rpe: rpe != null ? () => rpe : null,
      rir: rir != null ? () => rir : null,
    );

    // Persist to DB.
    if (set.dbId != null) {
      await _workoutDao.updateSet(
        setId: set.dbId!,
        weight: resolvedWeight ?? weight,
        reps: reps,
        setType: setType,
        isCompleted: isCompleted,
        rpe: rpe,
        rir: rir,
      );
    }

    final updatedSets = List<ActiveSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;
    _updateExercise(exerciseIndex, exercise.copyWith(sets: updatedSets));
  }

  /// Update the workout notes.
  Future<void> updateWorkoutNotes(String notes) async {
    if (state == null) return;

    final updatedNotes = notes.trim().isEmpty ? null : notes.trim();

    if (state!.workoutId != null) {
      await _workoutDao.updateWorkoutNotes(state!.workoutId!, updatedNotes);
    }

    state = state!.copyWith(notes: () => updatedNotes);
  }

  /// Update notes for a specific exercise.
  Future<void> updateExerciseNotes(int exerciseIndex, String notes) async {
    if (state == null) return;

    final exercise = state!.exercises[exerciseIndex];
    final updatedNotes = notes.trim().isEmpty ? null : notes.trim();

    if (exercise.workoutExerciseId != null) {
      await _workoutDao.updateExerciseNotes(
        exercise.workoutExerciseId!,
        updatedNotes,
      );
    }

    _updateExercise(
      exerciseIndex,
      exercise.copyWith(notes: () => updatedNotes),
    );
  }

  /// Set the rest timer duration for an exercise (null = OFF).
  void updateExerciseRestTimer(int exerciseIndex, int? seconds) {
    if (state == null) return;
    final exercise = state!.exercises[exerciseIndex];
    _updateExercise(
      exerciseIndex,
      exercise.copyWith(restTimerSeconds: () => seconds),
    );
  }

  /// Delete a set.
  Future<void> deleteSet(int exerciseIndex, int setIndex) async {
    if (state == null) return;

    final exercise = state!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    if (set.dbId != null) {
      await _workoutDao.deleteSet(set.dbId!);
    }

    final updatedSets = List<ActiveSet>.from(exercise.sets)..removeAt(setIndex);
    // Renumber sets.
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    _updateExercise(exerciseIndex, exercise.copyWith(sets: updatedSets));
  }

  /// Remove an exercise from the workout.
  Future<void> removeExercise(int exerciseIndex) async {
    if (state == null) return;

    final exercise = state!.exercises[exerciseIndex];
    if (exercise.workoutExerciseId != null) {
      await _workoutDao.removeExerciseFromWorkout(exercise.workoutExerciseId!);
    }

    final updatedExercises = List<ActiveExercise>.from(state!.exercises)
      ..removeAt(exerciseIndex);
    state = state!.copyWith(exercises: updatedExercises);
  }

  /// Finish the workout.
  Future<void> finishWorkout() async {
    if (state == null || state!.workoutId == null) return;

    await _workoutDao.finishWorkout(state!.workoutId!);
    _timer?.cancel();
    state = null;
  }

  /// Discard the workout.
  Future<void> discardWorkout() async {
    if (state == null || state!.workoutId == null) return;

    await _workoutDao.deleteWorkout(state!.workoutId!);
    _timer?.cancel();
    state = null;
  }

  /// Cancel the workout (just clear state, don't delete from DB — for "resume later" scenarios).
  void cancelWorkout() {
    _timer?.cancel();
    state = null;
  }

  void _updateExercise(int index, ActiveExercise exercise) {
    final updatedExercises = List<ActiveExercise>.from(state!.exercises);
    updatedExercises[index] = exercise;
    state = state!.copyWith(exercises: updatedExercises);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the active workout.
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
      final dao = ref.watch(workoutDaoProvider);
      return ActiveWorkoutNotifier(dao);
    });

// ─── Rest Timer ────────────────────────────────────────────

/// Rest timer state.
class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  final _audioPlayer = AudioPlayer();

  RestTimerNotifier() : super(const RestTimerState());

  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
        _playBeep();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _playBeep() {
    _audioPlayer.play(AssetSource('sounds/timer_beep.wav'));
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void addTime(int seconds) {
    if (state.isRunning) {
      state = state.copyWith(
        remainingSeconds: state.remainingSeconds + seconds,
        totalSeconds: state.totalSeconds + seconds,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
      return RestTimerNotifier();
    });
