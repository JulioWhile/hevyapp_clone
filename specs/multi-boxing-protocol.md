# Multi-Boxing Protocol — Conventions & Patterns

## Roles
- **Orchestrator**: Main window on the default branch. Plans, creates worktrees, writes kickoff prompts, coordinates merges.
- **Workers**: Separate VS Code windows, one per worktree. Execute implementation against a spec.

## Naming Conventions
- Worktree dirs: `~/projects/{repo}-ws-{a,b,c,...}` (alphabetical per wave)
- Branches: `fix/short-description` or `feat/short-description`
- Workstream memory: `spec/memory/workstreams/WS-{A,B,C,...}-short-name.md`
- Kickoff prompts: `spec/{NN}_wave{N}_kickoff_prompts.md`
- Specs: `spec/{NN}_description_spec.md`
- Integration branch: `dev-staging` (created from default branch, receives merges, FF'd back)

## Worker Trace Convention
Workers MUST append progress entries to their workstream memory file as they complete each task item.

### Format
```markdown
## Progress Trace

### [timestamp] — Item ID: Short description
- **Files changed:** list
- **What was done:** 1-2 sentence summary
- **Verification:** command or assertion used to confirm correctness
- **Status:** DONE | BLOCKED (reason)
```

### Rules
1. Append after EACH item, not in a batch at the end
2. Include the verification step (grep, test command, import check, etc.)
3. If blocked, explain why and continue to the next item
4. Final entry should be a summary: files changed count, test results, branch ready for merge

## Merge Protocol
1. Orchestrator creates `dev-staging` from the default branch
2. Merge in declared order (A → B → C)
3. Resolve conflicts if any (prefer workers' changes for their owned files)
4. Run full test suite on `dev-staging`
5. Fix integration issues on `dev-staging` directly
6. FF or merge `dev-staging` → default branch on user go-ahead

## Check-In Protocol
After all workers report done, orchestrator runs verification greps for each workstream's key artifacts before merging.

## Spec Memory Structure
```
spec/
  memory/
    README.md          — rules
    change-log.md      — append-only major updates
    decisions/         — immutable after accepted
    open-questions/    — unresolved items
    workstreams/       — mutable progress per workstream (workers write here)
```
