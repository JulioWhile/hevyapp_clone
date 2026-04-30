# Spec Memory Datastore

Shared working memory for parallel implementation.

## Structure
- `decisions/`: accepted architecture/product decisions (immutable after accepted)
- `workstreams/`: mutable progress by workstream (workers write here)
- `open-questions/`: unresolved decisions needing input
- `change-log.md`: append-only major updates

## Rules
- Keep entries short and structured.
- One owner edits one workstream file at a time.
- Decision records are immutable after accepted.
