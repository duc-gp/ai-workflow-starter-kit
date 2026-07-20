# AI Workflow Starter Kit

Drop the AI-assisted development workflow into any existing repo in one command: a curated set of Claude Code skills (grilling, spec/ticket generation, TDD, code review, bug diagnosis, triage, and more) plus the `CLAUDE.md` instructions that make them fire automatically from plain-language requests — no commands to learn.

New to this and want the story of how it came to be and where the pieces actually come from? See [`BACKGROUND.md`](BACKGROUND.md) — self-contained, no need to have the rest of the parent project around.

## Quick start

Clone this kit somewhere, then point `init.sh` at the repo you want to set up:

```bash
git clone <this-repo-url> ai-workflow-starter
ai-workflow-starter/init.sh /path/to/your/existing/repo
```

Or clone it straight into the target repo and run it from there:

```bash
cd /path/to/your/existing/repo
git clone <this-repo-url> .ai-workflow-starter
./.ai-workflow-starter/init.sh .
rm -rf .ai-workflow-starter   # one-time setup tool, safe to remove afterwards
```

With no argument, `init.sh` targets the current directory.

## What it does

1. **Installs 21 skills, project-scoped** (not global) via the official [`skills`](https://skills.sh) installer, so they're committed to the repo and every teammate who clones it gets the same toolset:
   `ask-matt`, `code-review`, `codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grill-with-docs`, `implement`, `improve-codebase-architecture`, `prototype`, `research`, `resolving-merge-conflicts`, `setup-matt-pocock-skills`, `tdd`, `to-spec`, `to-tickets`, `triage`, `wayfinder`, `teach`, `claude-handoff`, `git-guardrails-claude-code`, `setup-pre-commit`.
2. **Wires up `CLAUDE.md`** with the routing logic that makes those skills trigger from plain language instead of slash commands. Safe to run against a repo that already has its own `CLAUDE.md` — the block is appended, clearly delimited, and re-running the script is a no-op once it's there (delete the delimited block to force a refresh).

It does not touch git remotes, does not push anything, and does not require the target repo to be a git repo (it'll warn, not fail).

## After running it

```bash
cd /path/to/your/existing/repo
claude
```

Then just say **"run setup-matt-pocock-skills"** — a one-time, per-repo setup that configures your issue tracker (GitHub issues, local markdown, Jira, Linear — whatever you tell it), triage labels, and where domain docs (glossary, ADRs) live.

From there, just describe what you want in plain language:

- *"Add a dark-mode toggle to the settings page"* → grilled briefly if non-trivial, then implemented and reviewed.
- *"This form submits twice"* → routed to bug diagnosis.
- *"40 open issues, no idea where to start"* → routed to triage.
- *"I want to rework the whole billing system"* → routed to Wayfinder first, since that's big and foggy.

Optionally, once set up, ask Claude to also run `setup-pre-commit` (type checks + lint + tests on every commit) and `git-guardrails-claude-code` (blocks `push --force`, `reset --hard`, etc. before they run).

## Updating the skill set later

```bash
npx skills update              # update installed skills to latest, from inside the target repo
npx skills@latest add mattpocock/skills -y -s <name>   # add one that was skipped
npx skills list                                        # see what's installed
```

## Why project scope, not global

Project-scoped skills are the right call once more than one person touches a repo, because everyone gets the same versioned toolset instead of whatever happens to be installed on their own machine — see [`BACKGROUND.md`](BACKGROUND.md) for where that guidance comes from. If you're the only person who will ever touch a given repo, installing globally once (`npx skills@latest add mattpocock/skills -g`) and skipping this kit entirely is a reasonable alternative — this kit exists for the "hand this repo to someone else, or work across machines" case.
