#!/usr/bin/env bash
set -euo pipefail

# Installs the claude-sprint-pipeline agents and skills into your personal
# Claude Code directory (~/.claude by default; override with CLAUDE_DIR).

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

echo "Installing agents -> $CLAUDE_DIR/agents/"
for agent in "$SCRIPT_DIR/agents/"*.agent.md; do
  base="$(basename "$agent")"
  if [ -f "$CLAUDE_DIR/agents/$base" ]; then
    echo "  overwriting existing $base"
  fi
  cp "$agent" "$CLAUDE_DIR/agents/$base"
  echo "  installed $base"
done

echo "Installing skills -> $CLAUDE_DIR/skills/"
for skill in "$SCRIPT_DIR/skills/"*/; do
  name="$(basename "$skill")"
  mkdir -p "$CLAUDE_DIR/skills/$name"
  if [ -f "$CLAUDE_DIR/skills/$name/SKILL.md" ]; then
    echo "  overwriting existing $name"
  fi
  cp "$skill/SKILL.md" "$CLAUDE_DIR/skills/$name/SKILL.md"
  echo "  installed /$name"
done

echo
echo "Done. Installed:"
echo "  Agents: Project Plan, Sprint Plan"
echo "  Skills: /implement-project, /implement-sprint, /expand-sprints"
echo
echo "Recommended next step: merge templates/global-conventions.md into your"
echo "~/.claude/CLAUDE.md (PROJECT_STATUS tracking + branch workflow), then"
echo "restart Claude Code to pick up the new agents and skills."
