# Progress Tracker

---

## Phase 1: Project Setup & Navigation Shell

**Status:** ✅ Completed  
**Started:** ~2026-04-29  
**Completed:** ~2026-04-29  

### What Was Done

- [x] Initialized Flutter project with Dart SDK ^3.11.5
- [x] Installed dependencies:
  - State: `flutter_riverpod`, `riverpod_annotation`
  - Navigation: `go_router`
  - Database: `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
  - Codegen: `build_runner`, `drift_dev`, `riverpod_generator`, `freezed`, `json_serializable`
  - UI: `google_fonts`, `fl_chart`, `cupertino_icons`
  - Utils: `uuid`, `intl`
- [x] Created directory structure: `lib/core/`, `lib/features/`, `lib/app/`
- [x] Set up Drift schema — 8 tables (Exercises, WorkoutTemplates, WorkoutTemplateExercises, Workouts, WorkoutExercises, WorkoutSets, PersonalRecords, UserSettings)
- [x] Created exercise seed data — ~300 exercises in `assets/data/exercises.json`
- [x] Set up DB initialization with auto-seeding (`main.dart` → `seedExercises()`)
- [x] Created 4 DAOs: ExerciseDao, WorkoutDao, RoutineDao, SettingsDao
- [x] Set up GoRouter navigation shell (`StatefulShellRoute.indexedStack`) — 4 bottom tabs: Home, Analytics, History, Profile
- [x] Center FAB launches workout (Routines accessed from Home, not a separate tab)
- [x] Created dark-first Material 3 theme (`lib/app/theme/`)
- [x] Generated code committed to git (`*.g.dart` files)
- [x] `flutter analyze` passes with 0 issues

### Known Issues

- **Test fragility** — `test/widget_test.dart` constructs `App()` directly without `ProviderScope`/database override. If the widget tree reads `databaseProvider`, the test crashes (`UnimplementedError`). Tests need `ProviderScope` with `databaseProvider.overrideWithValue(AppDatabase.forTesting(...))`.

---

## Phase 2: Core Features

**Status:** ✅ Completed  
**Started:** ~2026-04-29  
**Completed:** ~2026-04-29  

### What Was Done

#### Exercise Library
- [x] Exercise list with search bar
- [x] Muscle group filter chips with colored icons
- [x] Exercise detail screen with fl_chart max weight & volume history
- [x] Exercise DAO: getAll, search, filter by muscle group/equipment, getById

#### Active Workout
- [x] `ActiveWorkoutNotifier` — full lifecycle: start, add exercise, add set, update set, delete set, remove exercise, finish, discard
- [x] `RestTimerNotifier` — start, stop, addTime, countdown; auto-starts on set completion
- [x] Set rows with previous performance ghost text, weight (decimal), reps (integer), set type badge (tap to change), complete checkbox with haptic feedback
- [x] Rest timer bar with progress bar, +30s button, stop button
- [x] Exercise picker bottom sheet (search, multi-select, create exercise shortcut)
- [x] Active workout screen with hero header, exercise cards, sticky footer

#### Workout History
- [x] History list grouped by month/year with date square UI
- [x] Duration + volume metrics per workout
- [x] Workout detail screen with SliverAppBar hero header, stats grid, notes, exercise detail cards with set rows
- [x] Previous performance context cards (last workout + goal) in active workout

### Known Issues

- None documented.

---

## Phase 3: Routines + PRs + Settings

**Status:** ✅ Completed  
**Started:** ~2026-04-29  
**Completed:** ~2026-04-29  

### What Was Done

#### Routines
- [x] RoutineDao: CRUD for templates + exercises, reorder
- [x] Routines list screen with exercise preview, popup menu (edit/delete)
- [x] Routine editor: rename, reorderable exercise list with drag handles, add/remove exercises, template exercise cards with mini steppers (sets/reps)
- [x] Start workout from template (pre-fills exercises + sets based on template targets)
- [x] Create routine dialog

#### Personal Records
- [x] SettingsDao with PR auto-detection: max_weight, max_reps, max_volume
- [x] PR auto-check on workout completion
- [x] Profile screen: workout count, PR list with trophy icons
- [x] Analytics screen: bento grid stats (total volume, new PRs, workouts), weekly frequency bar chart, volume focus by muscle group, PRs list
- [x] Home screen: time-based greeting, active workout banner, today's workout card, quick start, suggested routines, recent activity

#### Settings
- [x] kg/lbs unit toggle with automatic weight conversion (SQL multiplication)
- [x] Default rest timer picker (bottom sheet with presets: 30s–5m)
- [x] Unit conversion handles existing logged sets, PR values, and template targets

#### Workout Summary
- [x] Animated celebration header (checkmark scale, metrics slide)
- [x] Bento grid metrics: duration, volume, total sets
- [x] New PR announcements with trophy icons
- [x] Exercise breakdown list
- [x] Sticky "Done" button

#### Create Exercise
- [x] Form: name, muscle group dropdown, equipment dropdown, exercise type dropdown

### Known Issues

- None documented.

---

## Phase 4: Next Steps

**Status:** ✅ Completed  
**Started:** 2026-05-02  
**Completed:** 2026-05-02  

### What Was Done

#### Superset UI
- [x] Exercise picker sheet: superset toggle when 2+ exercises selected, visual switch + counter
- [x] `addExercise()` accepts optional `supersetGroupId` parameter
- [x] Visual grouping in active workout: amber border, "SUPERSET" label, connected borderRadius between consecutive superset exercises
- [x] Superset IDs transferred from routine templates when starting workout (routines_screen.dart, home_screen.dart)

#### Warm-up Auto-Calculations
- [x] When set type changes to warmup and weight = 0, auto-fills 50% of the heaviest normal set's weight in the same exercise

#### Rest Timer Sound Alerts
- [x] Added `audioplayers` dependency
- [x] Generated 880Hz beep WAV asset (`assets/sounds/timer_beep.wav`)
- [x] Beep plays when rest timer reaches 0

#### Exercise Search by Secondary Muscle Group
- [x] DAO: `getByAnyMuscleGroup()` and `searchByAnyMuscleGroup()` — match primary OR secondary (LIKE query on JSON column)
- [x] DAO: `getDistinctMuscleGroups()` now merges primary and secondary groups
- [x] Provider uses any-muscle-group methods for filtering
- [x] Filter chips automatically include secondary muscle groups

#### Polish Animations
- [x] Page transitions: ZoomPageTransitionsBuilder (Android), CupertinoPageTransitionsBuilder (iOS)
- [x] Rest timer urgency pulse: when ≤10s remaining, bar pulses red with animated opacity
- [x] Set row fade-in: staggered entrance animation (opacity + slide-up per set index)

### Remaining Candidates
- [ ] Write proper tests (widget + integration)
- [ ] Set up CI/CD pipeline
- [ ] Offline-first sync strategy (V2)
- [ ] Workout notes/editing post-completion
- [ ] Export workout data
- [ ] Exercise detail show secondary muscle group chips
