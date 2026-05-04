import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'routine_dao.g.dart';

/// Data access object for workout templates (routines).
@DriftAccessor(tables: [WorkoutTemplates, WorkoutTemplateExercises, Exercises])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  // ─── Template CRUD ───────────────────────────────────────

  /// Create a new routine, returns its ID.
  Future<int> createRoutine(String name, {String? notes}) {
    return into(workoutTemplates).insert(
      WorkoutTemplatesCompanion.insert(
        name: name,
        notes: Value(notes),
      ),
    );
  }

  /// Update a routine's name/notes.
  Future<void> updateRoutine(int id, {String? name, String? notes}) {
    return (update(workoutTemplates)..where((t) => t.id.equals(id))).write(
      WorkoutTemplatesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a routine and its exercises.
  Future<void> deleteRoutine(int id) async {
    await (delete(workoutTemplateExercises)..where((t) => t.templateId.equals(id))).go();
    await (delete(workoutTemplates)..where((t) => t.id.equals(id))).go();
  }

  /// Get all routines, newest first.
  Future<List<WorkoutTemplate>> getAllRoutines() {
    return (select(workoutTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Watch all routines (reactive).
  Stream<List<WorkoutTemplate>> watchAllRoutines() {
    return (select(workoutTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Get a single routine by ID.
  Future<WorkoutTemplate> getRoutineById(int id) {
    return (select(workoutTemplates)..where((t) => t.id.equals(id))).getSingle();
  }

  // ─── Template Exercises ──────────────────────────────────

  /// Add an exercise to a routine.
  Future<int> addExerciseToRoutine({
    required int templateId,
    required int exerciseId,
    required int orderIndex,
    int? supersetGroupId,
    int targetSets = 3,
    int targetReps = 10,
    double targetWeight = 0.0,
  }) {
    return into(workoutTemplateExercises).insert(
      WorkoutTemplateExercisesCompanion.insert(
        templateId: templateId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
        supersetGroupId: Value(supersetGroupId),
        targetSets: Value(targetSets),
        targetReps: Value(targetReps),
        targetWeight: Value(targetWeight),
      ),
    );
  }

  /// Remove an exercise from a routine.
  Future<void> removeExerciseFromRoutine(int templateExerciseId) {
    return (delete(workoutTemplateExercises)
          ..where((t) => t.id.equals(templateExerciseId)))
        .go();
  }

  /// Get all exercises in a routine with exercise details.
  Future<List<RoutineExerciseWithDetails>> getRoutineExercises(int templateId) async {
    final query = select(workoutTemplateExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(workoutTemplateExercises.exerciseId)),
    ])
      ..where(workoutTemplateExercises.templateId.equals(templateId))
      ..orderBy([OrderingTerm.asc(workoutTemplateExercises.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) {
      return RoutineExerciseWithDetails(
        templateExercise: row.readTable(workoutTemplateExercises),
        exercise: row.readTable(exercises),
      );
    }).toList();
  }

  /// Update target sets/reps/weight/orderIndex/supersetGroupId for a template exercise.
  Future<void> updateTemplateExercise(int id, {
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? orderIndex,
    int? supersetGroupId,
  }) {
    return (update(workoutTemplateExercises)..where((t) => t.id.equals(id))).write(
      WorkoutTemplateExercisesCompanion(
        targetSets: targetSets != null ? Value(targetSets) : const Value.absent(),
        targetReps: targetReps != null ? Value(targetReps) : const Value.absent(),
        targetWeight: targetWeight != null ? Value(targetWeight) : const Value.absent(),
        orderIndex: orderIndex != null ? Value(orderIndex) : const Value.absent(),
        supersetGroupId: supersetGroupId != null ? Value(supersetGroupId) : const Value.absent(),
      ),
    );
  }

  /// Duplicate a routine with all its exercises.
  Future<int> duplicateRoutine(int id) async {
    final original = await getRoutineById(id);
    final exercises = await getRoutineExercises(id);

    final newId = await createRoutine('${original.name} (Copy)', notes: original.notes);
    for (final re in exercises) {
      await addExerciseToRoutine(
        templateId: newId,
        exerciseId: re.exercise.id,
        orderIndex: re.templateExercise.orderIndex,
        supersetGroupId: re.templateExercise.supersetGroupId,
        targetSets: re.templateExercise.targetSets,
        targetReps: re.templateExercise.targetReps,
        targetWeight: re.templateExercise.targetWeight,
      );
    }
    return newId;
  }
}

/// Combined template exercise with its exercise details.
class RoutineExerciseWithDetails {
  final WorkoutTemplateExercise templateExercise;
  final Exercise exercise;

  const RoutineExerciseWithDetails({
    required this.templateExercise,
    required this.exercise,
  });
}
