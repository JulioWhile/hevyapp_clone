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
  int get schemaVersion => 3;

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
        if (from < 2) {
          await m.addColumn(exercises, exercises.gifUrl);
          await m.addColumn(exercises, exercises.instructions);
        }
        if (from < 3) {
          await m.addColumn(workouts, workouts.mediaPaths);
        }
      },
    );
  }

  /// Seeds the exercise library from the exerciseDB JSON dataset.
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
          final name = map['name'] as String;
          final targetMuscles = (map['targetMuscles'] as List<dynamic>).cast<String>();
          final secondaryMuscles = (map['secondaryMuscles'] as List<dynamic>).cast<String>();
          final equipments = (map['equipments'] as List<dynamic>).cast<String>();
          final bodyParts = (map['bodyParts'] as List<dynamic>).cast<String>();
          final instructions = map['instructions'] as List<dynamic>?;
          final gifUrl = map['gifUrl'] as String?;

          final primary = _normalizeMuscle(targetMuscles.first);
          final allSecondaries = {...targetMuscles.skip(1), ...secondaryMuscles}
              .map((m) => _normalizeMuscle(m))
              .where((m) => m != primary)
              .toSet()
              .toList();
          final eq = _normalizeEquipment(equipments.first);
          final type = _inferExerciseType(targetMuscles, secondaryMuscles, bodyParts);

          return ExercisesCompanion.insert(
            name: _titleCase(name),
            primaryMuscleGroup: primary,
            secondaryMuscleGroups: Value(allSecondaries.isNotEmpty ? json.encode(allSecondaries) : null),
            equipment: eq,
            exerciseType: type,
            gifUrl: Value(gifUrl),
            instructions: Value(instructions != null ? json.encode(instructions) : null),
          );
        }).toList(),
      );
    });
  }
}

// ─── Seed data mapping helpers ───────────────────────────

const _muscleMap = <String, String>{
  'delts': 'shoulders', 'deltoids': 'shoulders', 'shoulders': 'shoulders',
  'rear deltoids': 'shoulders', 'rotator cuff': 'shoulders',
  'pectorals': 'chest', 'chest': 'chest', 'upper chest': 'chest',
  'latissimus dorsi': 'back', 'lats': 'back', 'back': 'back',
  'upper back': 'back', 'lower back': 'back', 'rhomboids': 'back',
  'trapezius': 'back', 'traps': 'back', 'spine': 'back',
  'levator scapulae': 'back', 'erector spinae': 'back',
  'quadriceps': 'quads', 'quads': 'quads',
  'hamstrings': 'hamstrings', 'groin': 'other',
  'glutes': 'glutes', 'abductors': 'glutes',
  'calves': 'calves', 'soleus': 'calves', 'shins': 'calves',
  'biceps': 'biceps', 'brachialis': 'biceps',
  'triceps': 'triceps',
  'forearms': 'forearms', 'wrist flexors': 'forearms',
  'wrist extensors': 'forearms', 'grip muscles': 'forearms',
  'abdominals': 'core', 'abs': 'core', 'core': 'core',
  'lower abs': 'core', 'obliques': 'core',
  'serratus anterior': 'core', 'hip flexors': 'core',
  'adductors': 'hamstrings', 'inner thighs': 'hamstrings',
  'cardiovascular system': 'cardio',
};

String _normalizeMuscle(String name) {
  return _muscleMap[name.toLowerCase()] ?? name.toLowerCase();
}

const _equipmentMap = <String, String>{
  'barbell': 'barbell', 'ez barbell': 'barbell',
  'olympic barbell': 'barbell', 'trap bar': 'barbell',
  'dumbbell': 'dumbbell',
  'cable': 'cable', 'rope': 'cable',
  'smith machine': 'machine', 'sled machine': 'machine',
  'leverage machine': 'machine', 'assisted': 'machine',
  'kettlebell': 'kettlebell',
  'body weight': 'bodyweight',
  'band': 'band', 'resistance band': 'band',
  'medicine ball': 'other', 'stability ball': 'other',
  'bosu ball': 'other', 'weighted': 'other',
  'hammer': 'other', 'tire': 'other', 'roller': 'other',
  'wheel roller': 'other',
  'stationary bike': 'other', 'elliptical machine': 'other',
  'stepmill machine': 'other', 'skierg machine': 'other',
  'upper body ergometer': 'other',
};

String _normalizeEquipment(String name) {
  return _equipmentMap[name.toLowerCase()] ?? 'other';
}

String _inferExerciseType(
  List<String> targetMuscles,
  List<String> secondaryMuscles,
  List<String> bodyParts,
) {
  final parts = bodyParts.map((p) => p.toLowerCase()).toSet();
  if (parts.contains('cardio')) return 'cardio';
  if (targetMuscles.length > 1 || secondaryMuscles.isNotEmpty) {
    return 'compound';
  }
  return 'isolation';
}

String _titleCase(String s) {
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
