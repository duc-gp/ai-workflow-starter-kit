# 14. The Home Repo: Running Agents Across All Your Repos

Everything else in this guide prepares, steers, and verifies work in one codebase. Most organizations do not have one codebase — they have a storefront, a payments API, an admin dashboard, and twenty more, and the agent needs to work across all of them. This chapter covers the configuration problem that multi-repo work creates and the pattern that solves it: the **home repo** — a single repo holding all of your skills, steering files, settings, wiki, and custom tooling, that you always run your agent inside. The agent does not need to be launched from the repo it works on; based in the home repo, it reaches every other repo at once and pulls in the context it needs.

Matt Pocock held the pattern back for a long time because he thought it was "kind of just too boring and obvious to post about" — until articulating it made him realize "it actually solves a bunch of problems that people are actually having." Keep that bias named as you read: obvious-seeming techniques can still solve real problems, and the test is whether it works, not whether it feels novel.

## The Problem: Multi-Repo Configuration

Working with agents across multiple repos splits into a solved half and an unsolved half.

**Cross-repo code changes are solved.** Agents can work in multiple directories at once; a single session can produce PRs in several repos. The assumption that the agent must be launched from inside the repo it works on is false — hold that thought for the pattern below.

**Configuration is the unsolved half.** The stuff you want the agent to have in *every* session — skills, tooling, AGENTS.md, wiki links — has two default homes, and both fail at multi-repo scale:

- **Duplicated into every repo.** Skills, tooling, and steering files copied into each of maybe 30–40 repos: "this is a massive pain because you then need to keep all of those skills, all of that tooling in sync across different repos."
- **Dumped into the user directory.** Global/user-level config is where the user adapts the setup to suit how they work — not how the team wants them to work. Shared config living there is invisible, never updated, and falls behind; it is also the wrong ownership boundary for anything team-standard.

## The Pattern: One Home Repo, One Launch Directory

> "The solution that I propose is called the home repo where I have a single repo."

Build one repo containing all of your skills, all steering files, a wiki, "a load of custom tooling," and versioned settings — everything the agent needs in every session, in one place. Then adopt the operating habit:

> "Whenever I run my agent, I am running my agent always inside the home repo."

The home repo is "just like a normal repo" — nothing special about it except what it holds. Running inside it, "the agent… is able to reach the storefront and the payments API and just operate across lots of different repos at once and pull in all of the context that it needs." The principle underneath: **working directory ≠ operating scope**. Where the agent is launched from and what it can reach are two different things, and only the second matters.

The payoff is a single source of truth: skills, tooling, and steering files exist once and never need syncing across repos, while the agent keeps full operating range over all of them.

## Navigation Pointers: Plain Paths in AGENTS.md

Inside the home repo's AGENTS.md (or CLAUDE.md — its main structural file), list **navigation pointers** to all of the important repos you touch day-to-day. A pointer is "literally just a path" — his list includes the skills repo, the course video manager (his hottest repo by commits), the CO5 project, the AI coding crash course repo, sandcastle, and the rest. The agent reads the pointers and pulls what it needs from the target repos.

Three operational properties fall out:

- **Self-provisioning.** On a fresh machine, if a pointed-to repo (sandcastle, say) doesn't exist at its path, the agent "clones it down." Bootstrap cost is cloning the home repo itself; the agent provisions the rest. "It's zero setup basically. It just works on its own."
- **Concurrent agents use worktrees.** If several agents run at once against the same target repo, "it will just use a work tree within that same repo" — with occasional normal worktree cleanup as you go (worktree discipline is [Chapter 7](07-execution.md)).
- **Adding a repo is editing a line.** To bring another repo into the setup, add its path; it joins the same machinery.

**Progressive disclosure at scale.** A flat pointer list works for maybe 20–40 repos; at ~400 it would bloat the top-level file. Group instead — "here are the front-end repos, here are the backend repos, here are the internal repos for internal tooling" — and link the actual repos from those category files. The agent still finds the right repo by simple file-system tactics, without a bloated top-level list. It is the same progressive-disclosure move as [Chapter 3](03-preparing-your-codebase.md)'s CLAUDE.md pointers and [Chapter 10](10-building-skills.md)'s user-invoked skills, applied to the repo list itself.

## Versioned Settings and Private Skills

Two artifacts in the home repo propagate organization-wide when everyone runs the agent from it:

- **A versioned `settings.json`** — a versioned way to configure settings that "spill out over across your entire organization immediately." Configuration changes ride git and reach every session and teammate, instead of living invisible in per-machine user directories.
- **Private skills** — "skills that I do not want to release for whatever reason because they are extremely good and extremely sensitive to my business." They live in the home repo and are available in every single session: the multi-repo version of [Chapter 11](11-team-blueprint.md)'s shared, project-scoped skill set, including the parts too valuable to publish.

## The Personal Wiki

Pocock calls his home repo "my personal wiki": a wiki/ directory holding "an enormous wiki of all of the data that is kind of sensitive to my business… essentially a LLM wiki Karpathy style with a bunch of markdown files of interesting stuff." He queries it and extracts rich data from it that feeds course creation and content creation. The home repo is the obvious spot to house such a wiki — central, versioned, and reachable from every agent session. The instinct is the same as [Chapter 5](05-idea-to-spec.md)'s glossary and [Chapter 9](09-afk-and-parallel-agents.md)'s program.md: dense, agent-readable markdown beats prose in someone's head. (How he generates and keeps the wiki up to date was promised as a future video at recording time.)

## Custom Tooling Grows Organically

"Tooling is absolutely essential": give your agent custom tools that interface with the stuff you use for your business. In his setup, running `wiki help` inside the personal-wiki directory lists the tooling — integrations with Gmail, Slack, Discord, YouTube, GitHub, GCal, AI Hero, Cold Turkey (for focus blocks), publishing one-off HTML reports.

Centralization is what makes the tooling ambitious: since adopting the home repo he has been "much more ambitious with the tooling," and it "grows up organically" in one location into a large ecosystem you can build on. A real cross-tool workflow from his setup: look up a message in Discord, go to the crash-course repo and make a fix there using all of the existing skills, then use the CVM skill inside the course video manager "to go and actually edit the course to make the fix" — one session spanning chat history, code, and the product.

> **Why it works:** The home repo "becomes the tooling that links all different parts of your business up together, not only the code, but giving access to the agent to really rich data sources and rich tooling that it can use to actually do better work." One base gives every session the whole business, not just one repo's slice of it.

## Monorepo First, Home Repo When You Can't

Pocock loves monorepos (former Turborepo DevRel at Vercel): if everything could live in one repo, he would put it all in one repo. But you often can't — especially when you need a mix of public and private repos. "If you can't, and most likely you can't just because of political will, then a home repo is the way to go." Consolidate when you can; centralize when consolidation is blocked.

## Setting Up Your Own

His article "The Home Repo Pattern" ships a setup prompt for adopting the pattern: "It essentially just grills you about your own setup, looks at all of the repos that you need to care about, and then it will start to move things into a home repo." Note the shape — a grilling interview ([Chapter 5](05-idea-to-spec.md)) aimed at your infrastructure: the agent interviews you about your setup, then executes the migration.

## Checklist

- [ ] Stop duplicating skills, tooling, AGENTS.md, and wiki links into every repo — and stop using the user directory as the home for shared or team config.
- [ ] Create one home repo: all skills, all steering files, a wiki, custom tooling, and a versioned settings.json.
- [ ] Always launch agent sessions inside the home repo — working directory ≠ operating scope.
- [ ] Maintain navigation pointers (plain paths) to every day-to-day repo in the home repo's AGENTS.md/CLAUDE.md.
- [ ] Trust the self-provisioning: fresh machines clone missing repos; concurrent agents take worktrees within the same target repo.
- [ ] Beyond ~20–40 repos, group pointers into category files (front-end / backend / internal tooling) that link the raw repos.
- [ ] Keep org-wide settings and private skills in the home repo so every session and teammate gets them.
- [ ] Grow custom tooling — the business integrations — in the home repo and let centralization compound it into your integration hub.
- [ ] Prefer a monorepo when consolidation is possible; adopt the home repo when it isn't (public/private mix, political will).
- [ ] Bootstrap with the article's setup prompt: let the agent grill you about your setup and migrate things in.

## Sources

- The Home Repo Pattern: Run agents across ALL your repos
- The Home Repo Pattern

See also: [Chapter 3](03-preparing-your-codebase.md) for the single-repo placement rules this pattern scales up; [Chapter 5](05-idea-to-spec.md) for the grilling pattern the setup prompt reuses; [Chapter 7](07-execution.md) and [Chapter 9](09-afk-and-parallel-agents.md) for worktree discipline; [Chapter 10](10-building-skills.md) for skill scope and installation; [Chapter 11](11-team-blueprint.md) for the team version of shared skills, settings, and the user-directory anti-pattern.
