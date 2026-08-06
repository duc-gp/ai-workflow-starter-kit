# AI Workflow Starter Kit

## What it is

A cloneable kit for setting up AI-assisted development in any target project. It bundles a 13-chapter development guide ("the workflow, explained") and an `init.sh` setup script that installs the matching set of skills into the target repo. See `README.md` for full usage.

## Structure

- `development-guide/` — 13 chapters distilling the AI-driven development workflow from Matt Pocock's material, plus the `explain-workflow` skill that grounds the kit in this guide.
- `init.sh` — idempotent installer: copies the guide into the target repo, installs the skill set (project-scoped), and wires up `CLAUDE.md`. Safe to re-run — it skips whatever's already present.
- `skills/explain-workflow/` — a custom skill (not from Matt Pocock's repo) that explains *why* the workflow does something.
- `CLAUDE.md.template` — the routing block appended to the target repo's `CLAUDE.md`.

See `README.md` for the full story.