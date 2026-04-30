# Change Log

## 2026-04-29 — Project Kickoff
- Created MVP product spec (`specs/01_mvp_product_spec.md`)
- Accepted decision 001: MVP scope (all set types, RPE+RIR, supersets, Drift/SQLite, Riverpod, dark theme)

## 2026-04-29 — Wave 1: Foundation Complete
- Dependencies, DB (8 tables), theme, navigation shell, 5 placeholder screens
- `flutter analyze`: 0 issues

## 2026-04-29 — Wave 2: Core Features Complete
- WS-A: Exercise library (DAO, search, filter chips, colored icons)
- WS-B: Active workout (state mgmt, set rows with ghost text, rest timer, exercise picker)
- WS-C: Workout history (reactive list, detail screen with stats)

## 2026-04-29 — Wave 3: Routines + PRs + Settings Complete
- **WS-D: Routines**
  - RoutineDao (CRUD for templates + exercises)
  - Routines list screen with exercise preview
  - Routine editor (add/remove exercises, rename)
  - Start workout from template (pre-fills exercises + sets based on template targets)
  - Exercise picker for routines (bottom sheet, multi-select)

- **WS-E: PRs + Settings**
  - SettingsDao with PR auto-detection (max_weight, max_reps, max_volume)
  - Profile screen with workout count, PR list with trophy icons
  - Settings screen with kg/lbs toggle, default rest timer picker (30s-5m presets)
  - Workout Summary screen (post-workout: celebration header, stats cards, PR announcements, exercise breakdown)
  - Finish Workout → auto-check PRs → show Summary → Done returns home

- `flutter analyze`: 0 errors, 0 warnings
- **MVP COMPLETE** — all P0 and P1 features implemented
