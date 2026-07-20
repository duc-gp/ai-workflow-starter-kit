#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(cd "${1:-$(pwd)}" && pwd)"
MARKER_START="<!-- ai-development-workflow:start -->"
MARKER_END="<!-- ai-development-workflow:end -->"

SKILLS=(
  ask-matt code-review codebase-design diagnosing-bugs domain-modeling
  grill-with-docs implement improve-codebase-architecture prototype research
  resolving-merge-conflicts setup-matt-pocock-skills tdd to-spec to-tickets
  triage wayfinder teach claude-handoff git-guardrails-claude-code setup-pre-commit
)

if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found — install Node.js first (https://nodejs.org), then re-run this script." >&2
  exit 1
fi

echo "Target repo: $TARGET_DIR"
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "Warning: $TARGET_DIR does not look like a git repo. Continuing anyway." >&2
fi

echo ""
echo "== Installing skills (project scope, so they're committed and shared with your team) =="
( cd "$TARGET_DIR" && npx skills@latest add mattpocock/skills -y -s "${SKILLS[@]}" )

echo ""
echo "== Wiring up CLAUDE.md =="
CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
TEMPLATE="$SCRIPT_DIR/CLAUDE.md.template"

if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER_START" "$CLAUDE_MD"; then
  echo "CLAUDE.md already has the workflow block — leaving it as is."
  echo "(Delete the block between $MARKER_START and $MARKER_END and re-run this script to refresh it.)"
elif [ -f "$CLAUDE_MD" ]; then
  { echo ""; echo "$MARKER_START"; cat "$TEMPLATE"; echo "$MARKER_END"; } >> "$CLAUDE_MD"
  echo "Appended the workflow block to your existing CLAUDE.md."
else
  { echo "$MARKER_START"; cat "$TEMPLATE"; echo "$MARKER_END"; } > "$CLAUDE_MD"
  echo "Created CLAUDE.md with the workflow block."
fi

cat <<'EOF'

Done. Next steps:
  1. cd into the repo and run: claude
  2. Say: "run setup-matt-pocock-skills" — one-time setup for your issue
     tracker, triage labels, and domain-doc layout.
  3. From then on, just describe what you want in plain language. The
     workflow routes itself: grilling for fuzzy asks, specs/tickets for
     big work, TDD + code review for implementation, triage for backlogs.

Optional, worth asking Claude to run once you're set up:
  - "run setup-pre-commit"          — type checks, lint, tests on every commit
  - "run git-guardrails-claude-code" — blocks force-push / reset --hard / etc.
EOF
