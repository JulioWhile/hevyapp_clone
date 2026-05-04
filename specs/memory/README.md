# Memory Datastore

Cross-agent persistent memory for the Hevy app. Read this before starting any work.

## Files

| File | Purpose | When to read |
|------|---------|-------------|
| `progress.md` | Phase tracking with checkboxes, status, known issues, next steps | Start of every session |
| `change-log.md` | Chronological log of all changes | Understanding history |
| `decisions/` | Archived architecture decisions (numbered, ACKNOWLEDGED/SUPERSEDED) | When questioning "why was this done this way" |
| `open-questions/` | Unresolved design questions | Before making major design choices |

## Conventions

- **Update `progress.md` after every completed task** — mark checkboxes, add new issues
- **Append to `change-log.md` after every session** — date-stamped entries
- **Decisions are immutable once accepted** — supersede with a new decision, don't edit old ones
- **Keep it concise** — agents read this for context, not a tutorial
