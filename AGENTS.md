# AGENTS.md

## Build & Codegen

```bash
# Run codegen after editing tables, DAOs, providers, or models with annotations
dart run build_runner build --delete-conflicting-outputs

# Lint (target: 0 issues)
flutter analyze

# Run tests
flutter test
```

Generated `.g.dart` files are **committed to git** — not in `.gitignore`. Always regenerate and commit them after changing annotated source files.

## Architecture

- **Single Flutter app** (not a monorepo). Dart SDK `^3.11.5`.
- **Feature-first Clean Architecture**: `lib/features/<name>/presentation/` for screens, providers, widgets.
- **7 feature modules**: `exercises`, `workout`, `history`, `routines`, `profile`, `home`, `analytics`.
- **State**: Riverpod (`flutter_riverpod` + `riverpod_annotation`). Providers live in `presentation/providers/`.
- **Navigation**: GoRouter `StatefulShellRoute.indexedStack` — 4 bottom tabs (Home, Analytics, History, Profile). Center FAB launches workout. Routines accessed from Home, not a separate tab.
- **Database**: Drift (SQLite) — 8 tables, 4 DAOs. In-memory constructor `AppDatabase.forTesting(e)` available.

## Database

- 8 tables: `Exercises`, `WorkoutTemplates`, `WorkoutTemplateExercises`, `Workouts`, `WorkoutExercises`, `WorkoutSets`, `PersonalRecords`, `UserSettings`.
- Seed data at `assets/data/exercises.json` (~300 exercises). Loaded once on first launch.
- Schema version: 1. Migrations defined in `MigrationStrategy` — add new `onUpgrade` cases for future versions.
- The `databaseProvider` global (`lib/main.dart:36`) **throws `UnimplementedError`** unless overridden in `ProviderScope`. All code accesses the DB via `ref.read(databaseProvider)`.

## Testing

- Only 1 smoke test exists (`test/widget_test.dart`). It constructs `App()` directly (no `ProviderScope`/database override) — **this pattern fails if the widget tree reads `databaseProvider`**.
- For real tests, use `ProviderScope` with `databaseProvider.overrideWithValue(AppDatabase.forTesting(...))` and an in-memory connection.

## Style

- Dark-first Material 3 theme. Colors in `lib/app/theme/colors.dart`, typography in `lib/app/theme/app_theme.dart`.
- Lint: `flutter_lints` (`analysis_options.yaml`). Target: `flutter analyze` with 0 errors, 0 warnings.

## Reference Docs

- `specs/01_mvp_product_spec.md` — full product spec (flows, ERD, UI, QA)
- `specs/memory/change-log.md` — implementation history
- `specs/memory/decisions/001-mvp-scope.md` — accepted architecture decisions
- `stitch_swiftlift_workout_interface/high_performance_athletic/DESIGN.md` — design system spec
