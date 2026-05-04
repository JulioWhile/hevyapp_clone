import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'exercise_dao.g.dart';

/// Data access object for exercises.
@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase> with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  /// Get all exercises, ordered by name.
  Future<List<Exercise>> getAllExercises() {
    return (select(exercises)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  /// Search exercises by name (case-insensitive).
  Future<List<Exercise>> searchExercises(String query) {
    return (select(exercises)
          ..where((t) => t.name.lower().like('%${query.toLowerCase()}%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Filter exercises by muscle group.
  Future<List<Exercise>> getByMuscleGroup(String muscleGroup) {
    return (select(exercises)
          ..where((t) => t.primaryMuscleGroup.equals(muscleGroup))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Filter exercises by muscle group (primary or secondary).
  Future<List<Exercise>> getByAnyMuscleGroup(String muscleGroup) {
    final escaped = '"$muscleGroup"';
    return (select(exercises)
          ..where((t) =>
              t.primaryMuscleGroup.equals(muscleGroup) |
              t.secondaryMuscleGroups.like('%$escaped%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Filter exercises by muscle group (primary or secondary) and search query.
  Future<List<Exercise>> searchByAnyMuscleGroup(String query, String muscleGroup) {
    final escaped = '"$muscleGroup"';
    return (select(exercises)
          ..where((t) =>
              (t.primaryMuscleGroup.equals(muscleGroup) |
                  t.secondaryMuscleGroups.like('%$escaped%')) &
              t.name.lower().like('%${query.toLowerCase()}%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Filter exercises by equipment type.
  Future<List<Exercise>> getByEquipment(String equipment) {
    return (select(exercises)
          ..where((t) => t.equipment.equals(equipment))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get a single exercise by ID.
  Future<Exercise> getById(int id) {
    return (select(exercises)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Get distinct muscle groups (primary + secondary) present in the DB.
  Future<List<String>> getDistinctMuscleGroups() async {
    // Get all distinct primary groups.
    final primaryQuery = selectOnly(exercises, distinct: true)
      ..addColumns([exercises.primaryMuscleGroup]);
    final primaryRows = await primaryQuery.get();
    final groups = primaryRows
        .map((row) => row.read(exercises.primaryMuscleGroup)!)
        .toSet();

    // Collect secondary groups from all exercises.
    final allExercises = await select(exercises).get();
    for (final ex in allExercises) {
      if (ex.secondaryMuscleGroups != null) {
        try {
          final list = json.decode(ex.secondaryMuscleGroups!) as List<dynamic>;
          for (final g in list) {
            groups.add(g.toString());
          }
        } catch (_) {}
      }
    }

    return groups.toList()..sort();
  }

  /// Watch all exercises (reactive stream).
  Stream<List<Exercise>> watchAllExercises() {
    return (select(exercises)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Create a new custom exercise.
  Future<int> createCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    required String equipment,
    required String exerciseType,
  }) {
    return into(exercises).insert(
      ExercisesCompanion.insert(
        name: name,
        primaryMuscleGroup: primaryMuscleGroup,
        equipment: equipment,
        exerciseType: exerciseType,
        isCustom: const Value(true),
      ),
    );
  }
}

