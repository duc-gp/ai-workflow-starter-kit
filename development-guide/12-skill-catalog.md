# 12. Skill Catalog: Every Skill in the System

This chapter is the lookup table for the whole guide: every named skill, command, and harness feature mentioned across the source material, grouped by lifecycle phase, in an identical entry format. Use it while building your own team's skills — each entry records what the thing does, when to use it, how it is invoked, what its instructions contain, and how it has evolved (including what superseded what). The workflow that connects these entries lives in [Chapter 4](04-the-workflow.md); the craft of authoring your own versions lives in [Chapter 10](10-building-skills.md).

## How to read this catalog

Every entry uses the same seven fields:

- **Type** — skill (a reusable instruction set invoked in the harness), harness feature (built into Claude Code or another harness), or infrastructure (scripts, files, and services you build around the harness). A few entries combine these (e.g. "skill + infrastructure") or qualify one with its shipping status ("proto-skill, not yet packaged"; "skill set, in progress") where the sources describe something not yet cleanly in one bucket.
- **What it does** — the one-paragraph job description.
- **When to use** — the trigger condition, and when *not* to use it.
- **Invocation** — how you actually run it.
- **Construction notes** — what its instructions contain, per the sources; the raw material for building your own version.
- **Status & evolution** — renamed, deprecated, replaced by, or current.
- **Source** — the video the entry is grounded in.

The main flow, at a glance:

| Phase | Skill | Output artifact |
| --- | --- | --- |
| Setup (once per repo) | `/setup-mattpocock-skills` | tracker config, triage labels, `context.md` + ADR conventions, CLAUDE.md pointers |
| Idea → shared understanding | `/grill-with-docs` (or `/grill-me`, or `/wayfinder` for big ideas) | grilling transcript, updated `context.md`, ADRs |
| Understanding → destination | `/to-spec` | spec in the issue tracker |
| Destination → journey | `/to-tickets` | tickets sized one context window each |
| Journey → code | `/implement` (calls `/code-review` itself) | commits on the current branch |

### Supersession map

Where the sources evolved, the newer position wins. This table is the authoritative "which skill replaces which":

| Superseded | Replaced by | Why |
| --- | --- | --- |
| Plan mode (for planning features) | `/grill-me` / `/grill-with-docs` | plan mode "will tend to just spit out a plan really early," before shared understanding |
| Multi-phase plan workflow | Ralph loop over spec + tickets | multi-phase plans were onerous to sequence and hard to insert work into |
| `/grill-me` (inside a codebase) | `/grill-with-docs` | grill-me forced re-explaining domain jargon every session; good language was never documented |
| `ubiquitous-language` skill | merged into `/grill-with-docs` | the two were always run together, so they became one skill |
| `/grill-with-docs` (ideas too big for one session) | `/wayfinder` | Wayfinder manages the session-splitting instead of you; "default to Wayfinder" |
| write-a-PRD → `/to-prd` | `/to-spec` | "spec" is the accurate name — a PRD describes the product; non-PRD material was leaking in |
| PRD-to-issues → `/to-issues` | `/to-tickets` | "issues" was biased toward GitHub/Linear terminology; tickets is tracker-neutral |
| `/review` (in progress) | `/code-review` | graduated to blessed status; two-axis subagent design retained |
| TDD skill v1 (interactive steps, red-green-refactor) | TDD skill v2 (reference-only, red-green) | interactive steps broke AFK use; refactoring moved to code review "so you don't overload the implementation" |
| Old `/init` ("never run it") | New experimental `/init` — still prune the output | new version proposes skills and hooks, but still needs a context-paranoid human |
| `needs-triage` label on `/to-spec` / `/to-tickets` output | `ready for agent` label | issues produced by those skills are agent-ready by design |
| Playwright MCP (browser feedback) | Chrome DevTools MCP | community verdict: Playwright MCP "not very good" and context-hoggy |
| Manual "write me a handoff.md" prompt | `/handoff` | used so often it earned packaging as a skill |

> **Warning:** skill renames are not auto-migrated by the installer. `npx skills add` will not turn `to-prd` into `to-spec` — delete the old skills, re-add, then audit your skills folder for stale entries.

## Setup and codebase preparation

These run once per machine or once per repo. The full rationale for a minimal, hook-enforced setup is in [Chapter 3](03-preparing-your-codebase.md).

### Skills installer (`npx skills`)

- **Type:** infrastructure
- **What it does:** Installs a GitHub repo of skills (e.g. mattpocock/skills — 162k stars, 7.5M downloads at recording) into your harness. Works identically for brownfield repos and empty directories. All ~38 skills together consume only ~660 tokens of context because they are user-invoked with short descriptions.
- **When to use:** Any project, team or solo. Choose project-level scope for teams (shared skill set, joint contribution); global scope is fine solo.
- **Invocation:** `npx skills@latest add mattpocock/skills`, select skills, select agents, choose scope, choose **symlink** as install method ("I wouldn't even make a decision here. Just choose symlink."). `npx skills update` grabs all new versions.
- **Construction notes:** Two skill groups exist in the repo: blessed public-facing skills and experimental "other" skills that may be deleted. Skill descriptions are kept "quite short and precise" so they don't leech into context.
- **Status & evolution:** Current. The Vercel skills.sh CLI selection UX is "kind of broken"; Matt Pocock may replace it.
- **Source:** mattpocock/skills: A complete AI Coding workflow, end-to-end

### `/setup-mattpocock-skills` (the setup skill)

- **Type:** skill
- **What it does:** One-time repo setup for the whole skill system: picks your issue tracker (where specs and tickets get saved), configures triage labels, and sets up domain documentation (`context.md` + ADRs, single- or multi-context).
- **When to use:** Once per repo, right after installing the skills.
- **Invocation:** Run the skill in the agent; configure conversationally — "set it up with Jira" (or GitHub, Linear, beads, local markdown, "literally anything").
- **Construction notes:** Writes short links into CLAUDE.md pointing at `docs/agents/issue-tracker`, `docs/agents/triage-labels`, and `docs/agents/domain` — pointers to docs, never inlined content. Single context is right for 99% of repos; multi-context is only for big monorepos needing multiple bounded contexts.
- **Status & evolution:** Current. Answers the recurring question "how do I make the skills work with Jira/Linear/beads?" — you just tell it during setup.
- **Source:** mattpocock/skills: A complete AI Coding workflow, end-to-end

### `/setup-map-skills` (Wayfinder tracker adapter)

- **Type:** skill
- **What it does:** Configures Wayfinder to use an issue tracker other than GitHub (its default substrate for storing parent maps + sub-issue decision tickets). Maps Wayfinder's per-ticket workflow — blocking relationships, ticket types (research / prototype / grilling / task), and per-ticket resolutions written back into the parent — onto your tracker's primitives.
- **When to use:** If you track work in Linear, Jira, or "literally whatever you like" and want Wayfinder maps to live there rather than on GitHub. Matt Pocock's skills are issue-tracker-agnostic; `setup-map-skills` is the adapter that makes the non-GitHub path explicit.
- **Invocation:** Run the skill in the agent, pointing it at your target tracker.
- **Construction notes:** Wayfinder stores its map as a parent issue with typed, blocked sub-issues; on a non-GitHub tracker, `setup-map-skills` translates those constructs (sub-issues, blocked-by links, ticket-type labels) into the tracker's native equivalents. The per-ticket resolutions still accrue back into the parent map whatever the substrate.
- **Status & evolution:** Current; documented in the dedicated Wayfinder explainer.
- **Source:** /wayfinder: Nothing is too big to plan anymore

- **Type:** harness feature (Claude Code)
- **What it does:** Deterministic code that runs at fixed points in the harness's execution cycle. The key event is **PreToolUse**, which fires before a tool call and can block it: a script matches the command, echoes a corrective message, and exits with code 2 — the command is prevented AND the agent is steered to the right alternative (e.g. blocked `npm install foo` retried automatically as `pnpm install foo`).
- **When to use:** Any rule that can be enforced deterministically: CLI substitutions (pnpm over npm), forbidding destructive commands (`git push`), forcing wrapper scripts. Not for non-deterministic guidance — that belongs in skills.
- **Invocation:** Register under the `hooks` property in `settings.json` (project or global), pointing a `Bash` matcher at an executable script. Hooks then fire automatically; all matching hooks for an event run in parallel.
- **Construction notes:** Script pattern: check the command starts with the target CLI → `echo "Use pnpm, not npm"` → `exit 2`. A conversion prompt exists to have Claude turn your CLAUDE.md's deterministic rules into hooks itself (confirm → implement → provide test instructions). Other observed hooks: format-on-edit (prettier after every edit), `npx tsc` interception (redirect to `npm run type check`), git-push blockers kept globally.
- **Status & evolution:** Current, and the recommended replacement for CLI rules in CLAUDE.md — hooks enforce deterministically what instructions only make probable, and free the ~500-instruction budget for real work.
- **Source:** How to actually force Claude Code to use the right CLI (don't use CLAUDE.md); Claude Code tried to improve /init... Is it any better?

### `/init`

- **Type:** harness feature (Claude Code)
- **What it does:** Generates a CLAUDE.md with codebase documentation. The old version asked no questions and produced an enormous file that "will burn tokens, will distract the agent, and will go out of date faster than a pear on a hot day." The new experimental version (behind an environment variable) asks which CLAUDE.md files to set up, explores the codebase, and proposes a minimal CLAUDE.md plus hooks and skills.
- **When to use:** Old version: never — and delete any agent-generated CLAUDE.md/AGENTS.md you find. New version: usable, but only with an aggressive line-by-line audit of its proposals.
- **Invocation:** `/init` in a Claude Code session (new version requires the environment variable flag).
- **Construction notes:** Audit test for every proposed line: is it hook-enforced already? trivially discoverable from the code (package.json, config files)? rot-prone? rarely relevant? If any: kill it, or relocate rare instructions into a skill (progressive disclosure). Counteract sycophancy with "I'd like you to stand up to me on this one. Give me the best possible justification." The only content that belongs in CLAUDE.md is minimal, non-discoverable environment facts — Matt Pocock's entire global setup is six words: "you are on WSL on Windows." The new version's flow also uses the built-in ask-user-question tool — Matt Pocock's verdict: "Don't use the ask-user-question UI. That UI is pants." You can't see the full proposal while answering.
- **Status & evolution:** "Never run claude /init" partially deprecated by the new version, which came from community feedback (progressive disclosure, propose skills, minimal CLAUDE.md). Still too sycophantic — it caves to every pushback.
- **Source:** Never Run claude /init; Claude Code tried to improve /init... Is it any better?

## Idea to spec

The thinking phases. Details and human-side technique in [Chapter 5](05-idea-to-spec.md).

### Grilling reference skill

- **Type:** skill (shared reference)
- **What it does:** The central reference that "shows the LLM how to grill a person" — both `/grill-me` and `/grill-with-docs` rely on it.
- **When to use:** Not invoked directly; loaded by the grill-* skills.
- **Invocation:** Indirect, via `/grill-me` or `/grill-with-docs`.
- **Construction notes:** Three fixes shipped in v1.1, each a lesson in skill authoring: (1) one-question-at-a-time now states its *why* — "asking multiple questions at once is bewildering" — which made the rule stick across models; (2) a confirmation gate — "do not enact the plan until I confirm we've reached a shared understanding" — stops sessions jumping straight into implementation; (3) leading words distinguishing **facts** (things the agent finds itself by exploring the codebase) from **decisions** (made by the user) stopped the agent grilling itself.
- **Status & evolution:** Current; updated in skills v1.1 based on cross-model bug reports.
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets

### `/grill-me`

- **Type:** skill
- **What it does:** Makes the agent interview you relentlessly until shared understanding. The core is three sentences:

```text
Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. If a question can be answered by exploring the codebase, explore the codebase instead.
```

- **When to use:** Non-codebase use cases — spec-ing ideas, even non-engineering work (one user wrote a eulogy with it). Rule of thumb: "When you have a codebase, use grill-with-docs. When you don't have a codebase, use grill-me."
- **Invocation:** `/grill-me` seeded with a rough (dictated) idea, including the WHY: "Grill me. I'd like to think about adding this to the [X] page." Sessions run ~6 to ~50 questions; complex features take 30–45 minutes.
- **Construction notes:** Deliberately does NOT use the built-in ask-user-question tool — he dislikes that tool's UI, and not calling a tool is always more token-efficient. (Matt Pocock's UI complaint elsewhere is sharper: reviewing the new `/init`'s use of that same tool, he called it "pants" because you can't see the full proposal while answering.) Flexible driver role — you can flip and ask IT for trade-offs. Effectiveness depends on the human: classify questions by fidelity (grillable Q&A vs ungrillable feel-questions needing a prototype), pre-break oversized scope, lead the conversation, use a frontier model (grilling relies on parametric knowledge).
- **Status & evolution:** "The most influential four sentences I've ever written" — still alive, recategorized into the productivity section for non-codebase work. Superseded inside codebases by `/grill-with-docs`. Replaces plan mode as the planning method. Updated in v1.2 from one-question-per-turn to **multi-question rounds over a dependency graph**: questions are asked in rounds (labeled "Round 1", "Round 2"), each question labeled Q1/Q2 with a recommended answer, and only currently-answerable (frontier) questions are asked — dependent questions wait for their prerequisite. Fixes the end-of-session "dead slow" failure mode where only easy questions remain. Emojis add visual navigation; intended for dictation batch answers ("Q1, I agree. Q2, I agree. Q3, we need a change").
- **Source:** 5 Claude Code skills I use every single day; 9 Things People Get Wrong With My /grill-* skills; Building a REAL feature with Claude Code: every step explained; New Skills! v1.2 brings /wait-what, /writing-for-agents, and fixes /grill-me

### `/grill-with-docs`

- **Type:** skill
- **What it does:** Grill-me plus persistent documentation: it reads the repo's `context.md` glossary before questioning, challenges your language against it, sharpens fuzzy terms, discusses concrete scenarios, cross-references with code, updates the glossary as you go, and writes ADRs for non-obvious decisions. "This is where you turn 'I want to change X' into a crisp defensible plan."
- **When to use:** Whenever you have a codebase, and at project start (exactly when shared language is being established). Not for ideas too big for one session — use `/wayfinder`.
- **Invocation:** `/grill-with-docs` seeded with an idea ("It really can be as vague as this"). Mid-session save: "Could you save what we have into context.md so far. If there's anything we haven't figured out, grill me about that before you make the adjustments." Cut off bike-shedding: "That's good enough. Let's ship with this."
- **Construction notes:** Structure: the grill-me text at the top; instruction to find and pull in `context.md`; in-session glossary-challenging instructions; an ADR format (create ADRs only for decisions that are hard to reverse, surprising without context, AND a real trade-off). Supporting material is wrapped in XML tags to lower its prompt "loudness" — a fix for the skill being "too eager to implement" when lower text outshouted the core instructions.
- **Status & evolution:** Replaced `/grill-me` for codebase work; absorbed the separate `ubiquitous-language` skill. Payoff compounds: after 4–5 sessions one tester reported Claude "magically aligned" with his thoughts.
- **Source:** I stopped using /grill-me for coding. Here's what I use instead:; New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog

### `/wayfinder`

- **Type:** skill
- **What it does:** Pre-spec mapping for big, foggy ideas. Skill description: "A loose idea has arrived, too big for one agent session and wrapped in fog. The way from here to the destination isn't visible yet. This skill charts the way as a shared map on the repo's issue tracker, then works its tickets one at a time until the route is clear." A parent GitHub issue is the map; every decision becomes a sub-issue with blocking relationships, each scoped to one agent session and typed **research**, **grilling**, **prototype**, or **task**.
- **When to use:** Work that would blow out of the smart zone of one session; recommended for anything touching the front end (prototype tickets are essential there). Matt Pocock uses it "for literally everything, even non-coding stuff."
- **Invocation:** `/wayfinder` with the loose idea. Work the tickets one per session; when all are closed, the captured information is saved onto the map (closed tickets remain as primary sources), then run `/to-spec` on the completed map.
- **Construction notes:** Ticket types are defined at the bottom of the map ticket. Research tickets are AFK tasks (via `/research`) — "you don't actually need to watch it," so run them in a sub-agent. Grilling tickets need a session with you. Prototype tickets "raise the fidelity of the discussion by making a cheap rough concrete artifact to react to" and are "the mechanism that keeps Wayfinder from being waterfall" — cut them and the map degrades into Big-Design-Up-Front. Task tickets are "the boring stuff that doesn't need a grilling decision and can't really be automated by AI." Can invoke `/prototype` itself (model-invoked).

  The mental model the dedicated explainer adds: a *map* has a start point, a vague destination (often "a buildable spec", not the implementation), and a *fog of war* of unresolved decisions between them. Wayfinder tracks two sets — the **frontier** (decisions takable right now) and the **fog** (decisions blocked behind others); blocking relationships model dependency, and as frontier tickets close the fog recedes. It is run with a two-prompt structural pattern: **chart the map** once (free-text description of the destination), then **walk the map** per ticket — call Wayfinder *again* in a fresh session pointing at both the map and the specific takable ticket by its full name. Don't hand-drive the per-ticket loop; use Wayfinder for both. A fancier setup uses `/handoff` to auto-write the walk-the-map prompt and spawn a Claude sub-agent per ticket so you don't babysit each session.

  Two important distinctions: Wayfinder's **decision tickets are not implementation tickets** — they resolve *what to build* (research/grilling/prototype/task); the implementation tickets come later from `/to-tickets`. And the produced spec is **non-persistent** — "once the spec is present in the code, then you can just delete the spec" (deliberate divergence from spec-driven-development living specs); the durability lives in the closed decision tickets, which the spec links back to as primary source so a confused later agent can view the original instead of only the summary. That primary-source linkage is the fix for a real weakness of grill-with-docs, where the spec was the only source of truth despite being just a summary of the meeting.
- **Status & evolution:** New in skills v1.1; may replace `/grill-with-docs` in some situations — "default to Wayfinder instead." Replaces "the anxiety of managing my session with Grill with Docs, having to hand off, worry about the smart zone" — and the GitHub map is collaborative across the team. Based on pre-AI software planning fundamentals; works with any coding agent; usable for non-coding work (planning a course, a garden-office build — anything with a start, a vague destination, and a fog of open decisions). Don't reach for it when one session would suffice: "if you think the work that you're doing can be completable and plannable in a single session, then plan it in a single session."
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets

### `/research`

- **Type:** skill
- **What it does:** Near-verbatim content:

```text
Spins up a background agent to do the research so you keep working while it reads. Investigate the question against primary sources. Write the findings to a simple markdown file and save it where the repo already keeps such notes — match the existing convention.
```
- **When to use:** External dependencies, uncommon APIs, or anything with a difficult/expensive explore phase (e.g. a Stripe integration); also as the executor of Wayfinder research tickets.
- **Invocation:** `/research` standalone, or invoked from a Wayfinder research ticket.
- **Construction notes:** Very small skill; its purpose is to influence the model to research "in the right way" — primary sources, cached findings. Cache research as a repo asset (`research.md`), but scope it to the sprint: stale research "can go out of date or rot away" and cause the agent to take a wrong turn — delete it when the sprint ends.
- **Status & evolution:** New in skills v1.1, formalizing the research-caching practice from the 7-phases workflow.
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets; The 7 phases of AI-driven development

### `/prototype`

- **Type:** skill
- **What it does:** Builds throwaway prototypes to flush out design decisions before committing. Two modes: **UI prototypes** generate several radically different variations rendered in the actual route, with a floating button to toggle between them — pick, combine ("take a bit of A and B"), discard; **logic prototypes** build "a tiny interactive terminal app that pushes the state machine through cases that are harder to reason about on paper."
- **When to use:** "When you have some unknown unknowns that you can really only figure out by looking at code"; when "how should it look" or "how should it behave" is a key question. UI taste cannot be resolved by Q&A — "often the AI just simply can't see what it's building," so the human taste-loop happens here before any AFK implementation.
- **Invocation:** "Build me a prototype here," a Wayfinder prototype ticket, or bridged in and out of a grilling session via `/handoff`.
- **Construction notes:** Prototypes are research/spikes — throwaway by design, though committing a winning prototype grounds the later implementing agent. Model-invoked (so Wayfinder can call it), offering the logic-vs-UI choice because "the two react quite differently."
- **Status & evolution:** Current; made model-invoked in v1.1 to support Wayfinder.
- **Source:** New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog; New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets

### `/to-spec` (ex `/to-prd`, ex write-a-PRD)

- **Type:** skill
- **What it does:** Compresses the grilling discussion (e.g. 46.1k tokens of Q&A) into a spec document — problem statement, solution, user stories, implementation decisions, testing decisions — published to the configured issue tracker. "The spec is the destination that we're heading to."
- **When to use:** After grilling, when the remaining work won't fit in the current session's smart zone. Run it IN the grilling session — clearing context first and running it fresh throws away "100,000 tokens of really good design decisions."
- **Invocation:** `/to-spec` inside the grilling session (or on a completed Wayfinder map).
- **Construction notes:** The write-a-PRD ancestor documented the internals: ask for a long description → explore the repo to verify assertions → interview relentlessly (a copy of grill-me) → sketch the major modules to build or modify → write from a template and submit as a tracker issue, with "You may skip steps if you don't consider them necessary." Keep implementation decisions non-prescriptive so the spec stays durable against the code. Testing decisions in the spec make the implementing loop "more likely to follow TDD." Output labeling: "apply the ready for agent triage label. No need for additional triage" — but never mark the spec itself agent-ready: "don't implement PRDs, only implement actual issues."
- **Status & evolution:** write-a-PRD → `/to-prd` → `/to-spec` (v1.1 rename). Rationale: what was being created wasn't a PRD — "specification is a much broader term... technical, non-technical, or blend the two."
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets; 5 Claude Code skills I use every single day; mattpocock/skills: A complete AI Coding workflow, end-to-end

## Planning and tickets

Slicing the journey and managing the queue. See [Chapter 6](06-tickets-and-planning.md).

### `/to-tickets` (ex `/to-issues`, ex PRD-to-issues)

- **Type:** skill
- **What it does:** Turns the spec into tickets — "the journey that you take to actually enact the spec." Each ticket is sized to a single context window / smart zone, references the parent spec and its relevant user stories, and carries blocking relationships so unblocked tickets can run in parallel.
- **When to use:** Immediately after `/to-spec`, in the same session (don't clear between them). Push back on slicing: too-small tickets waste agent startup cost ("do it in one slice instead"); a good slice touches UI + schema + API.
- **Invocation:** `/to-tickets` in the spec session.
- **Construction notes:** From the PRD-to-issues ancestor: fetch the spec if not in context; draft slices with the rule "each issue is a thin vertical slice that cuts through all integration layers, not a horizontal slice of one layer"; establish blocking relationships; create on user approval. Order slices to flush out unknown unknowns first (tracer bullets). Real tickets are short — acceptance criteria live in the spec; each ticket is "literally what do you build in this session." Applies the `ready for agent` label. GitHub Issues historically lacked built-in blocking-relationship support; GitHub's sub-issue feature appears to have closed this gap — check before assuming you need to switch trackers (see [Chapter 4](04-the-workflow.md)).
- **Status & evolution:** PRD-to-issues → `/to-issues` → `/to-tickets` (v1.1 rename, tracker-neutral naming).
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets; 5 Claude Code skills I use every single day; mattpocock/skills: A complete AI Coding workflow, end-to-end

### `/triage`

- **Type:** skill
- **What it does:** Turns messy human backlogs (GitHub Issues, Jira, any tracker) into agent-actionable tasks via a label-based state machine: two category labels (`bug`, `enhancement`) × five state labels (`needs triage`, `needs info`, `ready for agent`, `ready for human`, `won't fix`), exactly one of each per issue. It is the translation layer between humans filing tickets and the AFK agents that implement them.
- **When to use:** Team contexts — triaging other people's ideas — and any repo feeding an AFK agent. Solo skill setups break down in teams without it.
- **Invocation:** Multiple modes: "triage — just give me all of the open issues I haven't triaged yet"; "walk through each of these and add the basic labels"; "show me anything that needs my attention now"; "let's move this one to ready for agent."
- **Construction notes:** Contains an **agent brief template** — moving anything to `ready for agent` requires writing a brief for the agent that picks it up. Reads a `.out-of-scope/` directory of ADR-style files recording rejected features, so matching enhancement requests get closed automatically. Don't be credulous about reporter claims: chain the `diagnose` skill ("diagnose this yourself") to force reproduction.
- **Status & evolution:** Current; the label taxonomy is explicitly provisional. Couples directly to AFK execution: Sandcastle's plan prompt only touches issues labeled `ready for agent`, so agents never "stumble around on crap tasks."
- **Source:** Burn through the backlog from hell with /triage

## Execution

Implementation sessions and the context-management skills that keep them from degrading. See [Chapter 7](07-execution.md).

### `/implement`

- **Type:** skill
- **What it does:** The named implementation step. Full content (near-verbatim):

```text
Implement the work described by the user in the spec or tickets. Use TDD where possible at pre-agreed seams. Run type checking regularly. Single test files regularly. Full test sweep once at the end. Once done, use code review to review the work and then commit your work to the current branch.
```
- **When to use:** One ticket per session. Do NOT say "do every single ticket" — implement one, check the smart zone, usually `/clear` between every ticket. If post-grilling work fits the remaining smart zone, `/implement this` directly in the grilling session.
- **Invocation:** After clearing: `@tickets` + "/implement this". The spec decides where you're going; the tickets decide how you get there — a fresh agent needs nothing else.
- **Construction notes:** Deliberately minimal — it mostly relies on the agent's prior and harness training, but "earns its place" as the named step so people know the flow. Observed behavior: implements, runs typecheck and build, does extra behavioral verification, invokes `/code-review` in subagents, commits when clean.
- **Status & evolution:** New in skills v1.1; the flow's endpoint that Matt Pocock almost didn't write.
- **Source:** New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets; mattpocock/skills: A complete AI Coding workflow, end-to-end

### TDD skill (`/tdd`)

- **Type:** skill
- **What it does:** Encodes test-first red-green discipline, one test at a time:

```text
An incremental loop for each remaining behavior: write the next test, see that it fails, write the minimal code to pass.
```

The red-then-green-without-touching-the-test sequence is a trust signal that is "pretty hard for it to fake," so you can skim test titles instead of reading every implementation. "TDD has been the most consistent way that I've improved agents' outputs."
- **When to use:** Whenever building features with an agent; as the prompt for Ralph loops. Precondition: clear module boundaries — TDD "demands a lot of your codebase."
- **Invocation:** `/tdd`, referenced by `/implement` ("TDD where possible at pre-agreed seams"), or passed to an AFK loop.
- **Construction notes:** v1 was long: philosophy, refactoring, mocking, deep-modules material, plus interactive steps (confirm interface changes with the user, confirm which behaviors to test, design interfaces for testability). One-test-at-a-time exists because LLMs "love to create huge horizontal layers" — 90 tests in one edit, then a one-shot implementation, yielding "a lot of crap tests."
- **Status & evolution:** Redesigned in v1.1 as **reference material only** — no prescribed steps, just the order: "red before green, one slice at a time." Refactoring was removed from the loop (no more red-green-refactor) and moved to code review, both because agents are reluctant to refactor code sitting in their own context window and because "you don't overload the implementation." The reference-only design means you can hand it to an AFK agent and it just works.
- **Source:** Red Green Refactor is OP With Claude Code; 5 Claude Code skills I use every single day; New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets

### `/handoff`

- **Type:** skill
- **What it does:** Compacts the relevant slice of the current session into a disposable markdown document that seeds a DIFFERENT session — unlike `/compact`, which only continues the same one. Enables scope-splitting, prototype side-quests, cross-agent handoffs (Claude Code → Codex/Copilot CLI, since it's plain markdown), and the "DIY subagent" pattern: hand off to a fresh full-context session, let it work, hand the learnings back.
- **When to use:** Out-of-scope work spotted mid-session; ungrillable questions needing a prototype round-trip; nearing the dumb zone but wanting a new session. Not for barreling on at the same problem — that's `/compact`.
- **Invocation:** `/handoff`, ALWAYS with arguments stating why you're handing off and what the next session will focus on ("I just can't see how you would write a good handoff document otherwise"). E.g.: "Hand off to prototype the difficult bits here: the window communication, the tldraw SDK integration."
- **Construction notes:** Instructions (near-verbatim):

```text
Write a handoff document summarizing the current conversation so a fresh agent can continue the work.
Save it to the temporary directory of the user's operating system, not the current workspace.
Read the file before you write to it.
Include a suggested skills section in the document which suggests skills that the agent should invoke.
Do not duplicate content already captured in other artifacts. Reference them by path or URL instead.
Redact any sensitive information: API keys, passwords or PII.
If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
```

A handoff must transfer "the vibe of the context window and the intent of the context window," not just content — that's why the suggested-skills section matters (it lets the next session auto-invoke grill-with-docs, diagnose, prototype, etc. without you having to think about it).
- **Status & evolution:** Started as a manual prompt ("write me a handoff.md") used so often it became a skill; lives in the productivity section (useful beyond engineering). Current — the bridge in and out of `/prototype` in the main flow.
- **Source:** /handoff is my new favourite skill; New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog

### `diagnose`

- **Type:** skill
- **What it does:** Makes the agent reproduce a reported bug itself rather than trusting the reporter, then fix it — structured like the TDD skill: create the regression test / feedback loop FIRST, then fix within that loop.
- **When to use:** During triage when the agent is "too credulous" about reporter-supplied stack traces; any bug fix where you want a regression test guaranteed.
- **Invocation:** "Diagnose this yourself" — chainable inside a `/triage` session.
- **Construction notes:** Borrows the TDD skill's feedback-loop-first setup. Demo behavior: scaffolded a regression unit test, ran the full suite plus type check, added a changeset, completed the fix.
- **Status & evolution:** Current; also appears as a suggested skill in handoff docs.
- **Source:** Burn through the backlog from hell with /triage

### Plan mode

- **Type:** harness feature (Claude Code; now also Cursor and VS Code)
- **What it does:** Disables the write-to-filesystem capability and swaps in a plan-focused system prompt: the agent explores the codebase (via an explore subagent), writes a plan to a file on disk, and asks clarifying questions before any code is written.
- **When to use:** Historically: every change ("if I had one tip to give to anyone that's doing AI coding, it is to use plan mode"). Current recommendation: the grilling skills replace it for feature planning — plan mode "will tend to just spit out a plan really early" before shared understanding. It remains the built-in fallback where the skills aren't installed.
- **Invocation:** Shift+Tab cycling until "plan mode" shows; dictate a rough prompt; iterate on the plan's questions; approve and exit into execution.
- **Construction notes:** Pairs with two CLAUDE.md rules: "Make the plan extremely concise. Sacrifice grammar for the sake of concision" (2,000-word plans → ~400) and "At the end of each plan, give me a list of unresolved questions to answer, if any" (pushes the agent into a paranoid, exploratory mode). For work bigger than one context window: "make the plan multi-phase," execute phase-by-phase with accept-edits on, persist the plan as a GitHub issue before `/clear`.
- **Status & evolution:** Three-stage evolution, newest wins: (1) plan mode converted Matt Pocock from AI skeptic; (2) multi-phase plans stored in GitHub issues carried large features; (3) both replaced — grilling skills for the thinking, spec + tickets + Ralph loops for the execution ("instead of using plan mode, you get an agent to grill you").
- **Source:** I was an AI skeptic. Then I tried plan mode; How I use Claude Code for real engineering; New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets

### Auto mode / accept-edits

- **Type:** harness feature (Claude Code)
- **What it does:** Lets the agent apply edits without per-edit approval.
- **When to use:** Matt Pocock's default for the main flow (grilling runs in auto mode, not plan mode). Being aggressive with accept-edits is earned by planning: "now that we've done the planning, we can be pretty aggressive with accept edits on." Turn it OFF for human-in-the-loop skills — "auto mode does some funny things with these human-in-the-loop style flows" (observed with improve-codebase-architecture).
- **Invocation:** Mode toggle in the session (same cycle as plan mode).
- **Construction notes:** Not applicable — built-in behavior.
- **Status & evolution:** Current.
- **Source:** mattpocock/skills: A complete AI Coding workflow, end-to-end; How I use Claude Code for real engineering; How To De-Slop A Codebase Ruined By AI (with one skill)

### Explore subagents

- **Type:** harness feature (Claude Code)
- **What it does:** Spawns a subagent — often on a cheap, fast model (Haiku 4.5) — that reads "tons and tons of files," pings out many requests, and hands only a summary back to the parent agent (Opus-class). Keeps the parent context small (a long grilling session stayed at ~40k tokens) and the cost down (~40k explore tokens on Haiku, not Opus).
- **When to use:** Automatic — plan mode, grilling, and `/init` all trigger it. It is the reason just-in-time context discovery beats pre-loaded CLAUDE.md documentation.
- **Invocation:** Automatic. Subagents are also the review mechanism: `/code-review` runs in subagents because "agents are often really bad at editing code or improving code they've just written."
- **Construction notes:** For DIY subagents with full context windows and human control, use `/handoff` instead of the built-in machinery.
- **Status & evolution:** Current. One complaint: "I do wish that explore was faster. You need it in every single session."
- **Source:** I was an AI skeptic. Then I tried plan mode; Building a REAL feature with Claude Code: every step explained; Never Run claude /init

### "By the way" side questions (side quests)

- **Type:** harness feature (Claude Code)
- **What it does:** Ask a quick question that does NOT enter the chat history — e.g. "describe what's going on with the course write service — its shape and capabilities."
- **When to use:** Quick orientation questions you don't want polluting the session's context.
- **Invocation:** The "by the way" side-question feature; exit with space-enter or escape.
- **Construction notes:** Not applicable — built-in behavior.
- **Status & evolution:** Current (new feature at recording).
- **Source:** Building a REAL feature with Claude Code: every step explained

### `/context` (the context meter)

- **Type:** harness feature (Claude Code)
- **What it does:** Shows tokens used vs the model's limit, broken down into system prompt, messages, tools. The instrument behind smart-zone budgeting: "you really do need full transparency, full understanding of what's happening in your context window at any time."
- **When to use:** Constantly — before executing, after each ticket/phase, and before deciding whether to clear. Working thresholds from the sources: quality degrades past ~120–140k tokens; keep a mental session budget of ~100k; get nervous below ~50k free.
- **Invocation:** `/context` in a session.
- **Construction notes:** Also useful to verify skill hygiene — the entire skills set shows up as only ~660 tokens.
- **Status & evolution:** Current. Feature request on record: expose token usage for the status line so you don't have to keep running the command.
- **Source:** Most devs don't understand how context windows work; mattpocock/skills: A complete AI Coding workflow, end-to-end; How I use Claude Code for real engineering

### `/clear`

- **Type:** harness feature (Claude Code)
- **What it does:** Clears the conversation history and frees the context window.
- **When to use:** "Clear should be your default" reset — between tickets, after persisting state externally (spec, tickets, GitHub issue). Never clear away a valuable grilling context before banking it with `/to-spec` or `/handoff`.
- **Invocation:** `/clear`.
- **Construction notes:** Not applicable — built-in behavior.
- **Status & evolution:** Current.
- **Source:** Most devs don't understand how context windows work; mattpocock/skills: A complete AI Coding workflow, end-to-end

### `/compact`

- **Type:** harness feature (Claude Code)
- **What it does:** Replaces the conversation history with an LLM-generated summary (files referenced, things you said, "the vibes"), moving you from near the dumb zone back into the smart zone of the SAME session. In one demo: messages went from ~70k tokens to ~4k.
- **When to use:** "Compacting is useful when you want to preserve the vibes of a conversation. But clear should be your default." Best fit: long debugging sessions — compact away tried options, keep going. To move work to a DIFFERENT session, use `/handoff` instead.
- **Invocation:** `/compact` (auto-compact triggers deep in the dumb zone if enabled).
- **Construction notes:** Costs time (~a minute) and tokens; repeated compaction leaves "a sediment of different layers."
- **Status & evolution:** Current; its single-session limitation is the gap `/handoff` fills.
- **Source:** Most devs don't understand how context windows work; /handoff is my new favourite skill

## Review and QA

The quality gate. Full treatment in [Chapter 8](08-review-and-qa.md).

### `/code-review` (ex `/review`)

- **Type:** skill
- **What it does:** Spawns two parallel subagents, one per axis: **standards** (does the code conform to this repo's documented coding standards — reads `coding-standards.md` if present, falls back to Martin Fowler-style code smells) and **spec** (does the code faithfully implement the originating ticket/spec, cross-checking every acceptance criterion). "If you only focus on standards, then you're going to miss spec stuff. And if you only focus on the spec, then you're going to miss standards stuff."
- **When to use:** Invoked automatically by `/implement` at the end of a run; also directly on any diff. Runs in subagents because the writing agent will just approve its own code.
- **Invocation:** `/code-review`, or automatically via `/implement`.
- **Construction notes:** v1.1 added a ~10-line list of Fowler's smells from *Refactoring* — mysterious name, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, divergent change, speculative generality, message chains, middleman — one sentence each. It works because the book is "deep in the agent's prior": naming the concept unlocks the knowledge. Result: "outrageously useful... really cheap to add." Coding standards belong in their own file outside agents.md; a separate standards-extraction skill is planned to feed the standards axis. Lessons from evaluating Cursor's "thermonuclear" review skill: license ambition beyond the diff (agents otherwise "treat that diff as its bounds"), tolerate false positives ("it's the ones that you miss... those are the dangerous ones"), keep prompts DRY with concrete criteria, and don't ignore tests/seams/feedback loops.
- **Status & evolution:** `/review` (in progress, two-axis design) → `/code-review` (graduated in v1.0, Fowler smells in v1.1). Absorbed the refactoring step removed from the TDD loop.
- **Source:** New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog; New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets; Can Cursor's HARDCORE Review Skill Stop The Slop?

### Improve-codebase-architecture (the de-slop skill)

- **Type:** skill
- **What it does:** Scans the codebase for architectural "deepening opportunities" — shallow modules, poor locality, duplicated parallel implementations, untested seams — presents a numbered candidate list, then walks you through the refactor design via a grilling session. The cure for AI-accelerated software entropy.
- **When to use:** Every couple of days in fast-moving codebases, weekly otherwise, or after a surge of development; the recommended FIRST step in a legacy codebase before any changes. Never as fire-and-forget: "this requires a judgment call from you, the programmer, sitting above the LLM." Turn auto mode off first. Do ONE candidate at a time — "these decisions do require taste."
- **Invocation:** Run the skill in a fresh session; pick a candidate explicitly (be precise — "pick one" got interpreted as candidate #1); answer its grilling questions; exit via "to PRD" / "to issues" to file the agreed design as a tracker issue for an AFK agent.
- **Construction notes:** Instructions: explore the codebase naturally, as an agent would, surfacing what the AI itself finds confusing — guiding questions include "Where does understanding one concept require bouncing around between many small files?" and "Where do tightly coupled modules create integration risk in the seams between them?" Then: ground with concrete code, grill, propose a module shape, "spawn three sub-agents in parallel, each of which must produce a radically different interface for the deepened module," recommend the strongest or a hybrid, and file a refactor RFC via `gh issue create`. Contains an embedded glossary (module, interface, seam, adapter, locality, depth) — "having a shared vocabulary with the AI... means you can be a lot more precise."
- **Status & evolution:** Current; the glossary was recently added. Output feeds `/to-tickets` — a refactor RFC is a destination needing a journey.
- **Source:** How To De-Slop A Codebase Ruined By AI (with one skill); 5 Claude Code skills I use every single day

### QA plan generation

- **Type:** proto-skill (free prompt, not yet packaged)
- **What it does:** Produces a step-by-step human QA plan from recent work and files it as a tracker issue.
- **When to use:** After every AFK/execution run with user-facing changes; the human verification checkpoint that makes AFK execution safe. QA findings become new tickets, which loop back into execution.
- **Invocation:** In a fresh session: "Take the last five commits and create a QA plan for me. Save that QA plan in a GitHub issue. The QA plan should give me a step-by-step guide on how to test every single part of the new implementation."
- **Construction notes:** Label/mark the QA-plan issue human-only so the AFK loop skips it, and close it once behavior drifts so it stops being treated as source of truth.
- **Status & evolution:** Matt Pocock is considering baking it into the skills "for almost every user-facing change."
- **Source:** Building a REAL feature with Claude Code: every step explained; The 7 phases of AI-driven development

### Feedback button

- **Type:** infrastructure (built into your own app)
- **What it does:** An in-app button that turns dictated QA feedback into a GitHub issue containing a Haiku-generated title, the route it was submitted from, and the verbatim feedback text (plus pasted errors). "This information is enough for Ralph to do a really nice job."
- **When to use:** During manual QA walkthroughs, so bug filing and bug fixing run in parallel — 6–7 issues filed in 8 minutes while the loop fixed earlier ones in the background.
- **Invocation:** Click, dictate, submit.
- **Construction notes:** Cheap model (Haiku) for title generation; capture route context automatically; keep the user's words verbatim.
- **Status & evolution:** Current; a pattern to replicate in your own internal tools rather than an installable skill.
- **Source:** Building a REAL feature with Claude Code: every step explained

### Chrome-debugging skill + browser MCP

- **Type:** skill + infrastructure
- **What it does:** Gives the agent a visual feedback loop for frontend work: an `.mcp.json` runs the Chrome DevTools MCP server against a remote-debugging browser, and a tiny project skill tells the agent how to start it. The agent screenshots and inspects its own UI work "like a human coder" — without it, "your LLM is essentially flying blind."
- **When to use:** Complicated frontend work (interactions, multi-step forms, animations, theming) and any frontend/full-stack AFK loop — "an enormous improvement." Not needed for purely textual backend work.
- **Invocation:** Automatic once configured; QA prompts like "double check if light mode and dark mode are working okay on the homepage."
- **Construction notes:** The skill's entire content is one instruction: "Before using Chrome DevTools MCP, you must launch Chrome in headless mode with remote debugging enabled." Warning: browser MCPs are context-hoggy (screenshots, verbose tool descriptions) — another reason tickets must stay small.
- **Status & evolution:** Playwright MCP → Chrome DevTools MCP (community verdict on the former: "not very good"); alternatives mentioned: dev browser, Playwriter.
- **Source:** Frontend is HARDER for AI than backend (here's how to fix it); Ship working code while you sleep with the Ralph Wiggum technique

## Scaling and AFK

Multiplying yourself. Full treatment, including safety, in [Chapter 9](09-afk-and-parallel-agents.md).

### Ralph loop (`ralph.sh` / `ralph-once.sh`)

- **Type:** infrastructure
- **What it does:** "Ralph is a bash loop. You give the LLM some task to complete or list of tasks and you run it again and again and again until it's complete." Each iteration is a fresh context window: pick the highest-priority item from `prd.json`, implement it, mark `passes: true`, APPEND learnings to `progress.txt`, commit, repeat — bounded by a max-iterations argument and an early-exit sentinel (e.g. `PROMISE_COMPLETE`).
- **When to use:** Working through a whole backlog unattended (overnight/AFK). `ralph-once.sh` (same prompt, one interactive iteration) for difficult features needing steering, and for learning what Ralph can do.
- **Invocation:** `plans/ralph.sh <max_iterations>` (any CLI-invocable agent works: Claude Code, opencode, Codex); `pnpm ralph` in the Dockerized variant.
- **Construction notes:** Prompt essentials, each fixing an observed failure: "highest priority feature... the one YOU decide" (else it takes the first item); "only work on a single feature" (else context bloat); "append" not "update" for progress.txt (else it rewrites the file); commit every iteration so git history is recoverable memory; output the sentinel when done. Feedback loops are what make it produce WORKING code: `pnpm typecheck` + `pnpm test` per commit, CI stays green, browser automation for end-to-end verification ("do all testing as a human user would"). Honor human-only labels so the loop skips QA-plan issues. Human reviews code and adjusts the PRD after the loop.
- **Status & evolution:** Credited to Geoffrey Huntley; replaced the multi-phase-plan workflow and beats swarms/meshes/orchestrators ("16 parallel agents... absolutely hellish"). Only recently viable because models (Opus 4.5, GPT 5.2) got good enough. Later matured into Sandcastle.
- **Source:** Ship working code while you sleep with the Ralph Wiggum technique; Building a REAL feature with Claude Code: every step explained

### Sandcastle

- **Type:** infrastructure (open-source TypeScript library)
- **What it does:** Orchestrates AI coding agents in isolated Docker sandboxes with one primitive — `sandcastle.run({agent, sandbox, prompt})` — composable in plain TypeScript into planner → parallel implementers → reviewer → merger pipelines. Sandboxing (not YOLO mode) solves the permissions problem: no approval prompts, and the agent can't "do mad things on your system like delete your home directory."
- **When to use:** True AFK operation: backlog pickup, parallel implementation, self-review, auto-merge. Agent-agnostic — swap Claude Code for Codex per step, run adversarial cross-agent review, or best-of-N implementations.
- **Invocation:** `npm install ai-hero/sandcastle`, `npx sandcastle init` (choose agent, sandbox provider, backlog manager, template), then `npx tsx .castle/main.mts`. Only GitHub issues labeled `sandcastle` (and, via triage, `ready for agent`) get picked up.
- **Construction notes:** Scaffolds a `.castle` directory: `main.mts`, editable markdown prompt files (plan/implement/review/merge), a Dockerfile (gh CLI + agent binary inside the container), `.env` (`ANTHROPIC_API_KEY`, GitHub token). Prompt files support arguments and `!`-backtick executed snippets (e.g. injecting a live `git diff`) — syntax copied from Claude skills. The review prompt has a fill-in coding-standards section; the merger acts as a "senior merger developer" for gnarly conflicts. Reviewer runs only when a branch has more than one commit — "the implementer can make mistakes, but the reviewer generally picks it up."
- **Status & evolution:** Current — the open-sourced maturation of the Ralph setup. Economics caveat: Anthropic's dedicated monthly credit for programmatic use (Agent SDK, `claude -p`, GitHub Actions) is effectively a 5x–10x cut for heavy AFK users; the stated plan is Claude Code for human-in-the-loop work and Codex-class subscriptions for AFK workloads.
- **Source:** I Open-Sourced My Own AFK Software Factory; Anthropic's "dedicated monthly credit" is actually a huge cut

### Worktrees (`claude --worktree`)

- **Type:** harness feature (Claude Code, on top of `git worktree`)
- **What it does:** Runs each session in its own isolated git worktree (auto-created at `.claude/worktrees/<random-name>`), so parallel agents don't interfere; on exit it prompts keep-or-remove. "It basically makes parallelization a lot more free than it was before" — every idea gets an instant worktree and flows back to main as a PR.
- **When to use:** "I'm not sure why you wouldn't want to use git worktrees like every single time you use Claude." Subagents also support worktrees, but opt-in — you must ask.
- **Invocation:** `claude --worktree` from the repo.
- **Construction notes:** Gotcha: the worktree branch tracks its source branch (main), so a plain `git push` can land commits on main. Rule: push to an explicitly named branch (`git push origin <worktree-branch>`), protect main, and run a push-blocking safety hook (the hook is what caught the bug). Push before removing a worktree or the work is lost. Related: a PRD exists for worktree locking to prevent concurrent agent access.
- **Status & evolution:** Current (first-impressions at recording).
- **Source:** I'm using claude --worktree for everything now; Burn through the backlog from hell with /triage

## Learning and meta

Skills about using the system itself. Authoring guidance lives in [Chapter 10](10-building-skills.md).

### `/ask-matt`

- **Type:** skill
- **What it does:** "Essentially me as a skill" — an interactive tutorial that knows everything about the skills repo and the main flow, answering questions like which skill to run first and when to fork to spec + tickets.
- **When to use:** Onboarding yourself or a teammate to the system; whenever you're unsure what the flow is.
- **Invocation:** "ask Matt, how do I get started? I want to make some code changes here. What is the main flow I should use?"
- **Construction notes:** Its demo answer doubles as the canonical flow summary: start at the top of the main flow in one unbroken context window; begin with grill-with-docs (stateful — records learnings into context.md and ADRs); if a question needs a runnable answer, use prototype bridged via handoff; after grilling, either implement directly or go to-spec → to-tickets when multiple sessions are needed.
- **Status & evolution:** Current.
- **Source:** mattpocock/skills: A complete AI Coding workflow, end-to-end

### `/teach`

- **Type:** skill
- **What it does:** Turns the agent into a stateful one-to-one teacher for any topic (Matt Pocock learned to solve a Rubik's cube with it). It persists a teaching workspace — `mission.md`, resources, numbered HTML lessons, learning records, glossary, cheat sheets, `notes.md` — so every fresh session "will have all the context it needs to keep me in the zone of proximal development."
- **When to use:** Learning anything over multiple sessions; proposed for engineering onboarding — point a new hire's teach workspace at the codebase instead of maintaining static docs (which rot AND sit outside each reader's zone of proximal development).
- **Invocation:** In an empty directory (one workspace per topic): "teach me how to solve a Rubik's cube"; subsequent sessions just `teach`; report progress and problems as you would to any one-to-one teacher.
- **Construction notes:** Opens with "The user has asked you to teach them something. This is a stateful request." Defines the workspace shape, a philosophy section giving the AI its thinking terms (knowledge from high-trust resources → skills from interactive practice → wisdom from community), lesson shape (HTML because it's "so much richer than markdown"), and a wisdom-delegation posture: "attempt to answer but ultimately delegate to a community." The exemplar of the **stateful vs stateless** skill-design axis: grill-me is stateless, grill-with-docs and teach are stateful; neither kind is better — choose per skill.
- **Status & evolution:** Current; deliberately anti-dependence — it hands learners off to real communities.
- **Source:** Learn anything with the /teach skill

### `/writing-*` (fragments → beats → shape)

- **Type:** skill set (in progress)
- **What it does:** A three-part writing pipeline: **fragments** (dictate raw pieces of text; the AI prompts you toward better ones), **beats** (choose a path through the story — the skill offers three options for where to go next and writes the beats from your fragments), **shape** (a final review pass — "make sure it doesn't sound too AI, make sure it's structured in the right way").
- **When to use:** Long-form writing — articles, newsletters, stories.
- **Invocation:** The three skills in sequence.
- **Construction notes:** Modeled on how authors keep years-long journals whose fragments "end up working their way into stories almost verbatim."
- **Status & evolution:** In progress — "I don't think they're going to be ready anytime soon," but free to try.
- **Source:** New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog

## Checklist

- [ ] Install the skills repo (`npx skills@latest add mattpocock/skills`, symlink, project scope for teams) and verify the context cost with `/context` (~660 tokens).
- [ ] Run `/setup-mattpocock-skills` once per repo: tracker, triage labels, single-context domain docs.
- [ ] Convert deterministic CLAUDE.md rules into PreToolUse hooks; keep CLAUDE.md to minimal, non-discoverable environment facts.
- [ ] Do not run the old `/init`; if you try the new one, audit every proposed line (hook-enforced? discoverable? rot-prone? rare?).
- [ ] Route every feature through the main flow: grill (grill-with-docs; wayfinder for big/foggy ideas) → to-spec → to-tickets → implement (which runs code-review) — never plan mode for feature planning.
- [ ] Use `/handoff` (always with a stated purpose) to split scope and round-trip prototypes; `/clear` between tickets; `/compact` only to barrel on in one session.
- [ ] Run `/triage` so AFK agents only ever pick up `ready for agent` work with a written brief; encode rejections in `.out-of-scope/`.
- [ ] Prompt execution loops with the TDD skill: red before green, one slice at a time; leave refactoring to code review.
- [ ] Run improve-codebase-architecture every few days to a week, one candidate at a time, auto mode off.
- [ ] After every AFK run: generate a QA plan issue (human-labeled), walk it, file findings via a feedback-button-style path, re-run the loop.
- [ ] Sandbox all AFK execution (Sandcastle/Docker) — never YOLO mode; use worktrees per agent and push to explicitly named branches behind a push-blocking hook.
- [ ] For foggy big work or front-end-heavy work, default to `/wayfinder`: chart the map once, then walk each takable ticket in its own Wayfinder session; let prototype tickets keep it from becoming waterfall.
- [ ] After adopting new or renamed skills, use delete-and-re-add rather than trusting the installer, then audit the skills folder for stale entries.

## Sources

- mattpocock/skills: A complete AI Coding workflow, end-to-end
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog
- 5 Claude Code skills I use every single day
- I stopped using /grill-me for coding. Here's what I use instead:
- 9 Things People Get Wrong With My /grill-* skills
- Building a REAL feature with Claude Code: every step explained
- The 7 phases of AI-driven development
- How To De-Slop A Codebase Ruined By AI (with one skill)
- Burn through the backlog from hell with /triage
- /handoff is my new favourite skill
- Red Green Refactor is OP With Claude Code
- Ship working code while you sleep with the Ralph Wiggum technique
- I Open-Sourced My Own AFK Software Factory
- Anthropic's "dedicated monthly credit" is actually a huge cut
- Learn anything with the /teach skill
- Can Cursor's HARDCORE Review Skill Stop The Slop?
- I was an AI skeptic. Then I tried plan mode
- How I use Claude Code for real engineering
- Never Run claude /init
- Claude Code tried to improve /init... Is it any better?
- How to actually force Claude Code to use the right CLI (don't use CLAUDE.md)
- I'm using claude --worktree for everything now
- Most devs don't understand how context windows work
- Frontend is HARDER for AI than backend (here's how to fix it)
- /wayfinder: Nothing is too big to plan anymore

See also: [Chapter 4 — The End-to-End Workflow](04-the-workflow.md), [Chapter 5 — From Idea to Spec](05-idea-to-spec.md), [Chapter 7 — Execution](07-execution.md), [Chapter 8 — Review, QA, and De-Slopping](08-review-and-qa.md), [Chapter 9 — AFK and Parallel Agents](09-afk-and-parallel-agents.md), [Chapter 10 — Building Skills](10-building-skills.md), [Chapter 13 — Glossary](13-glossary.md).
