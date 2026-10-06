# 13. Glossary: The Ubiquitous Language of AI-Driven Development

This guide teaches you to maintain a **ubiquitous language** — one precisely defined vocabulary shared by the code, the developers, the domain experts, and the agent — because "the same techniques that work with humans also, it turns out, work with AI." This chapter is the guide practicing what it preaches: every term of art used in the previous twelve chapters, defined in one to three sentences, with a link to the chapter where it is developed. Use these terms exactly — in tickets, in prompts, in skills, in conversation — and both your teammates and your agents will know precisely what you mean.

## A–C

**ADR (Architectural Decision Record)** — A short markdown file in the repo recording a non-obvious decision. Create one only when the decision is hard to reverse, would be surprising without context, and is the result of a real trade-off; easily reversible choices (interchangeable library picks) don't qualify. The out-of-scope ADR variant (a `.out-of-scope/` directory) records features you have decided never to build, so triage can auto-close matching requests. See [Chapter 5](05-idea-to-spec.md) and [Chapter 6](06-tickets-and-planning.md).

**AFK execution** — An agent working without a human at the keyboard ("away from keyboard"): Ralph loops, Sandcastle pipelines, overnight runs. Safe only with sandboxing, verifiable feedback loops, and a triaged backlog to draw from. See [Chapter 9](09-afk-and-parallel-agents.md).

**agent** — An LLM calling tools in a loop, where the LLM itself decides when to stop (the Anthropic definition). Each tool result feeds new information into the next call; a single LLM call is neither an agent nor a workflow — "it's just a freaking API call." Contrast with **workflow**. See [Chapter 1](01-how-llms-actually-work.md).

**attention degradation** — The decline in output quality as the context window fills: the attention mechanism prioritizes the start and end of context, so middle content gets lost ("lost in the middle"), and past roughly 120–140k tokens the model "ends up getting stupider, does weird hallucinations." The mechanical reason the **smart zone** exists. See [Chapter 1](01-how-llms-actually-work.md).

**auto mode** — The harness mode in which the agent's edits are accepted automatically (Claude Code's default), as opposed to plan mode or manual approval. The main flow runs in auto mode — but turn it off for human-in-the-loop skills such as the de-slopping flow, where it "does funny things." See [Chapter 4](04-the-workflow.md) and [Chapter 8](08-review-and-qa.md).

**blocking relationship** — A dependency between tickets: a blocked ticket may not start until the tickets blocking it are closed. Blocking relationships turn a flat backlog into a **kanban board** and define the parallelization frontier — any unblocked ticket can be handed to an agent right now. Wayfinder establishes blocking relationships between decision tickets so the frontier moves as the fog clears. See [Chapter 6](06-tickets-and-planning.md).

**CLAUDE.md / AGENTS.md** — The repo-level context file a harness injects into every session's system prompt. Keep it near-empty: only minimal, non-discoverable, non-rotting environment facts (the canonical example is a single line, "you are on WSL on Windows") plus pointers to domain docs. See [Chapter 3](03-preparing-your-codebase.md).

**claw** — A persistence layer above an agent harness: it keeps looping, has its own sandbox and a memory system more sophisticated than compact-on-overflow, and acts on your behalf when you're not looking, typically behind a messaging portal such as WhatsApp. Peter Steinberger's OpenClaw — with its SOUL.md personality document — is the reference implementation. See [Chapter 9](09-afk-and-parallel-agents.md).

**compaction (`/compact` vs `/clear`)** — `/compact` summarizes the current conversation so the *same* session can continue with a fresh window; `/clear` wipes it. Clear is the default; compact only when you must barrel on at the same problem (debugging) and need to preserve the session's intent; use a **handoff** when the work should move to a *different* session. See [Chapter 7](07-execution.md).

**context engineering** — "The craft of deciding exactly what the model should see and what it shouldn't, at each step": curating the smallest set of high-signal tokens rather than writing bigger prompts. Its four moves are write, select, compress, isolate. See [Chapter 1](01-how-llms-actually-work.md).

**context poisoning / distraction / confusion / clash** — The four named context failure modes: **poisoning** (a hallucinated fact enters context and is reused over and over), **distraction** (the model fixates on a huge history instead of making a fresh plan), **confusion** (extra unrelated details nudge it to the wrong answer), and **clash** (two sources disagree and the model picks the wrong one). Naming the failure points back at the Write / Select / Compress / Isolate fix kit: poisoning is contained by isolating the noisy source, distraction is reclaimed by compressing a huge history back down. See [Chapter 1](01-how-llms-actually-work.md).

**context stack** — The seven pieces a model actually sees at runtime: instructions, user input, retrieved facts, tools, short-term notes, long-term memory, and output format. Context engineering means curating each piece before every call. See [Chapter 1](01-how-llms-actually-work.md).

**context window** — Everything the LLM sees at one time — system prompt, messages, tool results, and its own output — up to a hard provider limit. All of it counts against the limit, and performance degrades well before you reach it (see **smart zone**, **attention degradation**). See [Chapter 1](01-how-llms-actually-work.md).

**context.md** — The repo-root glossary file recording the ubiquitous language of one bounded context: a short description of the repo, then a precise definition of every entity and term ("standalone video: a video with lessonId = null"). Pointed to from the local CLAUDE.md; large monorepos use a context map of several contexts. Renamed to **glossary.md** in skills v1.3 — "Context.md just felt way too vague. It didn't sort of trigger the agent to pull it in at the right moment" — because file names are triggers. See [Chapter 3](03-preparing-your-codebase.md) and [Chapter 5](05-idea-to-spec.md).

## D–G

**day shift / night shift** — The division of labor at the heart of the workflow: the human does the thinking work — ideation, grilling, specs, ticket slicing — in the day shift; agents execute AFK in the night shift. See [Chapter 4](04-the-workflow.md).

**decision ticket** — A Wayfinder sub-issue that resolves *what to build* (typed research, grilling, prototype, or task) — not an **implementation ticket**. Decision tickets live on the **wayfinder map**; each is scoped to one agent session and its resolution is written back into the parent map. Implementation tickets are produced later by `/to-tickets`. Confusing the two is a common beginner mistake: "when people first use Wayfinder." See [Chapter 5](05-idea-to-spec.md) and [Chapter 6](06-tickets-and-planning.md).

**deep module** — A module that hides a lot of implementation behind a simple interface; **depth** is "the amount of behavior a caller can exercise per unit of interface they have to learn" (from Ousterhout's *A Philosophy of Software Design*). Deep modules give callers leverage and maintainers locality; their opposite, **shallow modules** (complex interface, little behind it), are the signature of an AI-hostile codebase. See [Chapter 3](03-preparing-your-codebase.md).

**de-slopping** — The systematic cleanup of accumulated slop: architecture-deepening refactors driven by the improve-codebase-architecture skill, run human-in-the-loop every few days. Not an AFK skill — the candidates require a judgment call from the strategic programmer sitting above the agent. See [Chapter 8](08-review-and-qa.md).

**explore subagent** — A subagent (often on a cheap, fast model such as Haiku) that reads many files in its own context window and hands only a summary back to the parent agent. It is how harnesses build just-in-time context — and the reason pre-baked codebase documentation is mostly redundant. See [Chapter 1](01-how-llms-actually-work.md) and [Chapter 5](05-idea-to-spec.md).

**facts vs decisions** — The grilling distinction that stops an agent interviewing itself: **facts** are things the agent can discover by exploring the codebase; **decisions** can only be made by the human. A grilling agent must fetch facts and ask only about decisions. See [Chapter 5](05-idea-to-spec.md).

**feedback loop** — A deterministic signal that tells an agent whether its change actually worked: types, tests, lint rules, green CI, a browser it can screenshot. Feedback loops impose "back pressure" on an eager model, make autonomy safe, and improving them is "the entire point now of having a good codebase." See [Chapter 3](03-preparing-your-codebase.md).

**fog of war** — See **frontier vs. fog**.

**frontier vs. fog** — The two sets a **wayfinder map** tracks: the **frontier** = decisions takable right now (because nothing unresolved blocks them); the **fog** = decisions blocked behind others that must be resolved first. Fog "does not resolve cleanly" — you clear it by working the frontier ticket by ticket, each in its own session, until the route to the destination is visible. As frontier tickets close, fog recedes and new tickets unblock. See [Chapter 5](05-idea-to-spec.md) and [Chapter 6](06-tickets-and-planning.md).

**ghost entity** — The guide's worked example of domain language, from Matt Pocock's course video manager: a ghost lesson or ghost course is one that "exists in the database but not yet on the file system." Defined precisely in the repo's glossary so human and agent mean the same thing by "ghost." See **materialize** and **ubiquitous language**. See [Chapter 3](03-preparing-your-codebase.md).

**gray-box architecture** — Deep modules where the human designs and owns the interface (the seam, where taste is applied) and the AI owns the implementation inside, locked down by tests: "as long as the tests are good, then I don't really need to care about what happens inside." Neither black box nor white box — you look inside only to apply taste or tune performance. See [Chapter 2](02-principles.md).

**grillable vs ungrillable question** — Fidelity language (borrowed from Ryan Singer's *Shape Up*): low-fidelity questions ("what URL should this route live on?") are answerable by pure Q&A — grillable; high-fidelity questions ("how will this UI feel?") can only be answered by a prototype — ungrillable. Never try to answer ungrillable questions inside a grilling session. See [Chapter 5](05-idea-to-spec.md).

**grilling** — An interview session where the agent asks the human questions, one at a time, to harden an idea: "interview me relentlessly about every aspect of this plan until we reach a shared understanding," walking down each branch of the design tree. The guide's replacement for plan mode. See [Chapter 5](05-idea-to-spec.md).

## H–L

**handoff** — Compressing the relevant slice of a session's state into a disposable markdown document (saved to the OS temp dir, never the repo) that a fresh session — in any harness — can resume from. A good handoff transfers "not only the content of the context window… also the vibe of the context window and the intent," plus suggested skills for the next session; the round-trip version (hand off to a prototype session, hand the learnings back) is the **DIY subagent** pattern. See [Chapter 7](07-execution.md).

**harness** — The agent product wrapping the model: Claude Code, Cursor, Codex CLI, VS Code agent mode. The harness supplies the tool loop, the system prompt, permissions, and features like plan mode, subagents, hooks, and worktrees. See [Chapter 1](01-how-llms-actually-work.md).

**hooks** — Deterministic code the harness runs at fixed points in its execution cycle — e.g. a PreToolUse hook that blocks a bash command and echoes a corrective message ("Use pnpm, not npm", exit code 2). Hooks enforce rules that instructions can only make probable, and free up instruction budget while doing it. See [Chapter 3](03-preparing-your-codebase.md).

**instruction budget** — The rough limit of ~300–500 instructions an LLM can follow before it gets "less and less powerful and more and more confused." Every always-loaded rule — CLAUDE.md lines, MCP tool descriptions — spends budget the actual task needs; hooks, skills, and lean context files protect it. See [Chapter 1](01-how-llms-actually-work.md) and [Chapter 3](03-preparing-your-codebase.md).

**intrinsic vs extrinsic information** — Intrinsic = information supplied in the current context (files, code, search results); extrinsic = the model's lossily compressed training-set memory. Models are far more reliable on intrinsic information — hence "use your search tool" and feeding code before asking about it. See [Chapter 2](02-principles.md).

**jaggedness** — The uncoupled ability profile of models: talking to "an extremely brilliant PhD student who's been a systems programmer for their entire life — and a 10-year-old," simultaneously. Caused by the RL training boundary — models improve only in verifiable domains, and code-smartness has not generalized to everything else. See [Chapter 1](01-how-llms-actually-work.md).

**kanban board** — A list of tickets plus the blocking relationships between them. The unblocked tickets are the parallelization frontier: one agent per unblocked ticket. See [Chapter 6](06-tickets-and-planning.md).

**low-fi planning + high-fi feedback** — The Wayfinder principle "Huge amounts of low-fidelity upfront planning. A prototype is a high-fidelity way to get feedback on what you're actually building." The combination is what keeps Wayfinder's dense planning from being waterfall — the cheap maps handle the route-finding, the prototypes handle the taste. See [Chapter 5](05-idea-to-spec.md).

## M–P

**main flow** — The canonical skills pipeline all work runs through: grill-with-docs → (prototype via handoff when a question needs a runnable answer) → then either implement in the same session, or to-spec → to-tickets → implement one ticket per session, with code review built into implement. See [Chapter 4](04-the-workflow.md).

**materialize** — The domain verb paired with **ghost entity**: "the act of transitioning a ghost entity to a real entity by creating its on-disk representation" — with "aliases to avoid" (create on disk, realize) recorded in the glossary. The payoff of this precision: "there's a bug inside the materialization cascade" is instantly unambiguous to both human and agent. See [Chapter 3](03-preparing-your-codebase.md).

**merge danger / blast radius** — The two review-calculus fields every PR body carries: merge danger states whether the change is a **one-way door** (hard to roll back — deletes data, expensive to revert) or a **two-way door** ("a door that you can walk back through" — easily reverted); blast radius states the potential ramifications of the changes. Small blast radius + two-way door → light review; dangerous changes demand hard review. Verification can turn one-way doors into two-way doors — a verified, cheaply revertible merge is no longer one-way. See [Chapter 8](08-review-and-qa.md).

**model prior** — What the model already knows from training (also called **parametric knowledge**, as opposed to the contextual knowledge you supply in the window). Skills lean on it: name a well-cited concept ("message chains," "red before green") and you unlock knowledge "deep in the agent's prior" instead of re-teaching it. Grilling leans on it too — which is why planning wants a frontier model while implementation tolerates a dumber one. See [Chapter 7](07-execution.md) and [Chapter 5](05-idea-to-spec.md).

**plan mode** — A harness mode (Shift+Tab in Claude Code) that disables file writes and swaps in a plan-focused system prompt, forcing explore-then-plan before any code. It was the gateway to structured AI work; the guide's current recommendation replaces it with grilling, which reaches shared understanding *before* any plan document exists. See [Chapter 5](05-idea-to-spec.md).

**PRD (product requirements document)** — A destination document describing the product: problem statement, solution, user stories, and deliberately non-prescriptive implementation decisions so it stays durable against the code. The skill that produced them was renamed `/to-spec` because "specification is a much broader term" — PRD survives as the product-flavored subtype of **spec**. See [Chapter 5](05-idea-to-spec.md).

**progressive disclosure** — Revealing information only at the moment it becomes relevant: skills discovered on demand instead of always-loaded CLAUDE.md rules; module interfaces read before implementations. The organizing principle behind both context files and gray-box codebases. See [Chapter 3](03-preparing-your-codebase.md).

**prompt loudness** — The observation that parts of a prompt compete with each other "in terms of the volume and the amount of impact that they have on the final output." Structure controls the volume: wrap secondary material in XML tags (e.g. `<supporting_info>`) to turn it down so the core instructions win. See [Chapter 10](10-building-skills.md).

**prototype (logic vs UI)** — A cheap, throwaway artifact built to "raise the fidelity of the discussion" and answer ungrillable questions. **UI prototypes** render radically different variations in the actual route with a toggle to compare and combine; **logic prototypes** are tiny interactive terminal apps that push a state machine through cases hard to reason about on paper. See [Chapter 5](05-idea-to-spec.md).

## Q–S

**QA plan** — An agent-generated, step-by-step guide for a human to test completed work ("a step-by-step guide on how to test every single part of the new implementation"), saved as a ticket marked human-only so AFK agents skip it, and closed once behavior drifts so it stops being treated as source of truth. Findings become new tickets. See [Chapter 8](08-review-and-qa.md).

**Ralph loop** — A fresh-context agent loop over a backlog (from Geoffrey Huntley's Ralph Wiggum technique): a bash for-loop that repeatedly invokes a CLI coding agent — pick the highest-priority item, implement it, mark it done, append learnings to a progress log, commit — until the backlog is empty or max iterations is hit. Each iteration is a fresh context window, which is the whole point. See [Chapter 9](09-afk-and-parallel-agents.md).

**research rot** — The decay of cached research: a `research.md` asset "can go out of date or it can just rot away… and actually cause our agent to take a wrong turn." Research assets live only for the sprint that produced them — delete them after. See [Chapter 5](05-idea-to-spec.md).

**sandbox** — An isolated execution environment (typically a Docker container) where an agent runs without permission prompts and without endangering the host. The prerequisite for AFK execution and the safe alternative to **YOLO mode**. See [Chapter 9](09-afk-and-parallel-agents.md).

**Sandcastle** — Matt Pocock's open-source TypeScript library for orchestrating coding agents in isolated sandboxes around one primitive — `sandcastle.run({agent, sandbox, prompt})` — composing planner → parallel implementers → reviewer → merger pipelines from a labeled GitHub backlog. The guide's reference implementation of a "mini software factory." See [Chapter 9](09-afk-and-parallel-agents.md).

**seam** — The gap between modules where an interface lives: the place unit and integration tests attach, and where human taste is applied in a gray-box architecture. An **adapter** is a concrete module satisfying the interface at a seam — a real clock in production, a fake clock in tests. See [Chapter 3](03-preparing-your-codebase.md).

**side quest** — Work that surfaces mid-session but doesn't belong to the session's task. Handle it without polluting the session: spin it out via handoff (fire-and-forget, or round trip), or use an out-of-history "by the way" question for quick orientation. See [Chapter 7](07-execution.md).

**skill** — A reusable, versioned instruction set invoked in an agent harness (e.g. `/grill-me`) — not a "command," not a "plugin." Two design axes: **stateless** (each run self-contained, nothing persisted) vs **stateful** (persists state — glossaries, ADRs, learning records — to the file system so later sessions resume and compound); and **user-invoked** (a human types the slash command) vs **model-invoked** (the agent pulls it in when its description matches the situation). See [Chapter 10](10-building-skills.md).

**slop** — Plausible-looking, low-quality AI output: code that works but degrades the codebase — scattered conditionals, optional-prop creep, duplicated parallel implementations, shallow modules. The reviewer's verdict that names it best: "the behavior is correct in all three substantive PRs, but the codebase is meaningfully messier than it was a week ago." See [Chapter 8](08-review-and-qa.md).

**smart zone** — The usable portion of the context window before attention degradation: roughly the first 140k tokens on current Claude models (estimates in the sources range 120–140k), regardless of the advertised window size. Past it lies the **dumb zone** — strained attention, stupider decisions. Every ticket and session is sized to fit one smart zone. See [Chapter 1](01-how-llms-actually-work.md).

**spec** — The destination document: "the description of everything of how it's going to look at the end," compressed out of a grilling session (problem statement, solution, user stories, implementation and testing decisions) and published to the issue tracker. The spec is the destination; the **tickets** are the journey. See [Chapter 5](05-idea-to-spec.md).

**subagent** — An agent spawned by a parent agent, with its own clean context window, that returns only a digest to the parent. Used to isolate token-heavy work (exploration) and to get fresh eyes (review) — "agents are often really bad at editing code or improving code they've just written because they wrote it." See [Chapter 1](01-how-llms-actually-work.md) and [Chapter 8](08-review-and-qa.md).

## T–Z

**ticket** — One unit of the journey from spec to shipped: a thin vertical slice sized to a single context window / smart zone, with acceptance criteria and a reference to its parent spec. Implement one per session, clearing between tickets. (Renamed from "issues" because tickets is tracker-neutral.) See [Chapter 6](06-tickets-and-planning.md).

**token** — The unit LLMs read, think, and bill in: text encoded into numeric IDs from a model-specific vocabulary, which is why the same text costs different token counts on different providers. "Tokens are the currency of LLMs." See [Chapter 1](01-how-llms-actually-work.md).

**triage** — Turning a messy human backlog into agent-actionable work via a label state machine: every issue carries exactly one category role (bug, enhancement) and exactly one state role (needs triage, needs info, ready for agent, ready for human, won't fix). Moving an item to *ready for agent* requires writing an agent brief; AFK agents pick up only tickets bearing that label. See [Chapter 6](06-tickets-and-planning.md).

**ubiquitous language** — Domain-Driven Design's core idea (Eric Evans), extended to agents: the codebase, the developers, the domain experts — and now the AI — speak one precisely defined shared language within a bounded context, recorded in `context.md`. The terms chosen become every variable name, file name, and UI label, so getting them right is not bike-shedding. This glossary is the guide's own ubiquitous language. See [Chapter 3](03-preparing-your-codebase.md).

**verifiability gate** — Karpathy's rule for autonomy: "If you can't evaluate it, then you can't auto-research it." Full autonomy works only where an objective, cheaply evaluable signal exists — tests, types, a metric; everything else still needs a human judge. See [Chapter 2](02-principles.md) and [Chapter 9](09-afk-and-parallel-agents.md).

**vertical slice** — The ticket-slicing rule: "each issue is a thin vertical slice that cuts through all integration layers, not a horizontal slice of one layer." Slices are ordered to flush out unknown unknowns first — the tracer-bullet idea. See [Chapter 6](06-tickets-and-planning.md).

**wayfinder map** — A parent issue on the repo's tracker charting the route from a foggy, too-big idea to a spec: every open decision becomes a sub-issue typed research, grilling, prototype, or task, each scoped to one agent session, wired together with blocking relationships. Work the tickets one at a time "until the route is clear," then feed the completed map to `/to-spec`. See [Chapter 5](05-idea-to-spec.md) and [Chapter 6](06-tickets-and-planning.md).

**workflow** — The counterpart of **agent**: predetermined code paths, known ahead of time and written in code, with LLM calls embedded. Workflows can be optimized (parallelized, tuned) precisely because the path is known; agents improvise. Real systems sit on a spectrum between the two. See [Chapter 1](01-how-llms-actually-work.md).

**worktree** — An isolated git checkout (`git worktree`, or `claude --worktree`) giving each agent its own working copy so parallel agents don't interfere. Lifecycle rule: one worktree per agent task, PR back to main — and push to an explicitly named branch, because a worktree tracks the branch it was created from. See [Chapter 7](07-execution.md).

**YOLO mode** — Running an agent with all permission checks bypassed. Off-limits outside a sandbox: "Claude will do mad things on your system like delete your home directory." See [Chapter 9](09-afk-and-parallel-agents.md).

**zone of proximal development** — The teaching zone where a learner is "perfectly challenged but not intimidated." The `/teach` skill keeps every lesson inside it via persisted learning records — the argument for agent-driven onboarding over static docs, which sit outside almost every individual reader's zone. See [Chapter 10](10-building-skills.md).

## Checklist

- [ ] Use **spec** for the destination and **tickets** for the journey — never interchangeably.
- [ ] Keep a `context.md` glossary at the repo root and update it at the end of every grilling session, before committing.
- [ ] Pin down new domain terms *before* implementing — they become every variable name, file name, and UI label.
- [ ] Record "aliases to avoid" alongside each term so fuzzy synonyms get challenged, not absorbed.
- [ ] Embed a terminology glossary inside skills that need one, so agent and human argue from the same words.
- [ ] Invoke well-cited named concepts (Fowler smells, red-green, deep modules) by name instead of re-explaining them — they are in the model prior.
- [ ] Write an ADR only for decisions that are hard to reverse, surprising without context, and real trade-offs.
- [ ] Cut vocabulary bike-shedding when it stalls: "That's good enough. Let's ship with this. We can always change and refactor to new language later."
- [ ] When a teammate — or an agent — uses a term loosely, challenge it against the glossary.

## Sources

- Most devs don't understand how context windows work
- Most devs don't understand how LLM tokens work
- Most devs don't understand what agents are
- Context Engineering Explained: Stop Padding Prompts, Curate What the Model Sees
- Never Trust An LLM
- Never Run claude /init
- Claude Code tried to improve /init... Is it any better?
- How to actually force Claude Code to use the right CLI (don't use CLAUDE.md)
- Your codebase is NOT ready for AI (here's how to fix it)
- How To De-Slop A Codebase Ruined By AI (with one skill)
- I stopped using /grill-me for coding. Here's what I use instead
- 9 Things People Get Wrong With My /grill-* skills
- I was an AI skeptic. Then I tried plan mode
- How I use Claude Code for real engineering
- The 7 phases of AI-driven development
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- New Skills! /handoff, /prototype, /review and /writing-*
- /handoff is my new favourite skill
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- 5 Claude Code skills I use every single day
- Building a REAL feature with Claude Code: every step explained
- Red Green Refactor is OP With Claude Code
- Frontend is HARDER for AI than backend (here's how to fix it)
- Can Cursor's HARDCORE Review Skill Stop The Slop?
- Burn through the backlog from hell with /triage
- Ship working code while you sleep with the Ralph Wiggum technique
- I Open-Sourced My Own AFK Software Factory
- I'm using claude --worktree for everything now
- Learn anything with the /teach skill
- /wayfinder: Nothing is too big to plan anymore
- Andrej Karpathy on No Priors: Agentic Coding, Claws, Auto-Research & the Post-December Workflow Shift

See also: [Chapter 1](01-how-llms-actually-work.md) · [Chapter 2](02-principles.md) · [Chapter 3](03-preparing-your-codebase.md) · [Chapter 4](04-the-workflow.md) · [Chapter 5](05-idea-to-spec.md) · [Chapter 6](06-tickets-and-planning.md) · [Chapter 7](07-execution.md) · [Chapter 8](08-review-and-qa.md) · [Chapter 9](09-afk-and-parallel-agents.md) · [Chapter 10](10-building-skills.md) · [Chapter 11](11-team-blueprint.md) · [Chapter 12](12-skill-catalog.md)
