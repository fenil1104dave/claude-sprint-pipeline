---
name: expand-sprints
description: Expand the next two stub sprints in Plan/ into full feature files against the current codebase (rolling-wave planning). Use when the user says "expand sprints", "generate the next sprints", "prepare sprint N", "expand the plan", or right after merging a sprint PR to ready the upcoming sprints. Requires an existing Plan/ folder from the Sprint Plan agent.
---

# Expand Sprints

Thin wrapper over the Sprint Plan agent's **Expand mode**. Maintains the rolling-wave invariant: the next two unexecuted sprints are always fully detailed, expanded against the code that actually exists — not against what the original plan imagined.

## Steps

1. Read `.claude/PROJECT_STATUS.md` and `Plan/Overview.md`. No `Plan/` folder → stop: run the Sprint Plan agent first.
2. Find the next unexecuted sprints — skip any marked completed or in-progress (check `Plan/Sprint-<n>/EXECUTION.md` ledgers and PROJECT_STATUS) — whose detail level in Overview.md is `stub`. Take up to two. If none, report "the next two sprints are already fully expanded" and stop.
3. Invoke the `Sprint Plan` agent (Agent tool, `run_in_background: false`) in **Expand mode**, passing: the target sprint numbers, the `Plan/Overview.md` path, and the `HANDOFF.md` path from `docs/planning/<project-slug>/`. It re-reads the affected PRD/TRD modules and the current codebase, expands each stub into a full feature file (estimates, `Depends on:`, Verification steps adjusted to reality), and updates Overview.md, the sprint files' derived totals, and `estimates.md`.
4. If Expand mode flags that a change alters requirements (PRD/TRD modules must update first), relay exactly which files it named and stop — never let the plan fork away from the PRD.
5. Relay the agent's summary in your final message: which sprints were expanded, estimate changes, and any flags.

## Ground Rules

- Expansion never touches completed or in-progress sprints.
- This skill plans only — no branches, no code, no status entries beyond what Expand mode itself records.
