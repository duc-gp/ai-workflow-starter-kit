#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="<!-- ai-development-workflow:start -->"
MARKER_END="<!-- ai-development-workflow:end -->"

SKILLS=(
  ask-matt code-review codebase-design diagnosing-bugs domain-modeling
  grill-with-docs implement improve-codebase-architecture prototype research
  resolving-merge-conflicts setup-matt-pocock-skills tdd to-spec to-tickets
  triage wayfinder teach claude-handoff git-guardrails-claude-code setup-pre-commit
  grilling handoff
)

VERIFY_ONLY=false
TARGET_ARG=""

for arg in "$@"; do
  case "$arg" in
    --verify)
      VERIFY_ONLY=true
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: init.sh [TARGET_DIR] [--verify]

  TARGET_DIR   Repo to set up (default: current directory).
  --verify     Don't install anything; just check an already-set-up repo and
               report which skills resolve, which are auto-routed vs typed by
               hand, and whether /setup-matt-pocock-skills has been run.
USAGE
      exit 0
      ;;
    -*)
      echo "Unknown option: $arg (try --help)" >&2
      exit 1
      ;;
    *)
      TARGET_ARG="$arg"
      ;;
  esac
done

TARGET_DIR="$(cd "${TARGET_ARG:-$(pwd)}" && pwd)"

# Report on an installed setup: broken symlinks, missing skills, which skills
# the agent can start on its own, and whether the repo has been configured.
verify_setup() {
  local auto="" manual="" ok=0 missing=0 broken=0 skill link real

  echo ""
  echo "== Verifying $TARGET_DIR =="
  echo ""

  for skill in "${SKILLS[@]}" explain-workflow; do
    real="$TARGET_DIR/.agents/skills/$skill"
    link="$TARGET_DIR/.claude/skills/$skill"

    if [ ! -f "$real/SKILL.md" ]; then
      echo "  MISSING  $skill — no .agents/skills/$skill/SKILL.md"
      missing=$((missing + 1))
      continue
    fi

    if [ ! -d "$link" ]; then
      echo "  BROKEN   $skill — .claude/skills/$skill does not resolve to a directory"
      broken=$((broken + 1))
      continue
    fi

    if grep -q '^disable-model-invocation: true' "$real/SKILL.md"; then
      manual="$manual /$skill"
    else
      auto="$auto $skill"
    fi
    ok=$((ok + 1))
  done

  if [ "$broken" -gt 0 ]; then
    echo ""
    echo "  Broken links are almost always Windows: git checks symlinks out as"
    echo "  plain text files unless core.symlinks=true or Developer Mode is on."
    echo "  Fix with:  git config core.symlinks true && git checkout -- .claude"
  fi

  echo ""
  echo "  $ok skill(s) installed and resolving."
  echo ""
  echo "  Automatic — just describe the situation in plain language:"
  echo "   $auto"
  echo ""
  echo "  Type these yourself (the agent will suggest them, it cannot start them):"
  echo "   $manual"
  echo ""

  if [ -f "$TARGET_DIR/docs/agents/issue-tracker.md" ]; then
    echo "  Repo setup: configured (docs/agents/issue-tracker.md)"
  else
    echo "  Repo setup: NOT CONFIGURED — run /setup-matt-pocock-skills in Claude Code."
    echo "              Until then the tracker-touching skills (/to-spec, /to-tickets,"
    echo "              /triage, /wayfinder) have nowhere to publish."
  fi

  if [ -f "$TARGET_DIR/CLAUDE.md" ] && grep -qF "$MARKER_START" "$TARGET_DIR/CLAUDE.md"; then
    echo "  CLAUDE.md:  workflow block present"
  else
    echo "  CLAUDE.md:  workflow block MISSING — re-run init.sh without --verify"
  fi

  if [ -d "$TARGET_DIR/development-guide" ]; then
    echo "  Guide:      development-guide/ present"
  else
    echo "  Guide:      development-guide/ MISSING — re-run init.sh without --verify"
  fi

  if [ "$missing" -gt 0 ] || [ "$broken" -gt 0 ]; then
    echo ""
    echo "  $missing missing, $broken broken." >&2
    return 1
  fi
}

if [ "$VERIFY_ONLY" = true ]; then
  verify_setup
  exit $?
fi

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

echo ""
echo "== Bundling development-guide/ (background reading for the agent) =="
if [ -d "$TARGET_DIR/development-guide" ]; then
  echo "development-guide/ already exists — leaving it as is."
  echo "(Delete it and re-run this script to refresh it from the kit.)"
else
  cp -r "$SCRIPT_DIR/development-guide" "$TARGET_DIR/development-guide"
  echo "Copied development-guide/ into the target repo."
fi

echo ""
echo "== Installing the explain-workflow skill (custom, not from mattpocock/skills) =="
AGENTS_SKILL_DIR="$TARGET_DIR/.agents/skills/explain-workflow"
CLAUDE_SKILL_LINK="$TARGET_DIR/.claude/skills/explain-workflow"
mkdir -p "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.claude/skills"
rm -rf "$AGENTS_SKILL_DIR" "$CLAUDE_SKILL_LINK"
cp -r "$SCRIPT_DIR/skills/explain-workflow" "$AGENTS_SKILL_DIR"
ln -s ../../.agents/skills/explain-workflow "$CLAUDE_SKILL_LINK"
echo "Installed explain-workflow, symlinked into .claude/skills/ like the other skills."

verify_setup || true

cat <<'EOF'

Done. Next steps:

  1. cd into the repo and run: claude

  2. REQUIRED, once per repo — type this in Claude Code:

         /setup-matt-pocock-skills

     It configures your issue tracker, triage labels, and domain-doc layout.
     Until you run it, /to-spec, /to-tickets, /triage and /wayfinder have
     nowhere to publish, and the agent will stop and ask you to run it.

     On the tracker question, "local markdown" is the recommended answer:
     specs and tickets become files under .scratch/ in this repo. No tokens,
     no CLI, works with GitHub, GitLab, Bitbucket or no remote at all. Commit
     .scratch/ so the tickets travel with the code. Pick a shared tracker
     only if unattended agents or teammates need to pull from a shared queue.

  3. Then describe what you want in plain language. Some skills the agent
     starts on its own (bug diagnosis, TDD, code review, prototypes,
     research). The bigger ones it will suggest and you type — see the two
     lists printed above, or re-print them any time with --verify.

  4. Not sure why the agent is doing something, or not sure what to do next?
     Just ask "why" or say you're stuck. That reaches explain-workflow, which
     explains the reasoning in plain language using the bundled
     development-guide/ instead of silently proceeding.

Optional, worth asking Claude to run once you're set up:
  - setup-pre-commit           — type checks, lint, tests on every commit
  - git-guardrails-claude-code — blocks force-push / reset --hard / etc.

Re-check this setup any time with:  init.sh /path/to/repo --verify
EOF
