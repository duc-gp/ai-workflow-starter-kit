# AI Workflow Starter Kit

Drop the AI-assisted development workflow into any existing repo in one command: a curated set of Claude Code skills (grilling, spec/ticket generation, TDD, code review, bug diagnosis, triage, and more), the 13-chapter guide those skills are distilled from, plus the `CLAUDE.md` instructions that tell the agent which skill fits which situation — so you describe the problem, not the tooling.

You still type a command for the heavyweight steps (`/grill-with-docs`, `/to-spec`, `/implement`, …) — those are deliberately user-invoked upstream. What the kit removes is having to *know* that; the agent recognises the situation and tells you which one to run. See [Which skills run themselves](#which-skills-run-themselves).

New to this and want the story of how it came to be and where the pieces actually come from? See [`BACKGROUND.md`](BACKGROUND.md) — self-contained, no need to have the rest of the parent project around.

## Quick start

Clone this kit somewhere, then point `init.sh` at the repo you want to set up:

```bash
git clone https://github.com/duc-gp/ai-workflow-starter-kit.git ai-workflow-starter
ai-workflow-starter/init.sh /path/to/your/existing/repo
```

Or clone it straight into the target repo and run it from there:

```bash
cd /path/to/your/existing/repo
git clone https://github.com/duc-gp/ai-workflow-starter-kit.git .ai-workflow-starter
./.ai-workflow-starter/init.sh .
rm -rf .ai-workflow-starter   # one-time setup tool, safe to remove afterwards
```

With no argument, `init.sh` targets the current directory. Add `--verify` to check an already-set-up repo without installing anything.

The kit is public — just clone it.

## What it does

1. **Installs 23 skills, project-scoped** (not global) via the official [`skills`](https://skills.sh) installer, so they're committed to the repo and every teammate who clones it gets the same toolset:
   `ask-matt`, `code-review`, `codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grill-with-docs`, `grilling`, `handoff`, `implement`, `improve-codebase-architecture`, `prototype`, `research`, `resolving-merge-conflicts`, `setup-matt-pocock-skills`, `tdd`, `to-spec`, `to-tickets`, `triage`, `wayfinder`, `teach`, `claude-handoff`, `git-guardrails-claude-code`, `setup-pre-commit`.

   `grilling` and `handoff` are the interview/handoff primitives that `grill-with-docs`, `wayfinder`, `triage`, and `ask-matt` invoke internally by name — they're needed even though nothing routes to them directly.
2. **Wires up `CLAUDE.md`** with the routing logic: which skill fits which situation, which ones the agent may start itself, and which ones it must ask you to run. Safe to run against a repo that already has its own `CLAUDE.md` — the block is appended, clearly delimited, and re-running the script is a no-op once it's there (delete the delimited block to force a refresh).
3. **Bundles `development-guide/`** — the 13-chapter guide this whole workflow is distilled from — into the target repo, so the reasoning behind the workflow travels with it instead of staying behind on one machine. Skipped if `development-guide/` already exists there (non-destructive; delete it and re-run to refresh).
4. **Installs one custom skill, `explain-workflow`** — not from Matt Pocock's repo, built specifically for this kit. It explains *why* the workflow does something, or helps you figure out what to do next when you're not sure, grounded in the bundled guide. Just ask "why" or say you're stuck; no command needed. It's deliberately the one workflow skill the agent can start on its own — someone who is confused shouldn't have to know a command name to get unstuck.

It does not touch git remotes, does not push anything, and does not require the target repo to be a git repo (it'll warn, not fail).

## After running it

```bash
cd /path/to/your/existing/repo
claude
```

Then type **`/setup-matt-pocock-skills`** — a one-time, per-repo setup that configures your issue tracker, triage labels, and where domain docs (glossary, ADRs) live. See [Picking an issue tracker](#picking-an-issue-tracker) for the one question worth thinking about.

This step is required, not optional. Until it's done there's no `docs/agents/issue-tracker.md`, and the tracker-touching skills have nowhere to publish — so the `CLAUDE.md` block tells the agent to check for that file and stop and ask you to run setup if it's missing, rather than guessing a tracker.

From there, describe what you want in plain language:

- *"This form submits twice"* → bug diagnosis, started automatically.
- *"Why did you just clear the conversation?"* / *"I don't know what to do here"* → `explain-workflow`, started automatically, explains the reasoning instead of just proceeding.
- *"Add a dark-mode toggle to the settings page"* → the agent judges it non-trivial and says to run `/grill-with-docs` first; after grilling it either implements directly or points you at `/to-spec` → `/to-tickets` → `/implement`.
- *"40 open issues, no idea where to start"* → the agent points you at `/triage`.
- *"I want to rework the whole billing system"* → the agent points you at `/wayfinder`, since that's big and foggy.

Optionally, once set up, ask Claude to also run `setup-pre-commit` (type checks + lint + tests on every commit) and `git-guardrails-claude-code` (blocks `push --force`, `reset --hard`, etc. before they run). Both of those the agent can start itself.

## Which skills run themselves

Most of Matt Pocock's skills ship with `disable-model-invocation: true` in their frontmatter. That's upstream and deliberate: those skills publish to your issue tracker, restructure planned work, or eat an entire session, so they're meant to be conscious decisions rather than something an agent starts on your behalf. The kit doesn't override it (except for its own `explain-workflow`) — overriding would be undone by the next `npx skills update` anyway.

**Automatic** — just describe the situation:
`diagnosing-bugs` · `resolving-merge-conflicts` · `tdd` · `prototype` · `research` · `code-review` · `domain-modeling` · `codebase-design` · `grilling` · `setup-pre-commit` · `git-guardrails-claude-code` · `explain-workflow`

**Type these yourself** — the agent tells you which one and why:
`/setup-matt-pocock-skills` · `/grill-with-docs` · `/wayfinder` · `/to-spec` · `/to-tickets` · `/implement` · `/triage` · `/claude-handoff` · `/ask-matt` · `/teach` · `/improve-codebase-architecture` · `/handoff`

Run `init.sh /path/to/repo --verify` to print this split for the skills actually installed in a given repo.

## Picking an issue tracker

`/setup-matt-pocock-skills` asks where specs and tickets should live, and writes the answer to `docs/agents/issue-tracker.md`. Every downstream skill (`/to-spec`, `/to-tickets`, `/triage`, `/wayfinder`) reads that file instead of hardcoding a tracker — the skills are tracker-agnostic by design, and there's no adapter to write.

**Recommended default: local markdown.** Specs and tickets become files under `.scratch/<feature>/` in the repo. No API tokens, no CLI to install, works identically with GitHub, GitLab, Bitbucket, or no remote at all. It's also what Pocock uses for his own demo repo. **Commit `.scratch/`** — then the tickets travel with the code that satisfies them, and teammates can read them without any tracker at all.

Reach for a shared tracker (GitHub Issues, GitLab, Jira, Linear, beads, anything) for one reason only: unattended agents or teammates needing to *pull* work from a shared queue. That's the case AFK loops are built around. If that's not you, local markdown is strictly less friction.

Either way it's a one-word answer during setup, and switching later means editing one markdown file.

## Windows note

The installer puts each skill in `.agents/skills/<name>/` and symlinks it into `.claude/skills/<name>/`, so agent tools share one copy. Those symlinks get committed.

Git on Windows checks symlinks out as **plain text files containing the target path** unless `core.symlinks=true` or Developer Mode is enabled. When that happens, Claude Code finds no skills and says nothing about why. If a teammate on Windows reports the workflow doing nothing:

```bash
init.sh . --verify              # reports BROKEN for each unresolved link
git config core.symlinks true
git checkout -- .claude
```

## Updating the skill set later

```bash
npx skills update              # update installed skills to latest, from inside the target repo
npx skills@latest add mattpocock/skills -y -s <name>   # add one that was skipped
npx skills list                                        # see what's installed
init.sh /path/to/repo --verify                         # check a repo without reinstalling
```

`explain-workflow` isn't managed by `npx skills` (it's custom to this kit, not from Matt Pocock's repo) — re-run `init.sh` to refresh it or `development-guide/` to their latest bundled version.

The bundled `development-guide/` is maintained and updated over time — the maintainer processes new source material and publishes updated guide chapters to this repo. Re-run `init.sh` at any time, or just `git pull` this kit, to pull the latest version into your target repo.

## Why project scope, not global

Project-scoped skills are the right call once more than one person touches a repo, because everyone gets the same versioned toolset instead of whatever happens to be installed on their own machine — see [`BACKGROUND.md`](BACKGROUND.md) for where that guidance comes from. If you're the only person who will ever touch a given repo, installing globally once (`npx skills@latest add mattpocock/skills -g`) and skipping this kit entirely is a reasonable alternative — this kit exists for the "hand this repo to someone else, or work across machines" case.

## License

This kit (guide, scripts, explain-workflow skill, CLAUDE.md.template) is MIT licensed. The skills installed by `init.sh` come from github.com/mattpocock/skills and are governed by their own license.