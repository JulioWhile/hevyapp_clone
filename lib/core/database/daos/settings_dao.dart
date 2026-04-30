import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// Data access object for user settings and personal records.
@DriftAccessor(tables: [UserSettings, PersonalRecords, Exercises, Workouts])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // ─── Settings ────────────────────────────────────────────

  /// Get user settings (single row).
  Future<UserSetting> getSettings() {
    return (select(userSettings)..limit(1)).getSingle();
  }

  /// Watch settings (reactive).
  Stream<UserSetting> watchSettings() {
    return (select(userSettings)..limit(1)).watchSingle();
  }

  /// Update unit system and convert existing weights.
  Future<void> updateUnitSystem(String newUnitSystem) async {
    await transaction(() async {
      final currentSettings = await getSettings();
      if (currentSettings.unitSystem == newUnitSystem) return;

      // Conversion multipliers
      // kg to lbs: 2.20462
      // lbs to kg: 0.453592
      final multiplier = newUnitSystem == 'imperial' ? 2.20462 : 0.453592;

      // 1. Convert logged sets weights
      await customUpdate(
        'UPDATE workout_sets SET weight = weight * ?',
        variables: [Variable.withReal(multiplier)],
        updates: {attachedDatabase.workoutSets},
      );

      // 2. Convert template target weights
      await customUpdate(
        'UPDATE workout_template_exercises SET target_weight = target_weight * ?',
        variables: [Variable.withReal(multiplier)],
        updates: {attachedDatabase.workoutTemplateExercises},
      );

      // 3. Convert PRs (only weight and volume, not reps)
      await customUpdate(
        "UPDATE personal_records SET value = value * ? WHERE record_type IN ('max_weight', 'max_volume')",
        variables: [Variable.withReal(multiplier)],
        updates: {attachedDatabase.personalRecords},
      );

      // Finally update the setting itself
      await update(userSettings).write(
        UserSettingsCompanion(unitSystem: Value(newUnitSystem)),
      );
    });
  }

  /// Update default rest timer.
  Future<void> updateRestTimer(int seconds) async {
    await (update(userSettings)).write(
      UserSettingsCompanion(defaultRestTimerSeconds: Value(seconds)),
    );
  }

  // ─── Personal Records ────────────────────────────────────

  /// Get all PRs for an exercise.
  Future<List<PersonalRecord>> getPRsForExercise(int exerciseId) {
    return (select(personalRecords)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]))
        .get();
  }

  /// Get the current PR of a specific type for an exercise.
  Future<PersonalRecord?> getCurrentPR(int exerciseId, String recordType) {
    return (select(personalRecords)
          ..where((t) =>
              t.exerciseId.equals(exerciseId) &
              t.recordType.equals(recordType))
          ..orderBy([(t) => OrderingTerm.desc(t.value)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get all latest PRs grouped by exercise (for profile screen).
  Future<List<PRWithExercise>> getAllLatestPRs() async {
    // Get the max weight PR for each exercise.
    final query = select(personalRecords).join([
      innerJoin(exercises, exercises.id.equalsExp(personalRecords.exerciseId)),
    ])
      ..where(personalRecords.recordType.equals('max_weight'))
      ..orderBy([OrderingTerm.desc(personalRecords.value)]);

    final rows = await query.get();

    // Deduplicate by exercise — keep the highest value.
    final seen = <int>{};
    final results = <PRWithExercise>[];
    for (final row in rows) {
      final pr = row.readTable(personalRecords);
      if (!seen.contains(pr.exerciseId)) {
        seen.add(pr.exerciseId);
        results.add(PRWithExercise(
          pr: pr,
          exercise: row.readTable(exercises),
        ));
      }
    }
    return results;
  }

  /// Check and record PRs after a workout.
  /// Returns list of new PRs detected.
  Future<List<NewPR>> checkAndRecordPRs(int workoutId) async {
    final newPRs = <NewPR>[];

    // Get all exercises and their sets from this workout.
    final db = attachedDatabase;
    final workoutExercises = await db.workoutDao.getWorkoutExercises(workoutId);

    for (final we in workoutExercises) {
      final sets = await db.workoutDao.getSetsForExercise(we.workoutExercise.id);
      final completedSets = sets.where((s) => s.isCompleted).toList();
      if (completedSets.isEmpty) continue;

      // ─── Max weight PR ───────────────────────────
      final maxWeight = completedSets
          .map((s) => s.weight)
          .reduce((a, b) => a > b ? a : b);

      if (maxWeight > 0) {
        final currentPR = await getCurrentPR(we.exercise.id, 'max_weight');
        if (currentPR == null || maxWeight > currentPR.value) {
          await into(personalRecords).insert(
            PersonalRecordsCompanion.insert(
              exerciseId: we.exercise.id,
              recordType: 'max_weight',
              value: maxWeight,
              workoutId: workoutId,
              achievedAt: DateTime.now(),
            ),
          );
          newPRs.add(NewPR(
            exerciseName: we.exercise.name,
            recordType: 'max_weight',
            value: maxWeight,
            previousValue: currentPR?.value,
          ));
        }
      }

      // ─── Max reps at weight PR ───────────────────
      final maxReps = completedSets
          .map((s) => s.reps)
          .reduce((a, b) => a > b ? a : b);

      if (maxReps > 0) {
        final currentPR = await getCurrentPR(we.exercise.id, 'max_reps');
        if (currentPR == null || maxReps > currentPR.value) {
          await into(personalRecords).insert(
            PersonalRecordsCompanion.insert(
              exerciseId: we.exercise.id,
              recordType: 'max_reps',
              value: maxReps.toDouble(),
              workoutId: workoutId,
              achievedAt: DateTime.now(),
            ),
          );
          newPRs.add(NewPR(
            exerciseName: we.exercise.name,
            recordType: 'max_reps',
            value: maxReps.toDouble(),
            previousValue: currentPR?.value,
          ));
        }
      }

      // ─── Max volume (single set) PR ──────────────
      final maxVolume = completedSets
          .map((s) => s.weight * s.reps)
          .reduce((a, b) => a > b ? a : b);

      if (maxVolume > 0) {
        final currentPR = await getCurrentPR(we.exercise.id, 'max_volume');
        if (currentPR == null || maxVolume > currentPR.value) {
          await into(personalRecords).insert(
            PersonalRecordsCompanion.insert(
              exerciseId: we.exercise.id,
              recordType: 'max_volume',
              value: maxVolume,
              workoutId: workoutId,
              achievedAt: DateTime.now(),
            ),
          );
          newPRs.add(NewPR(
            exerciseName: we.exercise.name,
            recordType: 'max_volume',
            value: maxVolume,
            previousValue: currentPR?.value,
          ));
        }
      }
    }

    return newPRs;
  }
}

/// PR with exercise details.
class PRWithExercise {
  final PersonalRecord pr;
  final Exercise exercise;

  const PRWithExercise({required this.pr, required this.exercise});
}

/// A newly detected PR.
class NewPR {
  final String exerciseName;
  final String recordType;
  final double value;
  final double? previousValue;

  const NewPR({
    required this.exerciseName,
    required this.recordType,
    required this.value,
    this.previousValue,
  });

  String get displayType => switch (recordType) {
        'max_weight' => 'Weight',
        'max_reps' => 'Reps',
        'max_volume' => 'Volume',
        _ => recordType,
      };
}
