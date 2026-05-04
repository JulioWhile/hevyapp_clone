# Decision 001 — MVP Scope

**Date**: 2026-04-29
**Status**: ACCEPTED

## Choices

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Set types | All — normal, warmup, dropset, failure | Full coverage for strength training |
| RPE / RIR | Both fields per set (nullable) | User chooses which to track |
| Supersets | `superset_group_id` on WorkoutExercise | Simple grouping, no extra tables |
| Local DB | Drift (SQLite) | Offline-first MVP; server sync is V2 |
| Units | User-selectable kg/lbs stored in settings | Global preference, auto-convert on toggle |
| State mgmt | Riverpod | Compile-safe, testable, no context needed |
| Navigation | GoRouter `StatefulShellRoute` | IndexedStack preserves tab state |
| Design | Dark-first, Material 3, Hevy-inspired | Premium fitness app aesthetic |
| Rest timer | On-screen countdown, auto-start on set completion | Core UX for rest between sets |
| Platforms | Android + iOS (web as bonus) | Mobile-first fitness app |
| Codegen | build_runner (drift, riverpod, freezed, json) | Generated `.g.dart` files committed to git |
