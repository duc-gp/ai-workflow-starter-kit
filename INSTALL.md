# Install — instructions for an AI agent

You've been asked to install the AI Workflow Starter Kit into a repo. Do exactly the steps below, nothing more.

## Before you start

`init.sh` needs Node, for `npx`. Check with `node -v`. If it's missing, stop and tell the user to install Node from <https://nodejs.org> first — don't try to work around it.

## 1. Work out the target repo

The **target** is the repo being set up, not this kit.

- Kit cloned *inside* the target repo → the target is the directory containing this clone.
- Kit cloned somewhere else → the target is the repo the user is working in. Ask if that isn't obvious.

## 2. Run the installer

```bash
<path-to-this-kit>/init.sh <path-to-target-repo>
```

It installs the skills project-scoped, appends a delimited block to the target's `CLAUDE.md`, copies `development-guide/` across, and installs the `explain-workflow` skill. It's idempotent — safe to re-run, it skips whatever is already present.

It ends by printing a verification report. Relay anything it flags as `MISSING` or `BROKEN`.

## 3. Delete this clone

```bash
rm -rf <path-to-this-kit>
```

The kit is a one-time carrier — nothing in it needs to stay. Do this **before** committing: the clone carries its own `.git`, so git would otherwise record it as an embedded repo.

## 4. Commit

Commit the installed files in the target repo — e.g. `Add AI workflow starter kit`.

## 5. Tell the user what happens next

Both of these, in order:

1. **Restart the Claude Code session** — `/exit`, then `claude`. Skills load only at session start, so the newly installed ones aren't visible until then. You can't do this step for them.
2. **In the fresh session, run `/setup-matt-pocock-skills`.** Required, once per repo — it configures the issue tracker, triage labels, and domain-doc layout. On the tracker question, **local markdown** is the recommended answer: specs and tickets become files under `.scratch/` in the repo, with no API tokens and no CLI to install. Committing `.scratch/` keeps tickets alongside the code that satisfies them.

Don't run `/setup-matt-pocock-skills` yourself and don't follow its instructions by hand — it's marked `disable-model-invocation` upstream, so only the user can start it.
