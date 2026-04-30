# 01 — MVP Product Spec: Workout Tracker App

> Generated: 2026-04-29 | Status: DRAFT — awaiting user approval

---

## 1. Product Manager — Feature Breakdown

### MVP (V1) — Local-Only, Core Logging

| # | Feature | Priority |
|---|---------|----------|
| 1 | **Active workout logging** (add exercises, log sets: weight/reps, mark complete) | P0 |
| 2 | **Pre-built exercise library** (~300 exercises, searchable by name/muscle group) | P0 |
| 3 | **Workout history** (chronological list, tap for detail) | P0 |
| 4 | **Workout templates/routines** (create, reuse, edit) | P0 |
| 5 | **Previous performance** (show last workout's weight/reps as ghost text) | P0 |
| 6 | **Rest timer** (on-screen countdown, auto-start on set completion) | P1 |
| 7 | **PR tracking** (auto-detect max weight, max reps, max volume per exercise) | P1 |
| 8 | **Unit selection** (kg/lbs, switchable in settings) | P1 |
| 9 | **Dark mode** (default theme) | P1 |
| 10 | **Workout summary screen** (shown after finishing: volume, duration, PRs hit) | P1 |

### V2 — Cloud & Social

| # | Feature |
|---|---------|
| 1 | User accounts & auth (email + social login) |
| 2 | Cloud sync (PostgreSQL backend, offline-first sync) |
| 3 | Progress charts (volume over time, 1RM trends) |
| 4 | Body measurements tracking |
| 5 | Custom exercise creation |
| 6 | Workout notes & exercise notes |
| 7 | Social features (share workouts, follow users) |
| 8 | Export data (CSV/JSON) |
| 9 | Push notifications & reminders |
| 10 | Apple Watch / Wear OS companion |

### Core User Flows (MVP)

```
Flow 1 — Quick Start Workout:
  Home → "Start Empty Workout" → Add Exercise(s) → Log Sets → Finish → Summary

Flow 2 — Routine-Based Workout:
  Home → Pick Routine → Start Workout (pre-filled) → Log Sets → Finish → Summary

Flow 3 — Create Routine:
  Routines Tab → "New Routine" → Add Exercises → Configure defaults → Save

Flow 4 — Browse History:
  History Tab → Scroll list → Tap workout → See detail (exercises, sets, volume)

Flow 5 — Check PRs:
  Profile Tab → PR section → See records by exercise
```

---

## 2. Architect — System Design

### Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Framework** | Flutter (Dart) | Already initialized, cross-platform Android+iOS |
| **Local DB** | **Drift** (SQLite wrapper) | Type-safe, relational, migrations, perfect for offline-first. Mobile equivalent of PostgreSQL. |
| **State Mgmt** | **Riverpod** (flutter_riverpod + riverpod_annotation) | Compile-safe, testable, no context dependency |
| **Navigation** | **GoRouter** | Declarative routing, deep links, shell routes for bottom nav |
| **Architecture** | Feature-first Clean Architecture | Separation of concerns, testable, scalable |
| **Code Gen** | build_runner + freezed + riverpod_generator | Immutable models, generated providers |
| **DI** | Riverpod (built-in) | No extra DI framework needed |

### Why Drift over PostgreSQL for MVP

PostgreSQL is a **server-side** database — it cannot run embedded on a phone. For offline-first mobile, the right choice is **Drift (SQLite)**:
- Same relational mental model (tables, foreign keys, joins)
- Type-safe queries with Dart code generation
- Built-in migration system
- When V2 adds cloud sync, the **server** will use PostgreSQL

### Project Structure

```
lib/
├── app/                          # App-level config
│   ├── app.dart                  # MaterialApp + theme
│   ├── router.dart               # GoRouter config
│   └── theme/
│       ├── app_theme.dart        # ThemeData
│       └── colors.dart           # Color palette
├── core/                         # Shared utilities
│   ├── database/
│   │   ├── app_database.dart     # Drift database class
│   │   ├── app_database.g.dart   # Generated
│   │   └── tables/               # Table definitions
│   ├── constants/
│   ├── extensions/
│   └── utils/
├── features/
│   ├── exercises/                # Exercise library
│   │   ├── data/                 # Repository implementations
│   │   ├── domain/               # Models, repository interfaces
│   │   └── presentation/        # Screens, widgets, providers
│   ├── workout/                  # Active workout
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── history/                  # Workout history
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── routines/                 # Templates
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/                  # Settings, PRs
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### Entity Relationship Diagram

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────────┐
│   Exercise   │     │  WorkoutTemplate  │     │ WorkoutTemplateExer. │
│──────────────│     │───────────────────│     │──────────────────────│
│ id (PK)      │◄────│ id (PK)           │◄────│ id (PK)              │
│ name         │     │ name              │     │ template_id (FK)     │
│ muscle_group │     │ notes             │     │ exercise_id (FK)     │
│ equipment    │     │ created_at        │     │ order_index          │
│ type         │     │ updated_at        │     │ target_sets          │
│ is_custom    │     └───────────────────┘     │ target_reps          │
└──────┬───────┘                               │ target_weight        │
       │                                       └──────────────────────┘
       │
       │         ┌───────────────┐     ┌──────────────────┐     ┌─────────────┐
       │         │    Workout    │     │ WorkoutExercise   │     │ WorkoutSet  │
       │         │───────────────│     │──────────────────│     │─────────────│
       └────────►│ id (PK)       │◄────│ id (PK)          │◄────│ id (PK)     │
                 │ template_id?  │     │ workout_id (FK)  │     │ we_id (FK)  │
                 │ name          │     │ exercise_id (FK) │     │ set_number  │
                 │ started_at    │     │ order_index      │     │ set_type    │
                 │ finished_at   │     │ notes            │     │ weight      │
                 │ duration_secs │     └──────────────────┘     │ reps        │
                 │ notes         │                               │ is_done     │
                 └───────────────┘                               └─────────────┘

┌──────────────────┐     ┌──────────────────┐
│ PersonalRecord   │     │  UserSettings    │
│──────────────────│     │──────────────────│
│ id (PK)          │     │ id (PK)          │
│ exercise_id (FK) │     │ unit_system      │
│ record_type      │     │ rest_timer_secs  │
│ value            │     │ theme_mode       │
│ workout_id (FK)  │     └──────────────────┘
│ achieved_at      │
└──────────────────┘
```

---

## 3. Backend Engineer — Database Schema (Drift/SQLite)

### Tables (Drift Dart definitions)

```dart
// exercises table
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get primaryMuscleGroup => text()();         // chest, back, legs, etc.
  TextColumn get secondaryMuscleGroups => text().nullable()(); // JSON array
  TextColumn get equipment => text()();                  // barbell, dumbbell, machine, cable, bodyweight, other
  TextColumn get exerciseType => text()();               // compound, isolation
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// workouts table
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().nullable().references(WorkoutTemplates, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

// workout_sets table
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId => integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))(); // normal, warmup, dropset, failure
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}
```

### Seed Data Strategy

Pre-built exercise library (~300 exercises) will be:
- Stored as a JSON asset file (`assets/data/exercises.json`)
- Seeded into the local DB on first app launch
- Versioned — future updates can add exercises via migration

---

## 4. Frontend Engineer — UI Structure

### Navigation (Bottom Tab Bar + Workout Overlay)

```
Bottom Tabs:
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│  Home    │ History  │  (+)     │Exercises │ Profile  │
│  (feed)  │ (list)   │ (start)  │ (search) │ (PRs)    │
└──────────┴──────────┴──────────┴──────────┴──────────┘

Active Workout = Full-screen overlay (persists across tab switches)
```

### Screen Inventory

| Screen | Description |
|--------|-------------|
| **HomeScreen** | Dashboard: quick start button, recent workouts, streak counter |
| **HistoryScreen** | Chronological workout list with date headers |
| **WorkoutDetailScreen** | Read-only view of a completed workout |
| **ActiveWorkoutScreen** | THE core screen — logging sets in real-time |
| **ExercisePickerSheet** | Bottom sheet: search + filter exercises, multi-select |
| **ExerciseLibraryScreen** | Full exercise browser (by muscle group) |
| **ExerciseDetailScreen** | Exercise info + history for that exercise |
| **RoutinesScreen** | List of saved templates |
| **RoutineEditorScreen** | Create/edit a routine template |
| **ProfileScreen** | Settings, unit toggle, PR list |
| **WorkoutSummaryScreen** | Post-workout: duration, volume, PRs hit |

### Key Widget Components

| Widget | Purpose |
|--------|---------|
| `ExerciseCard` | During active workout — shows exercise name + set rows |
| `SetRow` | Inline: set#, previous (ghost), weight input, reps input, ✓ checkbox |
| `RestTimerBar` | Floating countdown bar at top of active workout |
| `WorkoutSummaryCard` | In history list — workout name, date, exercise count, volume |
| `MuscleGroupChip` | Filter chip for exercise search |
| `PRBadge` | 🏆 indicator when a new PR is hit |

---

## 5. UX Designer — Speed Optimization

### Design Principles (Hevy-inspired)

1. **Dark-first UI** with high contrast — easy on gym lighting
2. **Minimal taps to log a set**: tap weight → type → tap reps → type → tap ✓ (3 taps + 2 inputs)
3. **Ghost text from last workout** — pre-fills previous weight/reps so user can just tap ✓
4. **Auto-start rest timer** when checking off a set
5. **"+ Set" duplicates last row** — one tap to add another set with same weight/reps
6. **Number pad input** — large touch targets, decimal support for weight
7. **Swipe-to-delete** on set rows
8. **Haptic feedback** on set completion and PR detection

### Color Palette (Dark, Premium, Hevy-inspired)

```
Background:       #0D0D0F (near-black)
Surface:          #1A1A1E (card backgrounds)
Surface Elevated: #242428 (modals, sheets)
Primary:          #4F8CFF (vibrant blue — actions, CTAs)
Primary Variant:  #3A6FD8 (pressed states)
Accent:           #22C55E (success green — completed sets, PRs)
Warning:          #F59E0B (rest timer)
Error:            #EF4444 (delete actions)
Text Primary:     #F0F0F0
Text Secondary:   #8A8A8E
Text Tertiary:    #4A4A4E (ghost text / previous performance)
Border:           #2A2A2E
```

### Typography

- **Font**: Inter (Google Fonts) — clean, readable, modern
- **Set row numbers**: Monospace variant for alignment (tabular figures)

---

## 6. QA Engineer — Edge Cases & Testing

### Critical Edge Cases

| # | Edge Case | Mitigation |
|---|-----------|------------|
| 1 | App killed mid-workout | Auto-save to DB on every set change |
| 2 | Empty workout (0 exercises) | Disable "Finish" button, show prompt |
| 3 | 0 weight (bodyweight exercises) | Allow — track reps only |
| 4 | Extremely large numbers (999kg) | Cap at 9999, validate input |
| 5 | Duplicate exercise in workout | Allowed — common pattern |
| 6 | Switching units with existing data | Convert stored values, confirm dialog |
| 7 | Deleting exercise with history | Soft delete — preserve historical data |
| 8 | Back button during active workout | Confirm dialog "Discard workout?" |
| 9 | Very long workout (3+ hours) | Timer handles large durations |
| 10 | First launch — empty state | Onboarding hints, empty state illustrations |

### Testing Strategy

| Type | Scope | Tools |
|------|-------|-------|
| **Unit** | PR calculation, volume math, unit conversion | `flutter_test` |
| **Widget** | SetRow, ExerciseCard, RestTimer | `flutter_test` |
| **Integration** | Full workout flow: start → add → log → finish | `integration_test` |
| **DB** | Migrations, seed data, CRUD operations | Drift test utilities |

---

## 7. Implementation Plan — Waves

### Wave 1: Foundation (Orchestrator-only, no multi-boxing)
- Project structure, dependencies, Drift DB setup, theme, navigation shell
- **Why single-threaded**: Everything touches `pubspec.yaml` and root files — high conflict risk

### Wave 2: Core Features (Multi-boxing: 3 workers)
- **WS-A**: Exercise library (DB seed, browse/search screen, exercise detail)
- **WS-B**: Active workout (logging screen, set rows, rest timer)
- **WS-C**: Workout history (list screen, detail screen, summary)

### Wave 3: Templates & Polish (Multi-boxing: 2 workers)
- **WS-D**: Routines (create/edit templates, start from template)
- **WS-E**: PRs + Settings (PR detection, profile screen, unit toggle)

---

## Open Decisions for User

1. **Set types**: Support warmup/dropset/failure in MVP, or just "normal" sets?
2. **RPE/RIR tracking**: Include rate-of-perceived-exertion field, or defer to V2?
3. **Superset support**: Allow grouping exercises as supersets in MVP?
