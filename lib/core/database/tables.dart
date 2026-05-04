import 'package:drift/drift.dart';

// ─── Exercises ─────────────────────────────────────────────
/// Pre-built + custom exercise library.
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get primaryMuscleGroup => text()();
  TextColumn get secondaryMuscleGroups => text().nullable()();
  TextColumn get equipment => text()();
  TextColumn get exerciseType => text()();
  TextColumn get gifUrl => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Workout Templates (Routines) ──────────────────────────
/// Saved workout routines that can be reused.
class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exercises within a workout template.
class WorkoutTemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get supersetGroupId => integer().nullable()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
  RealColumn get targetWeight => real().withDefault(const Constant(0.0))();
}

// ─── Workouts ──────────────────────────────────────────────
/// A completed or in-progress workout session.
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().nullable().references(WorkoutTemplates, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

/// An exercise performed within a workout (ordered, supports supersets).
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get supersetGroupId => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Individual set within a workout exercise.
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId => integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  RealColumn get rpe => real().nullable()();
  IntColumn get rir => integer().nullable()();
}

// ─── Personal Records ──────────────────────────────────────
/// Auto-detected personal records per exercise.
class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get recordType => text()(); // max_weight, max_reps, max_volume, estimated_1rm
  RealColumn get value => real()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  DateTimeColumn get achievedAt => dateTime()();
}

// ─── User Settings ─────────────────────────────────────────
/// App settings (single row, created on first launch).
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();
  IntColumn get defaultRestTimerSeconds => integer().withDefault(const Constant(90))();
  TextColumn get themeMode => text().withDefault(const Constant('dark'))();
}
