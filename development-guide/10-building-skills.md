# 10. Building Skills That Actually Change Behavior

Every chapter before this one used skills; this one teaches you to write them. A **skill** is a reusable, versioned instruction set invoked inside an agent harness — the mechanism that turns "quality depends on who is prompting" into "quality is enforced by the process." This chapter covers the full authoring lifecycle: anatomy and invocation modes, the stateless/stateful design decision, the wording techniques that make instructions actually stick across models, when to reach for hooks instead, and how to install, distribute, test, and version a skill set. By the end you should be able to author a skill your whole team can run and improve.

## Skills Are Your Process, Written Down

Matt Pocock's framing: agents are "a fleet of middling to good engineers... but they have no memory." A memoryless workforce makes process more important than it has ever been — you need "a really strict path it can walk down every single time." Skills are that path, encoded. He reports that encoding his process this way made the code quality the AI produces "shoot up."

The design stance that follows: "The most successful way to get code quality up from agents is just to treat them like humans. Humans with weird constraints." His skills would read fine as "a little mini markdown book of processes for humans" — they are process documentation first, prompts second.

Two consequences for authors:

1. **Anything you do repeatedly is a skill candidate.** The `/handoff` skill started as a prompt he typed by hand ("write me a handoff.md document so that I can then just pass that into another agent") until: "It turned out I was doing this so freaking often that I just decided, okay, I need a skill for this." His standing habit: "I'm constantly thinking about how to package my instincts and coding practices into reusable skills." Do not dismiss a workflow as too simple to be a skill — he made that mistake with handoff, and frequency of use proved it wrong.
2. **Short skills can carry enormous weight.** The original `/grill-me` skill is three sentences:

```text
Interview me relentlessly about every aspect of this plan until we reach
a shared understanding.

Walk down each branch of the design tree, resolving dependencies between
decisions one by one.

If a question can be answered by exploring the codebase, explore the
codebase instead.
```

> **Why it works:** "Skills don't have to be long to be impactful. You've just got to choose the right words for the LLM at the right time." Those three sentences replaced plan mode for users worldwide (see [Chapter 5](05-idea-to-spec.md)).

But note what a short skill demands of its user: the grill skills "are designed to aid you as an engineer, not replace you as an engineer." A skill encodes the agent's side of the process; the human still has to be skilled at their side. Keep that boundary in mind when deciding what to put in the file.

## Anatomy of a Skill

Across the skills documented in the sources, a well-formed skill file is built from some subset of these parts:

- **A short, precise description** — one sentence stating what the skill does (e.g. `/handoff`: "compact the current conversation into a handoff document for another agent to pick up"). This is what sits in the always-loaded skill list; everything else is loaded only on invocation.
- **The core task** — what the agent actually does, stated up front. For simple skills this is the whole file (`/grill-me`'s three sentences; `/implement`'s six).
- **Supporting information** — rationale, formats, edge-case guidance, wrapped so it does not outshout the core task (see "Control the loudness" below).
- **Workspace shape** (stateful skills only) — the files and folders the skill reads at start and writes as it progresses.
- **A philosophy section** (large skills only) — `/teach` has a section where Matt "really define[s] the terms that the AI should think in" (knowledge → skills → wisdom). This gives the model a vocabulary for its own reasoning inside the skill.
- **Format documents** — supporting files packaged with the skill defining the shape of each artifact it produces (`/teach` ships a learning-record format, a mission format, a resources format; `/grill-with-docs` embeds an ADR format).
- **Harness handholding** — small workaround instructions for quirks of the tool, e.g. `/handoff` includes "read the file before you write to it" purely because Claude Code errors on Write if the file was never Read — "an awkward little bit of Claude Code handholding."
- **Metadata** — at minimum whether the skill is user-invocable: Matt sets `user-invocable: false` on model-only skills so they don't clutter the human-facing slash menu.

## User-Invoked vs Model-Invoked: Pay the Context Tax Deliberately

Skills come in two invocation modes, and the choice is a context-budget decision (the budget itself is [Chapter 1](01-how-llms-actually-work.md)'s subject).

**User-invoked** skills load only when a human types them (`/grill-with-docs`, `/to-spec`). Because they are user-invoked, only their descriptions sit in context permanently — which is why the descriptions must be short and precise. The payoff is measurable: with all ~38 skills from mattpocock/skills installed, the entire set consumes about **660 tokens** of context (verifiable via `/context` in Claude Code). "Even though we've downloaded all of my skills, the skills only take up 660 tokens here." Matt contrasts this with other skill repos whose skills "leech their way" into context with long auto-loaded descriptions.

**Model-invoked** skills are triggered by the agent itself when their description matches the situation. Two documented uses:

- `/prototype` was made model-invoked so that a planning skill can invoke it on its own when a "how should it look / how should it behave" question surfaces.
- The effect-package-install skill (generated by Claude Code's experimental `/init`) fires whenever the agent installs Effect packages — a rare, situational rule that would otherwise waste always-loaded instruction budget. Matt set `user-invocable: false` on it because a human never needs to call it.

> **Rule:** Default to user-invoked with a one-sentence description. Make a skill model-invoked only when another skill or a specific recurring situation must trigger it without a human present — and then hide it from the user menu with `user-invocable: false`.

Skills also compose: a handoff document includes a "suggested skills" section so the next session auto-invokes the right ones — "skills define the flavor of that session." When authoring, think about which skills should name yours, and which yours should name.

## Stateless vs Stateful: Decide Whether the Skill Needs Memory

The foundational design axis when authoring any skill, from the `/teach` video:

- A **stateless skill** retains nothing between runs. "A stateless skill doesn't save anything on the file system to help it pick up where it left off later." Example: `/grill-me` — "it just grills you about a topic until you're ready to implement."
- A **stateful skill** saves state to the local file system or to MCP servers, so it can pick up where it left off and get better over time. Example: `/grill-with-docs`, which persists ADRs and a glossary to the repo and "gets better over time."

Matt is explicit that "one of these is not better than the other. They're just useful in different situations." The design procedure:

1. Ask: does this skill need memory of previous runs to do its job well?
2. If yes, define a **workspace shape** — the set of files/folders the skill reads at start and writes to as it progresses — and document it in the skill.
3. If no, keep it stateless for simplicity.

Statefulness earns its complexity when value compounds across sessions (teaching, documentation, decision records). His own evolution proves the point: he first conceived `/teach` as stateless ("find some good resources and give you an output that would teach you a lesson") and rejected it — "I realized that all the good teaching that I do is stateful... So I decided that teach had to be a stateful skill."

### The /teach workspace, the stateful exemplar

`/teach` turns the agent into a personal one-to-one teacher over multiple sessions (Matt used it to learn to solve a Rubik's cube). Its opening framing is a model of stating statefulness explicitly:

```text
The user has asked you to teach them something. This is a stateful
request. They intend to learn the topic over multiple sessions.
```

Its workspace shape — worth copying as a template for any compounding skill:

```text
mission.md         # why the student wants this + a concrete, testable goal
                   # ("...solve it unaided at least once. The goal is the
                   #  achievement itself, not speed, not theory.")
resources          # web-searched primary-source, high-trust resources;
                   # created on first pass, continually updated
lessons/           # numbered HTML files, one per lesson
learning records   # simple records written whenever the student reports
                   # progress; used to tailor the next lesson
glossary           # all jargon learned so far — lets later lessons be
                   # more concise by referencing terms
cheat sheets       # e.g. a "solve card": the whole procedure in one place
notes.md           # the agent's internal notes: preferences, watch-outs
```

Because everything lives on disk, context can be cleared freely: every re-run of `teach` "will have all the context it needs to keep me in the zone of proximal development." On a fresh session the agent starts by checking the workspace state — even reading earlier lessons "to match the house style." That is what statefulness buys: the workspace is the teacher's memory across context clears.

Two authoring lessons generalize from `/teach`:

- **Mission-first.** Capture WHY the user wants the outcome plus a concrete success criterion, and what the goal is *not*. Skills that know the mission make better in-flight decisions.
- **Choose the richest output format the job allows.** Lessons are HTML, not markdown: "HTML is just so much richer than markdown. It allows it to be so much more expressive, so much more interactive."

`/teach` also doubles as an onboarding tool: point a new hire's own teach workspace at the codebase and they learn it independently — better than static onboarding docs, which are "a real pain in the ass" to keep current and are usually pitched outside any individual reader's zone of proximal development.

## Writing Instructions That Stick

These techniques come from several rounds of real user bug reports across the skills' history — some from the v1.1 changelog, others from earlier fixes to different skills — and each one made a documented failure mode disappear.

### Explain why, not just what

The grilling reference skill directed the model to ask one question at a time, yet models occasionally asked several at once. The fix was not louder repetition — it was adding the reason: **"asking multiple questions at once is bewildering."** That one clause made the rule stick.

> **Why it works:** Rules with reasons are followed more consistently across models. A bare imperative is one instruction among hundreds; a reasoned rule recruits the model's own judgment to the same side.

This mirrors the style rule for humans: a rule without its why gets cargo-culted and then dropped. Write skills the way you would write process docs for an engineer who will ask "but why?"

### Add confirmation gates at dangerous transitions

Users on multiple models reported grilling sessions ending abruptly and lurching straight into implementation. The fix was an explicit gate:

```text
Do not enact the plan until I confirm we've reached a shared understanding.
```

Wherever your skill has a transition the human must control (plan → code, draft → publish, review → commit), put a literal gate sentence at it.

### Separate facts from decisions

A weirder bug: the agent would sometimes grill *itself*, answering its own interview questions (observed especially on one model — behavior differs across models). The fix was "just a couple of sentences" of leading words distinguishing **facts** — things the agent finds itself by exploring the codebase — from **decisions** — things only the user can make. Blurring the two invites the agent to usurp decisions; naming the split "made it a lot more consistent."

### Control the loudness

Parts of a prompt compete with each other "in terms of the volume and the amount of impact that they have on the final output" — Matt calls this **loudness**. The well-used `grill-with-docs` skill was "a little bit too eager to implement sometimes" because supporting text lower in the file was outshouting the core instructions. The fix: wrap the core "what you're actually doing in this skill" section and the secondary material in distinct XML tags, with the latter in a supporting-info tag, signaling it is "just slightly less prioritized." "This tends to work pretty well with Anthropic models — it's certainly in their documentation." After the change, the over-eagerness reports stopped.

### Name what the model already knows

Do not re-teach well-cited concepts — invoke them. The `/code-review` skill gained a ~10-line list of Martin Fowler's code smells from *Refactoring* (mysterious name, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, divergent change, speculative generality, message chains, middleman), one sentence each. "*Refactoring* is such an old book, such a well-cited book that these smells are deep in the agent's prior" — naming a smell is enough to activate the full concept, and the agent starts using the vocabulary back at you ("I found a middleman situation"). Ten lines, "outrageously useful" (the review workflow itself is [Chapter 8](08-review-and-qa.md)).

The same principle in the opposite direction: the `/implement` skill is deliberately minimal because harness training already teaches agents how to implement. Its full body:

```text
Implement the work described by the user in the spec or tickets.
Use TDD where possible at pre-agreed seams.
Run type checking regularly. Single test files regularly.
Full test sweep once at the end.
Once done, use code review to review the work and then commit your work
to the current branch.
```

Matt almost didn't ship it — but it "earns its place" as the named step in the flow. Leverage-the-prior cuts both ways: name cited concepts instead of explaining them, and omit anything the model reliably does anyway.

### Leave escape hatches, keep content durable

Two smaller patterns with documented payoffs:

- **Escape hatches.** The write-a-PRD skill opens with "You may skip steps if you don't consider them necessary" — and in practice the agent correctly skipped to step four after a deep grilling had already happened. Rigid step lists without an exit produce ritual, not judgment.
- **Durability.** When editing a generated skill, Matt deleted its "currently installed effect packages" list: "I only want to make recommendations here that are durable... likely not to change in the codebase." State snapshots rot; a skill should contain rules and rationale ("I like that it has a why not. That's really useful."), never inventories. The same durability logic keeps PRD implementation decisions non-prescriptive ([Chapter 5](05-idea-to-spec.md)).

## Reference Material vs Step-by-Step: The TDD Skill Redesign

Skills split into two shapes, and the TDD skill's history shows why the choice matters.

The original TDD skill was **step-by-step**: confirm interface changes with the user, confirm which behaviors to test, design interfaces for testability, then loop red/green/refactor one test at a time. It worked interactively, but it was awkward — and it broke the expectation that "you should be able to pass an AFK agent the TDD skill and it should just work." An AFK agent (see [Chapter 9](09-afk-and-parallel-agents.md)) has no user to confirm with.

The redesign made it **reference material only**: no prescribed steps, just the constraint that matters — "red before green, one slice at a time." Refactoring was removed from the loop entirely and relocated to code review, because "putting the refactoring in the code review part is a lot more productive because then you don't overload the implementation" (execution details in [Chapter 7](07-execution.md)).

> **Rule:** If a skill will ever run without a human present, it cannot depend on mid-flight confirmation. Write interactive skills as step-by-step processes with gates; write AFK-compatible skills as reference material — constraints and definitions the agent applies on its own.

This is the newest position and the recommended one: default to reference material for anything execution-shaped, and reserve step lists for skills whose entire point is a human conversation (grilling, setup, review approval).

## Skills, CLAUDE.md, or Hooks: Put Each Rule in Its Strongest Home

Not every rule belongs in a skill. Matt's instruction-budget model: an LLM "can reasonably only handle like 500 instructions" before degrading, and the conversation itself is already spending them. Every always-loaded CLAUDE.md line spends budget on every task, whether relevant or not — and it only *reduces* the chance of a violation. "By adding this, we're reducing our chances of running git push... but we're not preventing it."

For deterministic rules, hooks beat instructions outright. The canonical example: instead of a CLAUDE.md line saying "use pnpm, not npm," a PreToolUse hook script checks whether a Bash command starts with `npm`, echoes `"Use pnpm, not npm"`, and exits with code 2 — which blocks the tool call and feeds the message back to the agent, which then retries with pnpm on its own. "You get to take instructions out of your instruction budget and enforce them deterministically." The same idea extends to lint rules: Matt encoded his no-positional-parameters preference as an ESLint rule so he can "lint Claude into the right thing without needing to warn it or instruct it." (Full hook setup and the CLAUDE.md-to-hooks conversion prompt live in [Chapter 3](03-preparing-your-codebase.md).)

The decision table for where a rule lives:

| Rule shape | Home | Why |
|---|---|---|
| Environment info needed on every action | CLAUDE.md (minimal) | "The stuff inside CLAUDE.md should be extremely minimal, basically only environment info" |
| Deterministic CLI rule (substitute/forbid commands) | Hook (PreToolUse, exit 2) | Prevents instead of persuades; zero instruction budget |
| Style rule expressible as static analysis | Lint rule | Deterministic feedback loop, no warning needed |
| Situational process or rare rule | Skill | Progressive disclosure: full rationale loads only when relevant, zero standing cost |
| Non-obvious, hard-to-reverse decision | ADR | Only for decisions that are hard to reverse, surprising without context, and a real trade-off |
| Domain vocabulary | context.md glossary | Shared language shortens replies and thinking traces |
| Coding standards | Separate standards file, read at code review | "Outside your agents.md file" — review is where standards are most useful |

The skill row is the **progressive disclosure** move: when Claude Code's `/init` proposed a CLAUDE.md line about installing Effect packages with `npm install --force` — a situation that occurs rarely — Matt relocated it: "Let's put the effect package installation stuff inside a specific skill that's invoked whenever we run effect packages... it won't burn the instruction budget of the LLM." Audit any proposed always-loaded line with four questions: already hook-enforced? trivially discoverable by exploration? a maintenance coupling? how often does the situation actually occur? Only durable, non-discoverable, non-enforced, frequently-relevant lines survive.

## Setup Skills, Tracker Adapters, and Docs-as-a-Skill

Three skill genres beyond the main workflow deserve attention from authors.

**Setup/config skills.** `setup-mattpocock-skills` runs once per repo and configures everything the other skills depend on: which **issue tracker** to save specs and tickets to (GitHub, local markdown, Jira, Linear, beads — "literally anything"; you configure it conversationally: "just say 'set it up with Jira'"), the **triage labels** the skills use to communicate about tickets, and the **domain documentation** layout (`context.md` plus ADRs; single context for 99% of people, multi-context only for big monorepos). It then writes short links into CLAUDE.md pointing at `docs/agents/issue-tracker`, `docs/agents/domain`, and the triage-labels docs — pointers, not inlined content. The authoring lesson: if your skill set has environmental assumptions, ship a setup skill that materializes them as configuration the other skills read, rather than hard-coding one tracker or layout. People constantly asked "how do I make the skills work with Jira?" — the adapter approach means the answer is to tell it during setup, no custom work required.

**Docs-as-a-skill.** `/ask-matt` is "essentially me as a skill" — it knows everything about the skills repo and works as an interactive tutorial: "ask Matt, how do I get started?... What is the main flow I should use?" and it walks you through the flow, stateful in a repo. Instead of (or alongside) a README nobody reads, package your workflow's documentation as a skill the agent answers questions from.

**Skills for learning.** `/teach` (above) closes the loop: the same authoring machinery that encodes your dev process can encode your teaching process, including onboarding engineers onto the codebase your other skills operate in. Matt's larger claim: developers are the first movers with AI because AI is best at code — "we can take the ideas that we develop here, turn them into skills and start bringing them out to the world."

## A Worked Skeleton: /handoff, Line by Line

`/handoff` is the most completely documented skill in the sources and small enough to study whole. Reconstructed from the video walkthroughs (metadata syntax varies by harness; the parts are what matter):

```markdown
description: Compact the current conversation into a handoff document
  for another agent to pick up.

# Handoff

Write a handoff document summarizing the current conversation so a
fresh agent can continue the work.

Save it to the temporary directory of the user's operating system,
not the current workspace. Read the file before you write to it.

Include a suggested-skills section in the document which suggests
skills that the next agent should invoke.

Do not duplicate content already captured in other artifacts.
Reference them by path or URL instead.

Redact any sensitive information: API keys, passwords, or PII.

If the user passed arguments, treat them as a description of what
the next session will focus on and tailor the doc accordingly.
```

Why each line earns its place:

- **Description** — one precise sentence; the only text that costs context before invocation.
- **Core task first** — a single sentence stating the job, at the top where it is loudest.
- **Temp directory** — encodes a judgment: handoff files are disposable transport, "not something to be kept around... to rot in your codebase as documentation."
- **Read before write** — pure harness handholding for a Claude Code quirk. Skills absorb tool quirks so users never see them.
- **Suggested skills** — composition: the handoff must transfer "not only... the content of the context window... also the vibe of the context window and the intent of the context window," including which skills should flavor the next session.
- **Pointers over duplication** — added after handoff docs "were getting really big"; reference artifacts by path or URL.
- **Redaction** — a safety rule at exactly the point it matters (secrets in stray markdown files).
- **Arguments as focus** — the skill degrades gracefully with no arguments but is designed for them: "I just can't see how you would write a good handoff document otherwise."

Notice the shape: every sentence is either the task, a durable judgment with a reason behind it, or a quirk workaround. Nothing is a state snapshot, nothing duplicates a hook, nothing re-teaches the model something it already knows. For a stateful skill, you would add a workspace-shape section (as in `/teach`); for a bigger skill, a supporting-info block in XML tags below the core task.

## Installing, Distributing, and Migrating

Skills are files in a repo, so distribution is a solved problem — mattpocock/skills had reached 162k GitHub stars and 7.5 million downloads at last count.

**Installing:**

```bash
npx skills@latest add mattpocock/skills
```

The skills.sh CLI installer (from Vercel; requires Node.js) walks you through: which skills to install (the repo splits into blessed public-facing skills and experimental "other skills"), which agents to configure (universal support for Cursor, Codex, Cline; Claude-skills agents like Claude Code selected explicitly), what scope, and the install method. Two decisions matter:

- **Scope — project vs global.** Project-level for teams: everyone shares the same skill set per project and can contribute to skills together. Global is fine for a solo developer.
- **Method — always symlink.** The copy alternative duplicates files into the agents folder as well as `.claude` and is "not a nice way to do it" — "I wouldn't even make a decision here. Just choose symlink."

The flow is identical for brownfield and greenfield: run it in your repo or an empty directory.

**Updating and migrating renames.** `npx skills update` grabs new versions of everything. But renames are not auto-migrated: when `/to-prd` became `/to-spec` and `/to-issues` became `/to-tickets` in v1.1, the installer could not convert the old skills into the new ones. The documented migration:

1. Delete the old skills and re-add with `npx skills add <repo>`, picking the skills you want (the safest route).
2. Do a pass through your skills folder and confirm no stale skills remain — "make sure you're intentionally grabbing all the right skills."
3. If you would rather not pick, clear out all your skills and run `npx skills update` to grab everything fresh.
4. If you have modified skills locally, point your agent at the upstream repo and the release notes and ask it to "pull down all of the good new stuff" — a merge the agent can do that the installer cannot.

The renames themselves carry an authoring lesson: they were "a little bit of friction, but good friction because it names it properly." A PRD describes a product; what the skill produced was a spec — and the misnaming let non-spec content "leak into the PRD." Rename skills when the name is wrong, and accept the migration cost.

## Testing Across Models and the Changelog Discipline

Skills run on whatever harness, model, and effort level each user has — Matt develops on Claude Code with Opus on medium effort but explicitly supports users elsewhere. That makes **cross-model behavior a first-class testing concern**: the self-grilling bug surfaced "especially" on one model while others were fine; the premature-implementation bug came in from "users on different models." You cannot test a skill on your own setup and call it done.

The documented testing regime, honestly, is dogfooding plus user reports rather than formal evals — and Matt flags the gap himself: the loudness fix shipped on "vibes... I'm not doing evals here. Maybe I should be doing evals on this particular case." The evidence standard he used instead: the user bug reports stopped. He also iterates by using his own skills in anger — `/teach` grew its glossary and community-footer elements because he noticed he needed them mid-use. The Fowler-smells addition to `/code-review` was tested for a couple of weeks before shipping.

What makes this iteration safe for users is the **changelog discipline**:

- **Version releases with named changes.** v1.1 shipped as a reviewed PR with release notes; each change (renames, grilling fixes, TDD redesign) was announced and explained.
- **Blessed vs experimental tiers.** The installer distinguishes public-facing skills from experimental ones that "may be deleted later." In-progress skills (`/review`, the writing pipeline) are visible but flagged: "I don't think they're going to be ready anytime soon, but you're free to try them if you like."
- **Graduation.** `/code-review` was "in progress" in v1.0 and graduated in v1.1 after real-world testing. Skills earn blessed status; they don't launch with it.
- **A channel for updates.** A newsletter carries skill changelogs and usage tips, because "I do change the skills all the time" — distribution without communication produces stale installs.

For a team ([Chapter 11](11-team-blueprint.md)), this maps directly: project-scoped skills in the shared repo, an experimental area for skills under trial, explicit graduation into the blessed set, and release notes so every agent user knows what changed. That is how "no such thing as a skill issue" becomes literally true — when a skill misfires for one person, the fix ships to everyone.

## Checklist

The skill authoring checklist — run a new or changed skill through every line:

- [ ] Does this workflow recur often enough to be a skill? (You typed it manually three times → yes, even if it feels "too simple.")
- [ ] Is a skill the right home at all — or is this rule deterministic (hook / lint), environment info (CLAUDE.md), a decision record (ADR), or vocabulary (context.md)?
- [ ] Description is one short, precise sentence — it is all the model sees until invocation.
- [ ] User-invoked by default; model-invoked only if another skill or situation must trigger it, and then marked `user-invocable: false`.
- [ ] Stateless or stateful decided deliberately: does it need memory of previous runs? If stateful, the workspace shape (files read at start, written in progress) is documented in the skill.
- [ ] Core task stated first; supporting material wrapped in XML tags so it cannot outshout the task (loudness).
- [ ] Every behavioral rule carries its WHY ("asking multiple questions at once is bewildering").
- [ ] Confirmation gates at every transition the human must control ("Do not enact the plan until I confirm...").
- [ ] Facts (agent discovers by exploring) explicitly separated from decisions (user makes).
- [ ] Well-cited concepts named, not re-taught (Fowler smells); anything the harness already trains for omitted (`/implement` minimalism).
- [ ] Escape hatch present where judgment applies ("You may skip steps if you don't consider them necessary").
- [ ] No state snapshots; only durable recommendations. Rationale kept ("why not" sections); inventories deleted.
- [ ] AFK-compatible skills written as reference material, not user-confirmation steps ("red before green, one slice at a time").
- [ ] Harness quirks absorbed into the skill ("read the file before you write to it"), not left for users to discover.
- [ ] Composition considered: which skills should suggest this one; which should it suggest or invoke?
- [ ] Installed at project scope for teams (shared, jointly improvable), global only for solo use; symlink, never copy.
- [ ] Renames handled as delete-and-re-add plus a stale-skill audit — the installer will not migrate them.
- [ ] Tested beyond your own model/harness; user reports from other models treated as bugs.
- [ ] Shipped through the changelog: experimental first, graduated when proven, release notes for every change.

## Sources

- Learn anything with the /teach skill
- 5 Claude Code skills I use every single day
- How to actually force Claude Code to use the right CLI (don't use CLAUDE.md)
- New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- 9 Things People Get Wrong With My /grill-* skills
- Claude Code tried to improve /init... Is it any better?
- I stopped using /grill-me for coding. Here's what I use instead:
- /handoff is my new favourite skill

See also: [Chapter 1](01-how-llms-actually-work.md) for the context-window model behind the context tax; [Chapter 3](03-preparing-your-codebase.md) for hooks, CLAUDE.md, and repo docs in full; [Chapter 4](04-the-workflow.md) for where each skill sits in the end-to-end flow; [Chapter 7](07-execution.md) for the TDD skill in use; [Chapter 8](08-review-and-qa.md) for the two-axis review skill; [Chapter 11](11-team-blueprint.md) for rolling skills out across a team; [Chapter 12](12-skill-catalog.md) for the full catalog of every skill named here.
