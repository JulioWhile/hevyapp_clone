# Decision 001 — MVP Scope Answers

**Date**: 2026-04-29
**Status**: ACCEPTED

## Decisions

1. **Set types**: Support all — normal, warmup, dropset, failure
2. **RPE/RIR**: Include both fields per set (nullable, user chooses which to track)
3. **Supersets**: Support via `superset_group_id` on WorkoutExercise — exercises sharing a group ID are in a superset
4. **Local DB**: Drift (SQLite) — PostgreSQL is server-only, comes in V2
5. **Units**: User-selectable kg/lbs stored in settings
6. **State mgmt**: Riverpod
7. **Design**: Dark-first, Hevy-inspired, premium palette
8. **Rest timer**: On-screen countdown, auto-start on set completion
9. **Platforms**: Android + iOS
