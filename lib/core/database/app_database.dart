import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'daos/exercise_dao.dart';
import 'daos/routine_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/workout_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutTemplates,
    WorkoutTemplateExercises,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    PersonalRecords,
    UserSettings,
  ],
  daos: [ExerciseDao, WorkoutDao, RoutineDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing — accepts an in-memory executor.
  AppDatabase.forTesting(super.e);

  /// DAO accessors.
  @override
  ExerciseDao get exerciseDao => ExerciseDao(this);
  @override
  WorkoutDao get workoutDao => WorkoutDao(this);
  @override
  RoutineDao get routineDao => RoutineDao(this);
  @override
  SettingsDao get settingsDao => SettingsDao(this);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default settings.
        await into(userSettings).insert(
          UserSettingsCompanion.insert(),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here.
      },
    );
  }

  /// Seeds the exercise library from the bundled JSON asset.
  /// Should be called once on first app launch.
  Future<void> seedExercises() async {
    final count = await (selectOnly(exercises)..addColumns([exercises.id.count()]))
        .map((row) => row.read(exercises.id.count()))
        .getSingle();

    if ((count ?? 0) > 0) return; // Already seeded.

    final jsonString = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> exerciseList = json.decode(jsonString) as List<dynamic>;

    await batch((batch) {
      batch.insertAll(
        exercises,
        exerciseList.map((e) {
          final map = e as Map<String, dynamic>;
          return ExercisesCompanion.insert(
            name: map['name'] as String,
            primaryMuscleGroup: map['primaryMuscleGroup'] as String,
            secondaryMuscleGroups: Value(map['secondaryMuscleGroups'] as String?),
            equipment: map['equipment'] as String,
            exerciseType: map['exerciseType'] as String,
          );
        }).toList(),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
