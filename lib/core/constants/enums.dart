/// Shared enums used across the app.
library;

/// Muscle groups for categorizing exercises.
enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  forearms('Forearms'),
  core('Core'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  calves('Calves'),
  fullBody('Full Body'),
  cardio('Cardio'),
  other('Other');

  const MuscleGroup(this.displayName);
  final String displayName;
}

/// Equipment types for exercises.
enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  machine('Machine'),
  cable('Cable'),
  bodyweight('Bodyweight'),
  kettlebell('Kettlebell'),
  band('Band'),
  plate('Plate'),
  smithMachine('Smith Machine'),
  other('Other');

  const Equipment(this.displayName);
  final String displayName;
}

/// Exercise movement type.
enum ExerciseType {
  compound('Compound'),
  isolation('Isolation'),
  cardio('Cardio');

  const ExerciseType(this.displayName);
  final String displayName;
}

/// Set types during a workout.
enum SetType {
  normal('Normal'),
  warmup('Warmup'),
  dropset('Drop Set'),
  failure('Failure');

  const SetType(this.displayName);
  final String displayName;

  /// Short label shown in the set row UI.
  String get shortLabel => switch (this) {
        SetType.normal => '',
        SetType.warmup => 'W',
        SetType.dropset => 'D',
        SetType.failure => 'F',
      };
}

/// Unit system for weight measurements.
enum UnitSystem {
  metric('kg'),
  imperial('lbs');

  const UnitSystem(this.label);
  final String label;
}
