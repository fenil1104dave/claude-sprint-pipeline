---
name: implement-sprint
description: Execute one sprint from the Plan/ folder produced by the Sprint Plan agent — create the sprint branch, develop each feature via parallel worktree agents, merge serially, review against the plan, raise one PR, and record status. Use when the user says "implement sprint 3", "execute the sprint", "run sprint N", or when /implement-project delegates a sprint. Requires an approved plan (Plan/Overview.md) — not for ad-hoc coding outside a planned sprint.
---

# Implement Sprint

Execute a single sprint from `Plan/Sprint-<n>/`: sprint branch off main, one feature agent per feature file (max 3 concurrent, dependency-ordered), serialized merges, plan-conformance review, one PR, status updates. **You orchestrate; feature agents implement.** Track phases with TodoWrite.

**Single-writer rule:** only you (the main thread) write `Plan/Sprint-<n>/EXECUTION.md` and `.claude/PROJECT_STATUS.md`. Feature agents never touch status files.

## Phase 0 — Pre-flight (every guard must pass; fail loudly, never proceed past a failed guard)

1. Read `.claude/PROJECT_STATUS.md` and `Plan/Overview.md` (no `Plan/` → stop: the Sprint Plan agent must run first). Target sprint = the argument if given, else the first sprint not marked completed.
2. **Resume check:** if `Plan/Sprint-<n>/EXECUTION.md` already exists, this is a resume — skip features marked `merged`, continue the rest from the ledger. Never redo merged work.
3. Guards, in order:
   - **Repo:** a git repository with a main/master branch exists at the project root. Greenfield exception: Sprint 1 containing a `project-setup` feature may initialize the repo as that feature's first task. No repo and no project-setup feature → stop and report.
   - **Approval:** the root PRD (path in Overview.md / HANDOFF.md) carries `Status: Approved` — else stop.
   - **Prior sprints:** every sprint named in this sprint's Dependencies is completed and its PR **merged to main** (verify with `gh pr list`/`git log`, plus PROJECT_STATUS). An unmerged PR → stop: "Merge PR #… first."
   - **Blockers:** any open `PTD-<n>` item or `UNVALIDATED` integration gating this sprint → resolve now via AskUserQuestion (offer the recorded recommended default). Write the resolution back into the root PRD's entry (`Resolved: <choice>, <date>`) and the affected feature files before starting. Never guess a deferred decision.
   - **Detail level:** if this sprint's feature files are stubs, expand first — invoke the `Sprint Plan` agent in **Expand mode** (Agent tool, `run_in_background: false`) for this sprint and the next (keep the plan two ahead), then re-read the expanded files.

## Phase 1 — Branch & Ledger

1. `git checkout main && git pull` (global workflow).
2. Create the sprint branch named in `Sprint-<n>.md` (`feat/sprint-<n>-<sprint-slug>`). If it already exists (resume), check it out.
3. Create/refresh `Plan/Sprint-<n>/EXECUTION.md`: a table — feature slug, branch, status (`pending` / `in-progress` / `merged` / `blocked`), estimate, actual notes. Update it after **every** state change; on a crash, the next run resumes from this ledger.
4. Ensure `.worktrees/` is in `.gitignore` (add it if missing).

## Phase 2 — Spawn Feature Agents (max 3 concurrent)

Build the schedule from each feature file's `Depends on:` line. A feature is **eligible** when all its dependencies are `merged`. Keep at most 3 agents running; as one merges, spawn the next eligible feature.

For each eligible feature:

1. Create its branch and worktree yourself — agents never improvise git setup:
   `git worktree add .worktrees/<feature-slug> -b feat/sprint-<n>/<feature-slug> <sprint-branch>`
2. Mark it `in-progress` in EXECUTION.md, then spawn a general-purpose agent whose prompt contains this contract:
   - Work ONLY inside `.worktrees/<feature-slug>`, on branch `feat/sprint-<n>/<feature-slug>`.
   - Inputs: the feature file path, its PRD/TRD module paths (from the feature file's Traceability), the prototype path if the feature file names a screen, and the project's root `CLAUDE.md` conventions.
   - Implement exactly what the feature file specifies — nothing more. On finding a gap, ambiguity, or missing decision in the spec: STOP and report it in the final message; never invent scope — that is the plan's job, not yours.
   - Definition of done: every acceptance criterion passes its listed Verification step; tests written and passing; build clean — all **inside the worktree**.
   - Commit small and focused per root CLAUDE.md conventions; never add AI-attribution lines.
   - Do NOT merge, do NOT touch other branches or worktrees, do NOT write EXECUTION.md or PROJECT_STATUS. Final message: what was built, test results, files touched, any deviations or open questions.
3. If an agent reports a spec gap: a plan ambiguity or unrecorded decision → AskUserQuestion with a recommended default, write the answer back into the PRD/feature file, then SendMessage the agent to continue. A question the PRD/TRD already answers → answer it yourself from the documents.

## Phase 3 — Serial Merge Protocol (one merge at a time, always)

When an agent reports done:

1. Verify in the worktree yourself: tests pass, build clean. Failures → SendMessage the agent back with the output; it is not done.
2. If the sprint branch moved since the feature branched, rebase the feature branch onto the sprint branch first; then merge it into the sprint branch.
3. **Conflicts:** resolve using both features' detail files when the conflict lies inside their declared scopes. A conflict touching code *outside both features' scopes* → investigate; if intent is still ambiguous, AskUserQuestion. Never resolve a conflict by guessing intent.
4. After every merge: run the full test suite and build on the sprint branch — must be green before the next merge begins.
5. Update EXECUTION.md (`merged`, with actual-effort notes), then clean up: `git worktree remove .worktrees/<feature-slug>` and delete the feature branch.
6. Spawn newly unblocked features (back to Phase 2) until all features are merged.

## Phase 4 — Sprint Review

With every feature merged:

1. Review the full sprint diff against three sources: the sprint file's Definition of Done, every feature's acceptance criteria and Verification steps, and the PRD/TRD module files this sprint draws from — hunting missing items and unhandled edge cases.
2. Findings that trace to a plan gap or an unrecorded decision → AskUserQuestion with a recommended default, write the resolution back into the PRD/feature file, then implement the fix. Clear in-scope misses → fix directly on the sprint branch.
3. Final gate: full test suite passes, build clean.

## Phase 5 — PR & Record

1. Raise **one PR**: sprint branch → main, per the global workflow (`gh` CLI; concise description; no AI-attribution lines anywhere).
2. Finalize EXECUTION.md: per-feature estimate-vs-actual notes — calibration data for future planning.
3. Update `.claude/PROJECT_STATUS.md` (newest on top): sprint completed pending PR review (PR link), which sprint is next, and any open blockers for upcoming sprints.
4. If the next sprint's features are stubs, say so in your report — `/expand-sprints` (or the next `/implement-project` run) will expand them.
5. **Stop.** Report the PR link and a per-feature summary. The user reviews and merges; the next sprint must start from a main that contains this one.

## Ground Rules

- Never proceed past a failed guard; never start a sprint whose dependency sprints aren't merged to main.
- One merge at a time; the sprint branch must be green after every merge.
- Feature agents never invent scope and never write status files; you never let a spec gap be resolved silently — it goes to the user and back into the documents.
- Crash-safe: EXECUTION.md is the source of truth for resume; re-runs skip merged features and continue the rest.
- All scope questions resolve back into the PRD/plan files first, then into code — the documents and the code never fork.
