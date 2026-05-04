# Change Log

## 2026-04-29 — Project Kickoff
- Initialized Flutter project (Dart SDK ^3.11.5)
- Installed all dependencies (Riverpod, GoRouter, Drift, freezed, fl_chart, google_fonts)
- Created Drift schema: 8 tables, 4 DAOs
- Created exercise seed data (~300 exercises)

## 2026-04-29 — Wave 1: Foundation
- Dark-first Material 3 theme
- GoRouter navigation shell (4 bottom tabs + center FAB)
- Database initialization and auto-seeding in `main.dart`
- `databaseProvider` global provider pattern
- `flutter analyze`: 0 issues

## 2026-04-29 — Wave 2: Core Features
- Exercise library (search, filter chips by muscle group, list, detail with charts)
- Active workout (full state management, set rows with ghost text, rest timer, exercise picker)
- Workout history (month-grouped list, detail screen with stats)
- Previous performance context cards

## 2026-04-29 — Wave 3: Routines + PRs + Settings
- Routines CRUD (list, editor with drag-reorder, start workout from template)
- PR auto-detection on workout completion (max_weight, max_reps, max_volume)
- Settings (kg/lbs toggle with automatic weight conversion, rest timer presets)
- Workout Summary (celebration header, stats, PR announcements, exercise breakdown)
- Create Exercise screen
- Profile screen with stats
- Analytics screen with charts
- Home screen (greeting, active workout banner, routines, recent activity)
- `flutter analyze`: 0 errors, 0 warnings
- **MVP COMPLETE**

## 2026-05-02 — Memory Setup
- Created `specs/memory/` folder for cross-agent progress tracking
- Created `AGENTS.md` with build commands, architecture notes, and testing gotchas

## 2026-05-02 — Phase 4: Enhancements
- **Set numbering fix**: Normal sets restart at 1 after warmup (W, 1, 2, 3 instead of W, 2, 3, 4)
- **Delete sets**: Added visible trash icon on each set row (swipe-to-delete still works)
- **Per-exercise rest timer**: Chip in exercise header shows timer setting (OFF, 30s–5m). OFF disables auto-start on set completion
- **Superset UI**: Toggle in exercise picker, amber-bordered grouped cards with "SUPERSET" label, superset IDs flow from routines
- **Warm-up auto-calcs**: Switching set type to warmup auto-fills weight as 50% of max normal set weight
- **Rest timer sound**: Beep plays on timer completion via `audioplayers`
- **Secondary muscle search**: Exercise filtering now matches primary OR secondary muscle groups
- **Animations**: Page transition theme, rest timer red pulse when ≤10s, set row staggered fade-in
- `flutter analyze`: 0 errors, 0 warnings
