# 3. Preparing Your Codebase: The Environment Determines Quality

Most developers who get bad output from a coding agent blame their prompts. The evidence in the source material points the other way. The repository the agent wakes up in — its architecture, its feedback loops, its documentation, its enforcement machinery — determines output quality far more than any prompt. This chapter shows exactly how to prepare that environment: feedback loops first, then modular architecture, then domain documentation, then a near-empty CLAUDE.md backed by deterministic hooks, and finally the extra work frontend code demands. It ends with a repo readiness checklist you can run against any repository.

## The Codebase Beats the Prompt

Matt Pocock's core claim is blunt: "Your codebase, way more than the prompt that you used, way more than your agents.md file, is the biggest influence on AI's output."

The reason comes from how agents encounter your code. An agent has no memory of your repository. Every session, "it's like the guy from Memento who just steps in and goes, 'Okay, I'm here. Uh, what am I doing?'" It does not arrive knowing every function, every module, and how they link together. The right mental model is not a superpowered developer approaching AGI — it is a **new starter** in your codebase, with some weird limitations. And you will be "spawning like 20 new starters every day or probably more." A codebase that is hostile to new starters is hostile to every one of those sessions.

A badly designed codebase imposes three concrete costs on agent work:

1. **No fast feedback.** The agent doesn't find out whether its change did what it intended.
2. **Poor sense-making.** It struggles to find files and work out how to test things.
3. **Your cognitive burnout.** You end up trying to hold the AI and the codebase together in your head.

The upside of this diagnosis is that the fix is not exotic. "Software quality matters more than ever" — how easy your codebase is to change directly determines how well AI can change it, and the software best practices we've known for twenty years hold "more true than ever." Everything in this chapter is a variation on that theme: what works for a well-onboarded human new starter works for the agent.

> **Why it works:** You hold the mental map of the codebase; the agent only sees the raw file system, the tests, and the docs. Preparation is the act of externalizing your mental map into artifacts the agent can discover.

## Feedback Loops Are the #1 Quality Lever

If you do only one thing from this chapter, do this: give the agent fast, deterministic feedback on every change. "Tests and feedback loops are essential for an AI because of course they're essential for a new starter joining the codebase. If you want the new starter to contribute effectively, you need a well-tested codebase so they can see what their changes do as they ripple out."

The standard textual feedback loops are:

- **Type checking** — run regularly during implementation, not just at the end.
- **Tests** — unit and integration tests that lock down module behavior; single test files run frequently, a full sweep once at the end of a session.
- **Lint** — style and correctness rules encoded as ESLint (or equivalent) rules.
- **Build** — verified before commit.

These are not optional niceties; they are the load-bearing infrastructure of every AFK technique in this guide. In Matt's Ralph loop setup (see [Chapter 9](09-afk-and-parallel-agents.md)), the "crucial success factor" was "making sure it runs tests and types on every single commit." His `/implement` skill bakes the same cadence in: type checking regularly, single test files regularly, full test sweep once at the end. Pre-commit hooks running unit tests, linting, and type checking mean the agent sees errors at the moment it commits.

There is a deeper principle here: **feedback loops beat instructions**. Matt hates positional parameters in functions. Instead of writing "don't use positional parameters" into an instructions file — an instruction the agent may or may not follow — he encoded it as an ESLint rule, so he can "lint Claude into the right thing without needing to warn it or instruct it." A lint rule is deterministic; a written instruction is probabilistic and burns the agent's limited instruction budget (more on that budget below). As he puts it: "Creating these feedback loops for Claude is so, so powerful."

> **Rule:** Any quality rule that CAN be expressed as a deterministic check (lint rule, type constraint, test, hook) should be — never as prose instructions to the agent.

And a check that exists but nothing runs is not a feedback loop. A real retrospective finding (see `/retro` in [Chapter 8](08-review-and-qa.md)): a repo shipping a `pnpm check` script with no CI pipeline to run it — no guard rail, so nothing stopped a broken release. Wire the checks into CI so they fire without anyone deciding to run them.

### Verification as the #1 skill: give the agent hands and eyes

Poteto (creator of the pstack skill library, whose agents ship thousands of PRs a month) calls this the top of the whole hierarchy: "the single most important skill that should be in your toolkit is verification" — even if you don't use his skill library. Verification means giving the agent the ability to run the code and interact with it like a human user — debug it, take traces and snapshots ("hands and eyes"). Without it you remain the proxy between the agent and its output, and the agent can't iterate — there is no loop:

> "The most important part of a loop that allows it to be a loop is the verification part, because the agent is able to verify its own work." — Poteto

It was the first skill he built at Cursor, the thing that first let him climb the trust ladder, and every app his team runs carries an auto-maintained verification skill — "critical infrastructure." The verification CLI itself is "just a bunch of glue" over Playwright and the Chrome DevTools Protocol plus APIs. Once the agent can verify against a rubric or score, it can also **hill-climb**: continually try to improve the result in a loop (cf. Karpathy's auto-research, [Chapter 9](09-afk-and-parallel-agents.md)).

In this guide's terms, that is exactly what the frontend browser loop below does — and the reason "the environment determines quality" is not just about lint rules but about giving the agent **eyes on its own output**.

## Modular Architecture: Deep, Gray-box Modules

The architectural pattern for an AI-ready codebase comes from *A Philosophy of Software Design*: **deep modules** — "lots of implementation controlled by a simple interface" — instead of many small interconnected ones.

### Make the file system match your mental map

Start with organization. You mentally hold vague groupings of functionality: the thumbnail editor feature, the video editor feature, authentication, CRUD forms for a CMS. In a typical codebase those groupings are "not actually reflected that much in the file system" — modules are "all really jumbled up together" and any module can import from any other, creating "disparate relationships between stuff that doesn't actually relate to each other." When your prompt describes something "over in the video editor section," the agent should be able to find it by looking at folders on disk.

So: give each grouping its own folder, document each service inside its own folder, and enforce the boundaries — because by default "there's nothing stopping" a cross-import. This has a second payoff: the directory layout itself becomes architecture documentation. "The file system is a really nice way to tell Claude what's going on" — the architecture is defined in the source of truth (code), not in prose that rots.

### Deep modules with type-level interfaces

Within each service folder:

1. Consolidate into "big chunks of modules with simple controllable interfaces" rather than "many many small modules."
2. Enforce that all exports come through the module's public interface.
3. Make that interface "really obvious in a type section" — the exported types readable before the implementation.
4. Write tests that "completely lock down the module in terms of its behavior."

This gives the agent **progressive disclosure of complexity**: exploring the codebase, it sees the services on the file system, reads the exported types, and can say "I've seen the interface. I understand what this does. I don't need to look inside because I can just trust what it's returning." It looks inside only when needed.

One gotcha: some languages make boundary enforcement easier than others. "In TypeScript and JavaScript, it's actually not that easy to make these modules boundaried in this way" — Matt recommends the Effect library, which "makes this kind of seaming/modularizing of your codebase really simple," and reports using it more over time for exactly this purpose.

### Gray-box modules: the human owns the interface, the AI owns the inside

Deep modules become **gray-box modules** when you split ownership at the interface. The interface is a **seam**: the place where the human applies taste and careful design — "I can carefully control and I can apply my taste to and design" it — while the implementation inside is delegated to the agent. Behavior is locked down with tests, so you look inside only to influence outcomes, apply taste, or improve performance. "As long as the tests are good, then I don't really need to care about what happens inside."

Three benefits are claimed:

1. **Navigability** — the agent trusts interfaces instead of reading every implementation.
2. **Reduced cognitive burnout** — "I can just keep kind of seven or eight lumps of stuff in my head" instead of the full web of inter-module relationships.
3. **It's just good software design** — "this is what we've been doing all along... a 20-year-old software practice." What works for humans works for AI.

> **Warning:** Gray-box delegation is "a million miles away from vibe coding." You must still apply taste at module boundaries — deciding what belongs in which module and how interfaces fit together is exactly the work you cannot delegate. See [Chapter 2](02-principles.md).

The failure mode this replaces is "a web of interconnected kind of shallow modules... really hard to navigate and really hard to test and really hard to keep in your head" — the summary diagnosis of an AI-unready codebase.

**Turning agent mistakes into environment constraints** is the same idea run continuously, from Poteto's setup. Every observed agent failure prompts two questions: "how do I turn this into a lint rule? How do I make it so that the codebase makes this impossible?" The goal is an environment where "it's actually very hard to write bad code" — where there's "really only one way to do something." His before-and-after: early versions of his product were ~eight god files of 10,000+ lines each; breaking features into their own directories plus restrictive lint rules fixed it. His internal framework ("our internal Next.js for our Electron apps") bakes this in: very restrictive lint rules, registry-based feature directories, conventional patterns. The same move at the language level is **type narrowing** — narrow the space of possible types until "there's only one type," exactly analogous to constraining the codebase so there's only one way to do something. Constraints live in the environment, not in the agent's memory: the agent isn't overloaded with rules, it just "bounces off them." And for migrations, encode the transformation itself: use scripts and code mods that crawl the AST and transform code literally, instead of asking the agent to invent the transformation each time. His working definition of the goal: "a good codebase is a codebase that's easy to make changes in."

Finally, module thinking starts before code: "right from the early planning stage when you're writing your PRDs or when you're turning your PRDs into implementation issues," identify which modules you're affecting, design the interfaces, and decide how you'll test them. During review, this is what you scrutinize — Matt describes reviewing a proposed `materializeCourseAndLesson` method versus adding a parameter to `materializeGhost` (the extra param would be "dodgy API-wise", so a new method won): "Notice how I'm thinking about the interface more than the implementation... I want to make sure this is testable and that the rest of the repo and any future AI agents can understand what it's doing."

## Domain Documentation: Glossary, context.md, ADRs, Coding Standards

Code and file structure are the source of truth for *how the system works*. But some knowledge is not in the code: what domain terms mean, why decisions were made, what standards the team holds. That knowledge belongs in a small set of dedicated documents — each with a specific home and a specific consumer.

### The ubiquitous language file (glossary)

Borrowed directly from Domain-Driven Design: you are the domain expert, the LLM is the developer, and a shared precise language bridges the gap. Maintain a glossary file in the repo defining every domain term. Matt's example, from his course video manager:

```markdown
ghost lesson: a lesson that exists in the database but not yet on the file system.

materialize: the act of transitioning a ghost entity to a real entity by
creating its on-disk representation.

materialization cascade: the chain reaction when materializing a lesson inside
a ghost course — assigns file path to course, materializes section,
materializes lesson.

Aliases to avoid: "create on disk", "realize".
```

Note the four ingredients: entity definitions, verbs, named composite concepts, and **aliases to avoid**. After every grilling session (see [Chapter 5](05-idea-to-spec.md)), ask the agent to update the glossary with newly agreed terms, review the edit, and commit it yourself.

> **Why it works:** When the agent searches the codebase it finds the glossary. Later you can say "there's a bug inside the materialization cascade" and it knows exactly what you mean. It also makes naming new functions trivial — `materializeGhost`, `addGhostLesson` — so the ubiquitous language flows into the code itself.

### context.md and ADRs

Matt's skills repo formalizes two more documents, wired up by its setup skill:

- **context.md** — the repo's accumulated domain context. Grilling sessions record their learnings into it statefully, so each session makes the next one smarter.
- **Architectural decision records (ADRs)** — captured during grilling "to capture the non-obvious stuff": decisions and their rationale that a future agent (or human) could not reconstruct from the code.

In his setup these live under a dedicated docs structure — `docs/agents/domain`, `docs/agents/issue-tracker`, and so on — with CLAUDE.md containing only short links pointing at them. For 99% of teams a single context is right; multi-context setups exist only for big monorepos needing multiple bounded contexts.

### coding-standards.md

Coding standards get their own file — and pointedly NOT a place inside CLAUDE.md or AGENTS.md. The reasoning is about *when* standards are useful: they matter most at code-review time, so Matt's `/code-review` skill spawns a standards subagent that looks for a `coding-standards.md` file in the repo and checks the work against it (falling back to classic Martin Fowler code smells if none exists — see [Chapter 8](08-review-and-qa.md)). Loading standards into every session's system prompt would spend instruction budget on rules that are irrelevant to most of what the session does.

Where each document lives, and who reads it when:

| Document | Home | Consumed by | When |
|---|---|---|---|
| Glossary / ubiquitous language | Repo file, updated after grilling | Any agent exploring the codebase | Whenever domain terms appear |
| context.md | `docs/agents/domain` (or equivalent) | Grilling and planning sessions | Start of thinking work |
| ADRs | Alongside context.md | Grilling, planning, implementation | When a past decision is relevant |
| coding-standards.md | Its own repo file, outside CLAUDE.md | Code-review standards subagent | Review time |
| CLAUDE.md | Repo root | Every session, always | Loaded into every system prompt |

The pattern across all of them: **just-in-time over always-loaded**. Only CLAUDE.md is loaded unconditionally — which is exactly why it must stay nearly empty.

## CLAUDE.md: Almost Nothing Belongs In It

To understand why, you need two models of how an agent spends its resources.

**Context-window budgeting.** An agent session's context is consumed by four chunks: (1) the **system prompt** — the agent's built-in prompt, MCP servers, system tools, and ALL CLAUDE.md content, locked in the moment the session starts; (2) **exploration** of the codebase; (3) **implementation**; (4) **testing and feedback loops**, which can "absolutely balloon" when something goes wrong. Chunks 2–4 flex with the task; chunk 1 does not. Everything you shave off the system prompt is space returned to actual work.

**Instruction budget.** Beyond raw tokens, "LLMs really only have a realistic instruction budget of around 300 to 400 instructions... even then it only caps out at like 500." Every sentence in CLAUDE.md is an instruction ("use Effect for dependency injection" is one; "services are defined with Effect.Service" is another). Filling that budget with content irrelevant to the current task means "you're just hamstringing your agent before it even gets started." And CLAUDE.md is global — a frontend tip is dead weight in a database session or a documentation session. "Anything you put into this global scope will affect everything you do and cost you tokens every time you do anything." (See [Chapter 1](01-how-llms-actually-work.md) for the underlying context-window mechanics.)

### The audit test

Before any line enters CLAUDE.md, run it through four questions:

1. **Is it needed on every single request?** CLAUDE.md is loaded for every session type.
2. **Is it discoverable from the code?** Commands live in package.json; the stack is visible in config files; Effect usage shows up in imports. The agent's explore phase surfaces all of this just-in-time — sometimes the config file is even fewer tokens than the prose describing it.
3. **Will it rot?** Anything referencing specific files, service names, or implementation patterns goes stale the moment the code changes — and then you either burn tokens keeping docs in sync ("just feels crazy") or delete them anyway. Documenting test patterns in CLAUDE.md also creates a maintenance coupling: change the tests, and you must remember to change CLAUDE.md.
4. **Is it already enforced by a hook?** Then the line adds nothing (see Hooks, below).

Only content that is needed broadly, NOT discoverable from the repo, durable, and not hook-enforced survives. In practice that means **minimal, non-discoverable environment facts**. Matt's entire global setup at one point contained exactly one line, six words:

```markdown
you are on WSL on Windows
```

WSL is an unintuitive setup with path-resolution issues across the Windows/Linux divide — genuinely needed everywhere and impossible to discover from the code. That is the bar.

Two more placement rules complete the picture:

- **Steering guidance goes into skills**, not CLAUDE.md. Genuinely useful but situational guidance — e.g. "LLMs are reluctant to use reducers in frontend logic, but reducers are amazing with LLMs because you can pull them out as a testable unit" — should be a skill the agent discovers on demand, carrying its full rationale at zero standing cost (see [Chapter 10](10-building-skills.md)). Matt even retired his own long-advocated global concision instruction to skill territory.
- **Links, not content.** When his setup skill writes to CLAUDE.md, it writes only short links to the issue-tracker, triage-label, and domain docs under `docs/agents/` — pointers, not inlined prose.

One honest counterweight: "one line in CLAUDE.md is cheap insurance against a mistake that's annoying to catch in review." The always-in-context argument is sometimes legitimately right. Weigh it against the budget — but the default answer is no.

## The /init Story: From "Never Run It" to "Grill Its Output"

Matt's advice on Claude Code's `/init` command evolved across two videos, and the evolution is instructive.

**The original position: never run it.** The old `/init` "would have asked me no questions, created an enormous CLAUDE.md file and then just peaced out." His verdict: "The file that this creates will burn tokens, will distract the agent, and will go out of date faster than a pear on a hot day." If you find a CLAUDE.md or AGENTS.md that looks agent-generated, delete it. The generated files fail every part of the audit test: boilerplate headers ("This file provides guidance to Claude Code when working with code in this repository" — "Who is this for? Why would you even print this?"), package.json commands that are "unbelievably trivial to discover," architecture sections restating what config files already say, and specific file and pattern references that rot immediately. He backs this with a research paper evaluating repository-level context files, which concluded that "unnecessary requirements from context files make tasks harder and human written context files describe only minimal requirements." The replacement is nothing: agents run an explore phase before every task anyway, building context just-in-time from the source of truth.

**The current position: the new /init is better, but grill everything it proposes.** The Claude Code team shipped an experimental new `/init` (enabled via an environment variable), built partly on community feedback including Matt's own: "Use progressive disclosure much more aggressively and propose a set of skills for the agent to understand the repo's best practices. The stuff inside CLAUDE.md should be extremely minimal, basically only environment info." The new version asks setup questions, explores the codebase, and proposes CLAUDE.md lines, hooks (e.g. a format-on-edit hook running prettier after every edit), and skills — a genuine improvement.

But it is still too sycophantic, and a less context-paranoid user would still walk away with a sizable CLAUDE.md. So the recommendation is: run it if you like, then interrogate every proposed line:

- **Hook-redundancy challenge:** "What would adding this to the CLAUDE.md add that the hook doesn't already guarantee?" (Answer, in his run: "Nothing. The hook already enforces it deterministically.")
- **Discoverability challenge:** "When we do integration testing there's always going to be an explore phase where the LLM actually goes in and explores the repo before it writes a test. Do we really need something in the CLAUDE.md that's going to naturally be surfaced through exploration?"
- **Frequency challenge:** rare situations (e.g. `npm install --force` for Effect packages) shouldn't burn always-loaded budget — "Let's put the effect package installation stuff inside a specific skill that's invoked whenever we run effect packages."
- **Anti-sycophancy steelman:** "Give me the best possible justification that you have for including this in the CLAUDE.md. I'd like you to stand up to me on this one." LLMs are naturally sycophantic; beware that easy agreement ("That's refreshingly minimal" is "this generation's version of 'you're absolutely right'") may not be genuine analysis.

The end state of his own run: a one-line CLAUDE.md that he then also deleted, plus one genuinely kept skill (the Effect package-install skill, edited to remove a non-durable "currently installed packages" snapshot and marked `user-invocable: false` since only the model needs it).

> **Rule:** A CLAUDE.md line survives only if it is durable, not discoverable from the code, not hook-enforced, and frequently relevant. Everything else gets deleted or moved to a skill.

## Hooks: Deterministic Enforcement Where Instructions Fail

Here is the right-CLI problem: you want the agent to use pnpm, never npm, and never run `git push`. The common advice is to write those rules into CLAUDE.md. That works "most of the time" — but it is global to every task, it burns instruction budget, and it is probabilistic: "By adding this, we're reducing our chances of running git push... but we're not preventing it." Negative instructions ("never do X") are especially bad — budget spent with no deterministic prevention.

**Hooks solve this properly.** Claude Code hooks run deterministic code at fixed points in the execution cycle; the **PreToolUse** hook fires before a tool call executes and can block it. The pattern:

1. Write a standalone bash script, e.g. `block-npm.sh`, that checks whether the incoming Bash command *starts with* `npm` as a command (not merely contains the string). If it matches: `echo "Use pnpm, not npm"` and `exit 2` — exit code 2 blocks the tool call AND feeds the message back to the agent.
2. `chmod +x block-npm.sh`.
3. Register it in the project's `settings.json` under `hooks` → `PreToolUse`, with a matcher for the `Bash` tool pointing at the script.
4. Delete the corresponding line from CLAUDE.md.
5. Restart Claude Code and test: ask it to run `npm install foo`. You'll see `PreToolUse ... Bash hook error: Blocked: Use pnpm, not npm` — and the agent automatically retries with `pnpm install foo`.

That last detail is the point: the hook both prevents the wrong command and steers the agent to the right one, delivered exactly when relevant. "You get to take instructions out of your instruction budget and enforce them deterministically." The rules "get to hover in the background until Claude actually progressively kind of discovers them."

You can have Claude Code build the hooks itself. The conversion prompt (include the hook-construction syntax from the Claude Code docs where indicated):

```text
Take the instructions in your CLAUDE.md file, turn them into deterministic
Claude Code hooks in this project directory. Not all the instructions will be
deterministic. Only do the ones you can, such as an instruction to use one CLI
command over another, or disallowing certain CLI commands. Use separate bash
scripts for running the hooks.

[Syntax for how to construct a hook — lifted directly from the Claude Code docs.]

First, confirm with the user which hooks will be created. Second, implement the
hooks. Third, provide the user with instructions on how to test the newly
created hooks.
```

In the demo, Claude listed the deterministic candidates (block npm; block `git push`), confirmed, wrote the script, chmod'd it, wired settings.json, and produced test instructions — reviewed and accepted step by step. Matt keeps his `git push` blockers in his global setup, so hooks can live at global as well as project level — which likely also makes unattended AFK runs safer, though the source doesn't say this directly. Other hook examples from his setup: an `npx tsc` interception hook that redirects the agent to `npm run type check`, and the init-proposed format-on-edit hook. The idea transfers beyond Claude Code — the same knowledge applies to Codex and other coding agents.

> **Warning:** Only deterministic rules qualify. CLI substitutions, forbidden commands, forced wrapper scripts — yes. Judgment calls and design preferences — no; those stay in skills or become lint rules.

## Frontend Readiness: Give the Agent a Browser

Coding agents "are way better at writing backend code than they are at writing front-end code" — not at frontend slop like one-shot marketing pages, but at complicated user interactions, multi-step forms, and animations. The reason is feedback-loop quality: "The feedback loops that the LLM is using are way more precise on the back end than they are on the front end." Backend loops are entirely textual — code tested by code, test output as text, docs as text — and LLMs excel at text. Frontend development is a visual loop: write code, look at the UI, write more code, look again. "So much of this feedback loop is visual, not textual." You can (and should) still attach tests, lint, and types to frontend code, but they are insufficient — without a visual element the agent can't know whether what it built actually works. "Without it, your LLM is essentially flying blind. It can't see the execution environment in which the changes are being made."

The fix is a **visual feedback loop**: give the agent a real browser. Matt's setup, in full:

1. Add an `.mcp.json` in the project that runs the **Chrome DevTools MCP server**, pointed at a running browser's remote-debugging URL.
2. Add a project skill for Chrome debugging whose entire content is essentially one instruction: "Before using Chrome DevTools MCP, you must launch Chrome in headless mode with remote debugging enabled." That plus the `.mcp.json` is "the entire setup."
3. Start your local dev server.
4. Prompt a QA task with the URL, e.g.: "Double check if light mode and dark mode are working okay on the homepage and check if all the content is rendered acceptably on both" — plus "my local server which is localhost 5175."

In the demo the agent took a full-page screenshot, noticed there was no dark-mode toggle, hypothesized system preference, tried adding a `dark` class (no effect), worked out the site used the `prefers-color-scheme` media query, emulated it, screenshotted both modes, confirmed both looked good, and cleaned up — the same **ad hoc testing** a human dev does after building a feature, deliberately not a permanent E2E suite. "Having the browser there means the LLM is much more like a human coder."

Two caveats and one amplifier:

- **Context cost.** Playwright MCP and Chrome DevTools MCP are "context hoggy": screenshots pumped back into the LLM are expensive, and the servers ship verbose tool descriptions and many tools. Community alternatives mentioned: dev browser and Playwriter (both recommended to Matt on X, untried by him); the Claude for Chrome extension exists but isn't supported on WSL, which is why he uses the MCP route.
- **Prototype before speccing.** Frontend questions like "how should it look" or "how should it behave" often can't be settled by talking — Matt recommends the prototype route (and Wayfinder) for almost anything touching the frontend: "raise the fidelity of the discussion by making a cheap rough concrete artifact to react to." See [Chapter 5](05-idea-to-spec.md).
- **AFK multiplier.** Plugging a browser into a frontend or full-stack Ralph loop produced "an enormous improvement" — without it, a looped agent literally cannot see its own output. See [Chapter 9](09-afk-and-parallel-agents.md).

## Checklist

Run this repo readiness checklist against any repository before pointing agents at it:

**Feedback loops**
- [ ] Type checking, tests, lint, and build all runnable via standard commands discoverable from the repo (e.g. package.json scripts)
- [ ] Tests lock down each module's behavior well enough that an agent can change internals safely
- [ ] Tests and type checks run on every commit (pre-commit hooks or loop configuration)
- [ ] Style preferences encoded as lint rules, not written instructions

**Architecture**
- [ ] File system matches the team's mental map: one folder per feature/service, documented inside its own folder
- [ ] Deep modules: big implementations behind simple interfaces, exports forced through the public interface
- [ ] Each module's interface obvious at the type level, readable before the implementation
- [ ] Module boundaries enforced, not implied (in TS/JS, consider Effect)
- [ ] PRDs and tickets already name the modules, interfaces, and tests they affect
- [ ] No god files: features broken into their own directories, with restrictive lint rules making bad code hard to write
- [ ] Observed agent failures converted into constraints (lint rules, directory structure, type narrowing) instead of instructions

**Domain documentation**
- [ ] Glossary / ubiquitous language file exists: terms, verbs, composite concepts, aliases to avoid — updated after every grilling session
- [ ] context.md and ADRs in place (e.g. under `docs/agents/`), capturing non-obvious decisions
- [ ] coding-standards.md exists as its own file, outside CLAUDE.md, for the code-review pass

**CLAUDE.md / AGENTS.md**
- [ ] No agent-generated CLAUDE.md/AGENTS.md surviving unaudited — delete or grill line-by-line
- [ ] Every line passes the audit: needed on every request, not discoverable from code, won't rot, not hook-enforced
- [ ] Content limited to non-discoverable environment facts plus short links to docs
- [ ] Situational steering moved into discoverable skills

**Deterministic enforcement**
- [ ] Deterministic rules (right CLI, forbidden commands, wrapper scripts) converted to PreToolUse hooks with corrective messages
- [ ] Destructive commands (e.g. `git push`) blocked by hooks
- [ ] Corresponding instructions removed from CLAUDE.md after each hook lands

**Frontend readiness**
- [ ] Browser feedback loop configured: `.mcp.json` for a browser MCP plus a launch-instructions skill — the agent has hands and eyes on its own output
- [ ] Textual loops (tests, lint, types) attached to frontend code too — necessary but not sufficient
- [ ] Any AFK loop touching frontend code has the browser plugged in
- [ ] Frontend look/behavior questions routed through prototypes, not settled by conversation

## Sources

- Your codebase is NOT ready for AI (here's how to fix it)
- Never Run claude /init
- Claude Code tried to improve /init... Is it any better?
- How to actually force Claude Code to use the right CLI (don't use CLAUDE.md)
- Frontend is HARDER for AI than backend (here's how to fix it)
- Building a REAL feature with Claude Code: every step explained
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- LIVE: Poteto (creator of pstack) on shipping 1,000's of PR's a month at SpaceX

See also: [Chapter 1](01-how-llms-actually-work.md) for context windows and the smart zone; [Chapter 2](02-principles.md) for the trust and taste principles gray-box delegation depends on; [Chapter 5](05-idea-to-spec.md) for grilling and prototyping; [Chapter 8](08-review-and-qa.md) for how coding-standards.md is consumed at review; [Chapter 9](09-afk-and-parallel-agents.md) for the loops these feedback mechanisms make safe; [Chapter 10](10-building-skills.md) for authoring the skills that absorb steering guidance.
