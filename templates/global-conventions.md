# Recommended global conventions

The pipeline assumes these conventions. Merge the sections below into your `~/.claude/CLAUDE.md` (adjust to taste — the pipeline reads `PROJECT_STATUS.md` and follows the branch naming exactly as written here).

---

## Progress Tracking Across Sessions

For any multi-feature / multi-sprint project, maintain a persistent project status file so work survives across sessions and parallel sessions can be handed off cleanly.

- **File location:** `.claude/PROJECT_STATUS.md` in the project root (create it if missing).
- **At the start of every session:** read `.claude/PROJECT_STATUS.md` first to understand current project state before doing anything else.
- **After completing each feature / module / sprint:** update `.claude/PROJECT_STATUS.md` before wrapping up. Record:
  - what was completed (feature/module/sprint ID + short description),
  - what is in progress and exactly where it was left off,
  - what is pending / next up,
  - any decisions, blockers, or TODOs that affect future work.
- Keep entries concise and dated. Newest status at the top of each section.

## Feature / Module Workflow

Before starting development of **any new feature or module**:

1. **Read the project status file** (`.claude/PROJECT_STATUS.md`) first.
2. **Pull main** — `git checkout main && git pull` to get the latest base.
3. **Create a sprint branch** off main: `feat/sprint-<n>-<slug>`.
4. **Create sub-branches per feature** off the sprint branch: `feat/sprint-<n>/<slug>`. Implement each feature in its own sub-branch.
5. **Merge sub-branches → sprint branch** as each feature is complete and reviewed. Do not open PRs from sub-branches to `main`.
6. **Raise one PR** from the sprint branch to `main` when all features are merged and the build is clean. The user reviews and merges.

After completing the sprint: **update `.claude/PROJECT_STATUS.md`** before wrapping up.

### Sprint Execution for Planned Projects

When the project has a `Plan/` folder (created by the Sprint Plan agent):

- Execute sprints with `/implement-project` (runs the next due sprint, stops at its PR) or `/implement-sprint <n>` — these skills apply the branch workflow above; don't hand-roll it.
- Keep the rolling-wave plan ahead with `/expand-sprints` after merging a sprint PR.
- If scope changes mid-sprint, update the affected PRD/TRD module files and `Plan/` files **before** implementing the change — the documents lead, the code follows.
