---
name: implement-project
description: Execute a planned project sprint-by-sprint from the Plan/ folder — finds the next sprint due, keeps the rolling-wave plan two sprints ahead, runs the sprint via /implement-sprint, and stops at that sprint's PR for the user's review. Use when the user says "implement the project", "continue the project", "run the next sprint", or after merging a sprint PR to start the next one. Requires Plan/Overview.md from the Sprint Plan agent.
---

# Implement Project

Serial orchestrator over the whole `Plan/` folder. One invocation executes **at most one sprint**, then stops at its PR. Sprints run strictly in dependency order — never in parallel — because each sprint's branch must be cut from a main that already contains its predecessors, and the user reviews one sprint PR at a time (global workflow). The user's PR review is the pace-setter: merge, re-run `/implement-project`, repeat.

## Phase 0 — Locate State

1. Read `.claude/PROJECT_STATUS.md` and `Plan/Overview.md`. No `Plan/` folder → stop: the Sprint Plan agent must produce a plan first (and before that, the Project Plan agent a PRD/TRD).
2. Determine where the project stands:
   - A sprint is **in progress** (its `EXECUTION.md` exists but isn't complete) → that sprint is the target; `/implement-sprint` will resume it from the ledger.
   - Otherwise the **lowest-numbered sprint not completed** (per Overview.md's table and PROJECT_STATUS) is the target, respecting Overview.md's dependency graph.
   - **Every sprint completed and merged** → go to Phase 3.
3. **PR gate:** if the previous sprint's PR is still open (check `gh pr list` / `git log` on main), stop and report: "Merge PR #… first, then re-run /implement-project." Never start sprint N+1 from a main that lacks sprint N.

## Phase 1 — Keep the Plan Two Ahead

If the target sprint or the one after it consists of stubs, invoke the `Sprint Plan` agent in **Expand mode** (Agent tool, `run_in_background: false`) to expand the next two unexecuted sprints against the current codebase before executing anything. If Expand mode flags that a change requires PRD/TRD updates first, surface that to the user and stop — the documents lead, the code follows.

## Phase 2 — Execute One Sprint

Invoke the `/implement-sprint` skill (Skill tool) for the target sprint and let it run through its phases to the PR. When it stops, relay its report in your final message: the PR link, the per-feature summary, and the next step — "merge the PR, then re-run /implement-project for Sprint <n+1>."

## Phase 3 — Wrap Up (all sprints done)

When every sprint is completed and its PR merged:

1. Write the project-complete entry to `.claude/PROJECT_STATUS.md`: all sprints with themes and PR links (where recorded).
2. Summarize open items so nothing rots silently: any `PTD-<n>` entries still open in the PRD, `UNVALIDATED` flags never spiked, and deferred improvements noted in EXECUTION ledgers.

## Ground Rules

- One sprint per invocation; never skip the PR gate; never reorder sprints against Overview.md's dependency graph.
- All status writing happens here or inside `/implement-sprint` — never in feature agents.
- If any pre-flight guard inside `/implement-sprint` fails, relay the failure and stop — don't work around a guard.
