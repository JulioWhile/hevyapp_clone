import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'workout_dao.g.dart';

/// Data access object for workouts and related entities.
@DriftAccessor(tables: [Workouts, WorkoutExercises, WorkoutSets, Exercises])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ─── Workout CRUD ────────────────────────────────────────

  /// Create a new workout, returns its ID.
  Future<int> createWorkout({
    required String name,
    int? templateId,
  }) {
    return into(workouts).insert(
      WorkoutsCompanion.insert(
        name: name,
        startedAt: DateTime.now(),
        templateId: Value(templateId),
      ),
    );
  }

  /// Finish a workout — set finished time and duration.
  Future<void> finishWorkout(int workoutId) async {
    final workout = await (select(workouts)..where((t) => t.id.equals(workoutId))).getSingle();
    final duration = DateTime.now().difference(workout.startedAt).inSeconds;

    await (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        finishedAt: Value(DateTime.now()),
        durationSeconds: Value(duration),
      ),
    );
  }

  /// Delete a workout and all its exercises/sets (cascade).
  Future<void> deleteWorkout(int workoutId) async {
    // Get workout exercises first.
    final wExercises = await (select(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId)))
        .get();

    // Delete sets for each workout exercise.
    for (final we in wExercises) {
      await (delete(workoutSets)..where((t) => t.workoutExerciseId.equals(we.id))).go();
    }

    // Delete workout exercises.
    await (delete(workoutExercises)..where((t) => t.workoutId.equals(workoutId))).go();

    // Delete workout.
    await (delete(workouts)..where((t) => t.id.equals(workoutId))).go();
  }

  /// Update workout notes.
  Future<void> updateWorkoutNotes(int workoutId, String? notes) {
    return (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(notes: Value(notes)),
    );
  }

  /// Get all completed workouts, newest first.
  Future<List<Workout>> getCompletedWorkouts() {
    return (select(workouts)
          ..where((t) => t.finishedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  /// Watch completed workouts (reactive).
  Stream<List<Workout>> watchCompletedWorkouts() {
    return (select(workouts)
          ..where((t) => t.finishedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  /// Get a workout by ID.
  Future<Workout> getWorkoutById(int id) {
    return (select(workouts)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Check if there's an active (unfinished) workout.
  Future<Workout?> getActiveWorkout() {
    return (select(workouts)
          ..where((t) => t.finishedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  // ─── Workout Exercises ───────────────────────────────────

  /// Add an exercise to a workout.
  Future<int> addExerciseToWorkout({
    required int workoutId,
    required int exerciseId,
    required int orderIndex,
    int? supersetGroupId,
  }) {
    return into(workoutExercises).insert(
      WorkoutExercisesCompanion.insert(
        workoutId: workoutId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
        supersetGroupId: Value(supersetGroupId),
      ),
    );
  }

  /// Get all exercises for a workout with exercise details.
  Future<List<WorkoutExerciseWithDetails>> getWorkoutExercises(int workoutId) async {
    final query = select(workoutExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(workoutExercises.exerciseId)),
    ])
      ..where(workoutExercises.workoutId.equals(workoutId))
      ..orderBy([OrderingTerm.asc(workoutExercises.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) {
      return WorkoutExerciseWithDetails(
        workoutExercise: row.readTable(workoutExercises),
        exercise: row.readTable(exercises),
      );
    }).toList();
  }

  /// Remove an exercise from a workout (and its sets).
  Future<void> removeExerciseFromWorkout(int workoutExerciseId) async {
    await (delete(workoutSets)..where((t) => t.workoutExerciseId.equals(workoutExerciseId))).go();
    await (delete(workoutExercises)..where((t) => t.id.equals(workoutExerciseId))).go();
  }

  /// Update exercise notes.
  Future<void> updateExerciseNotes(int workoutExerciseId, String? notes) {
    return (update(workoutExercises)..where((t) => t.id.equals(workoutExerciseId))).write(
      WorkoutExercisesCompanion(notes: Value(notes)),
    );
  }

  /// Reorder exercises in a workout.
  Future<void> reorderExercises(int workoutId, List<int> workoutExerciseIds) async {
    for (int i = 0; i < workoutExerciseIds.length; i++) {
      await (update(workoutExercises)..where((t) => t.id.equals(workoutExerciseIds[i]))).write(
        WorkoutExercisesCompanion(orderIndex: Value(i)),
      );
    }
  }

  // ─── Sets ────────────────────────────────────────────────

  /// Add a set to a workout exercise.
  Future<int> addSet({
    required int workoutExerciseId,
    required int setNumber,
    String setType = 'normal',
    double weight = 0.0,
    int reps = 0,
  }) {
    return into(workoutSets).insert(
      WorkoutSetsCompanion.insert(
        workoutExerciseId: workoutExerciseId,
        setNumber: setNumber,
        setType: Value(setType),
        weight: Value(weight),
        reps: Value(reps),
      ),
    );
  }

  /// Update a set's values.
  Future<void> updateSet({
    required int setId,
    double? weight,
    int? reps,
    String? setType,
    bool? isCompleted,
    double? rpe,
    int? rir,
  }) {
    return (update(workoutSets)..where((t) => t.id.equals(setId))).write(
      WorkoutSetsCompanion(
        weight: weight != null ? Value(weight) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        setType: setType != null ? Value(setType) : const Value.absent(),
        isCompleted: isCompleted != null ? Value(isCompleted) : const Value.absent(),
        rpe: rpe != null ? Value(rpe) : const Value.absent(),
        rir: rir != null ? Value(rir) : const Value.absent(),
      ),
    );
  }

  /// Delete a set.
  Future<void> deleteSet(int setId) {
    return (delete(workoutSets)..where((t) => t.id.equals(setId))).go();
  }

  /// Get all sets for a workout exercise.
  Future<List<WorkoutSet>> getSetsForExercise(int workoutExerciseId) {
    return (select(workoutSets)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }

  /// Watch sets for a workout exercise (reactive).
  Stream<List<WorkoutSet>> watchSetsForExercise(int workoutExerciseId) {
    return (select(workoutSets)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .watch();
  }

  // ─── Previous performance ────────────────────────────────

  /// Get the most recent completed sets for an exercise (from last workout).
  Future<List<WorkoutSet>> getPreviousPerformance(int exerciseId) async {
    // Find the most recent completed workout containing this exercise.
    final query = select(workoutExercises).join([
      innerJoin(workouts, workouts.id.equalsExp(workoutExercises.workoutId)),
    ])
      ..where(
        workoutExercises.exerciseId.equals(exerciseId) & workouts.finishedAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.desc(workouts.startedAt)])
      ..limit(1);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final lastWorkoutExercise = rows.first.readTable(workoutExercises);
    return getSetsForExercise(lastWorkoutExercise.id);
  }

  // ─── Analytics ───────────────────────────────────────────

  /// Get max weight history for an exercise over time.
  Future<List<ChartDataPoint>> getMaxWeightHistory(int exerciseId) async {
    final query = customSelect(
      '''
      SELECT w.started_at as date, MAX(ws.weight) as value
      FROM workouts w
      JOIN workout_exercises we ON w.id = we.workout_id
      JOIN workout_sets ws ON we.id = ws.workout_exercise_id
      WHERE we.exercise_id = ? AND w.finished_at IS NOT NULL AND ws.is_completed = 1
      GROUP BY w.id
      ORDER BY w.started_at ASC
      ''',
      variables: [Variable.withInt(exerciseId)],
    );
    
    final rows = await query.get();
    return rows.map((r) => ChartDataPoint(
      date: DateTime.parse(r.read<String>('date')),
      value: r.read<double>('value'),
    )).toList();
  }

  /// Get volume history for an exercise over time.
  Future<List<ChartDataPoint>> getVolumeHistory(int exerciseId) async {
    final query = customSelect(
      '''
      SELECT w.started_at as date, SUM(ws.weight * ws.reps) as value
      FROM workouts w
      JOIN workout_exercises we ON w.id = we.workout_id
      JOIN workout_sets ws ON we.id = ws.workout_exercise_id
      WHERE we.exercise_id = ? AND w.finished_at IS NOT NULL AND ws.is_completed = 1
      GROUP BY w.id
      ORDER BY w.started_at ASC
      ''',
      variables: [Variable.withInt(exerciseId)],
    );
    
    final rows = await query.get();
    return rows.map((r) => ChartDataPoint(
      date: DateTime.parse(r.read<String>('date')),
      value: r.read<double>('value'),
    )).toList();
  }
}

class ChartDataPoint {
  final DateTime date;
  final double value;

  const ChartDataPoint({required this.date, required this.value});
}

/// Combined workout exercise with its exercise details.
class WorkoutExerciseWithDetails {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;

  const WorkoutExerciseWithDetails({
    required this.workoutExercise,
    required this.exercise,
  });
}
