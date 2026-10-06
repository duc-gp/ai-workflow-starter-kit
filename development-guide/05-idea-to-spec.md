# 5. From Idea to Spec: Grilling, Research, Prototyping

This chapter covers the phases where the human adds the most value: turning a vague idea ("the way we handle ghost and real lessons is a little bit cumbersome in places") into a precise, shared destination document that agents can execute against. The core move is the **grilling** interview — the agent questions you until you both reach a shared understanding — supported by two auxiliary moves for questions that conversation cannot answer: cached research for external unknowns, and throwaway prototypes for questions of taste and feel. Matt Pocock's own words for the payoff: "The more we do here, the less we're going to end up needing to do when we actually guide the LLM."

## Plan Mode: What Converted a Skeptic

Before grilling existed as a named practice, there was plan mode — and it is worth understanding first, because it establishes the mechanic that everything in this chapter builds on.

One source describes himself as a total AI-coding skeptic — "no way AI can write decent code" — until Claude Code shipped plan mode: "Then Claude Code released plan mode and I tried it and I've never gone back." His verdict: "I believe this process is completely indispensable to getting decent outputs from an AI." Mechanically, plan mode is simple: the agent's write-to-filesystem capability is disabled and it gets a system prompt telling it to plan before changing anything. So it explores the codebase (often via a cheap explore subagent — his example burned ~40,000 tokens on Haiku 4.5, not the expensive parent model), writes a plan to a file on disk, and asks you clarifying questions before you approve and execute.

Why does this work? Two reasons, and both survive into grilling:

1. **It loads the agent's context with relevant information before it writes.** His mental model: an AI agent is like "a colleague who every time they made a commit forgot everything they'd ever learned about the repo." You make that colleague productive by telling them to explore before changing things.
2. **It forces the *developer* to clarify their own requirements.** Citing The Pragmatic Programmer's maxim that "no one ever knows what they want": planning is rubber-ducking with an entity that can also scan the codebase. In his worked example, the agent asked "Should new repos default to v1.0 as the initial version name?" — information he had never provided. "I was behaving like a crappy client… I had a question from the developer and I answered it."

His two CLAUDE.md lines are worth stealing regardless of which planning mechanism you use:

```markdown
Make the plan extremely concise. Sacrifice grammar for the sake of concision.
At the end of each plan, give me a list of unresolved questions to answer, if any.
```

The concision rule shrinks ~2,000-word plans to ~400 words — scannable, killing the "my job is just reading PRDs all day" objection. The unresolved-questions rule pushes the agent into "a slightly worried, paranoid, exploratory mode" so it surfaces confusion instead of guessing.

> **Why it works:** "Hashing out the requirements before you get to code is something we've been doing for 50 years as developers. And there's no reason why we should stop now."

Three more habits from his plan-mode practice that carry over into any planning phase:

- **When to skip planning:** only when you know the codebase inside out and know exactly the change needed — and those cases are limited (in a large org you deeply know only a few repos). For big architectural tweaks you still want the rubber-duck process even in code you know. And in unfamiliar repos the balance flips entirely — "you and the LLM walk in with the same amount of context," so a planning phase lets you contribute even in languages you don't know.
- **Plans as team artifacts (the RFC pattern):** post the generated plan as a GitHub issue so teammates can comment, or attach it to the PR so reviewers understand the intent behind the code. Or rubber-duck with the AI first, then "send that plan document to your buddy and say, 'I've got this plan. What do you think?'"
- **Re-plan, don't wing it:** when an unforeseen issue emerges mid-execution (his example: sections still carrying a stale repo ID after the migration), kick off the planning phase *again* for the follow-up rather than improvising.

**The limit of plan mode — and why grilling supersedes it.** Plan mode's Q&A step is an afterthought: the agent writes a plan and *may* ask questions at the end. Grilling inverts this — the questioning IS the process, and the plan falls out of it. Matt Pocock's main flow is explicit: "instead of using plan mode, you get an agent to grill you." He runs grilling sessions in Claude Code's default auto mode, not plan mode. The recommendation of this guide follows the newer position: use grill skills as your planning mechanism; treat plan mode as the built-in fallback that teaches the same habit. What transfers from plan mode either way: re-plan rather than wing it when surprises emerge mid-execution, and post plans/specs where teammates can comment on them like RFCs.

## Grilling Mechanics: How the Interview Actually Works

The original **/grill-me** skill is famously about four sentences long — "the most influential four sentences I've ever written," in Pocock's words. Its essence: "It interviews you until you reach a shared understanding, walking down each branch of the design tree, resolving dependencies between decisions one by one." The skills "are really not super long, and they're designed to aid you as an engineer, not replace you as an engineer" — which means the mechanics below are mostly about *your* side of the conversation.

### One question at a time — and why the "why" matters

The central grilling reference skill (shared by /grill-me and /grill-with-docs) directs the agent to ask one question at a time. The direction alone was not enough — models occasionally batched questions anyway. What fixed it was adding the reason: "asking multiple questions at once is bewildering." This is a general skill-authoring lesson (see [Chapter 10](10-building-skills.md)): rules with stated reasons are followed more consistently across models.

### From one-question-per-turn to multi-question rounds (v1.2)

The one-question-at-a-time rule had a failure mode of its own, which surfaced in v1.2 of the skills repo. At the end of a grilling session, when the hard questions are already settled and only easy ones remain, one-question-per-turn devolves into saying "yeah, that sounds good" over and over, one at a time — "incredibly frustrating" and "dead slow." The v1.2 update to `/grill-me` changed the shape: **multiple questions per turn, organized in rounds**.

The design that makes batching safe is a **dependency graph**. Questions are not a flat list — one critical early question may open a raft of follow-on questions, which themselves lead to others. The skill asks only the questions available *right now* (the frontier), then the next round of questions those answers unlock — "always pushing you as fast as possible down the frontier of questions." Naive multi-question batching would ask dependent questions before their prerequisites are answered; modeling questions as a graph and asking in rounds resolves this. The tradeoff — batching trades one problem (slowness) for another (asking dependents too early) — is solved by the graph, not by going back to one-at-a-time.

The UX makes the rounds scannable: rounds are labeled ("Round 1", "Round 2"), questions are labeled Q1/Q2/etc. with a recommended answer each, and emojis add "a little pop of color" for eye navigation. The intended interaction pattern is dictation: blast answers by label — "Q1, I agree. Q2, I agree. Q3, we need something to change there. Q4, we need something to change" — and the skill moves to the next round. This is the most popular skill in the repo; the update was driven by the end-of-session friction real users hit.

### Explore the code first, ask second

The skill instructs the agent: if a question can be answered by looking at the code, it must look at the code first instead of asking you. In practice a grilling session opens with an explore phase — a subagent reads "tons and tons of files" in its own context window and hands back only a summary, keeping the parent context small (one full session sat at only ~40k tokens after 22 minutes of grilling). The effect is that every question you actually receive is one the code could not answer, and the agent's challenges are grounded in what the repo really does rather than what it guesses (see the worked example below). One friction note from heavy use: "I do wish that explore was faster. You need it in every single session, sometimes multiple times a session."

### Facts vs decisions

A reported failure mode: the agent would grill *itself*, answering its own questions (observed especially on some models). The fix was a couple of sentences distinguishing **facts** from **decisions**: facts are things the agent finds itself by exploring the codebase; decisions must be made by the user. Keep this distinction in your own head too — if the agent asks you for a fact, redirect it: that is discoverable, go look ("look harder" works when it confidently claims something false about the repo).

### The confirmation gate

Users across models reported grilling sessions ending abruptly and jumping straight into implementation. The fix, now baked into the skill and worth adding to any homegrown variant:

```text
Do not enact the plan until I confirm we've reached a shared understanding.
```

The session ends when the agent lays out the full scope — as in the ghost-courses example below, eight bullet points after ~22 minutes — and *you* confirm. Shared understanding is a two-sided state: "we've walked the whole tree."

### Explain the WHY, not just the WHAT

Seed the session with your reasoning, not just your request. From a real grilling opener: "The reason I want this is so that I can plan courses freely without needing to commit to an exact shape on the file system." The principle: "If the LLM has the what, then it understands what you want to build. But if it doesn't know the why, then it can't suggest alternatives." You can also explicitly invite uncertainty ("I'm not sure about that flow. Maybe we can work on that together") and flip the driver's seat mid-session ("Can you give me the trade-offs of both of these approaches?") — the skill is deliberately "nice and flexible so that you can drive sometimes and the AI can drive."

The initial idea itself can — and should — stay rough. "It really can be as vague as this." The skill does the heavy lifting; over-polishing the opening prompt is wasted effort. (Pocock dictates his prompts rather than typing them.)

### What a real session looks like

From a full feature build on Pocock's production course-video-manager repo (~1,200 commits), a grilling session on "ghost courses" showed the characteristic question shapes you should expect from a well-built grill skill:

- **Framing challenges grounded in code:** "delete lesson… already handles both ghost and real lessons directly… Is there something in the UI that forces the convert-to-ghost-then-delete flow?"
- **Forcing woolly language precise:** "when you say a ghost course could have real lessons, what does *real* mean without a file system?"
- **Combinatorial scope questions:** "does direct create apply inside ghost courses too?" — his live reaction: "that's so freaking smart."
- **Edge-case probing:** "you delete all the real lessons… does the real course become a ghost course?"
- **Invariants captured as statements:** "Once a course has a file path, it stays real forever because the thing that's on disk is not going anywhere."

The session ran ~22 minutes and ended with the full scope as eight bullet points for confirmation — while the context window sat at only ~40k tokens, because explore subagents did the file reading in their own contexts. Session counts vary: his tutorial demo took 6 questions, typical sessions run ~20.

Two small session-hygiene habits from the same build. First, decide *before* grilling whether multiple ideas belong in one session or separate ones — "will this crowd out the grill-me session or will it all fairly seamlessly link together?" Second, for quick orientation questions you don't want polluting the conversation, use an out-of-history side question (Claude Code's "by the way" feature — he used it to ask "describe what's going on with the course write service — its shape and capabilities").

One design note on the skill itself: it deliberately does *not* use the harness's built-in ask-user-question tool — partly UI preference, partly economics: not calling a tool is always more token-efficient, because every tool call must be wrapped in JSON.

### Use a frontier model for grilling

Grilling leans on **parametric knowledge** — the model's trained-in understanding of systems — to prompt you with "off-the-wall suggestions, strange ideas" you had not considered. (If you had considered them, you would have passed them in as context.) That requires a big frontier model. Implementation, by contrast, is mostly **contextual** — by then the plan, the relevant files, and things to copy are all in context — so a dumber, cheaper model suffices. See [Chapter 1](01-how-llms-actually-work.md) for the parametric/contextual distinction.

## Which Skill When: grill-me → grill-with-docs → Wayfinder

The tooling evolved through three stages, and the sources are explicit about why each step happened. Present position first, history after.

**Current recommendation:**

| Situation | Skill |
|---|---|
| No codebase (pure ideation, non-engineering work) | `/grill-me` |
| A codebase, and the work fits one grilling session | `/grill-with-docs` |
| Idea too big/foggy for one session; anything touching the front end | `/wayfinder` |

**Stage 1 → 2: grill-me deprecated for coding.** Pocock stopped using /grill-me for coding work, despite its reception (~5 user messages a day praising it; "at first I felt like it slowed me down with all the questions, but… you just one-shot everything after you've gathered all the context"). Its failure modes inside a codebase: the agent got verbose and he had to keep reminding it "no, there's already a term for that"; good shared language reached in a session was never documented and evaporated; and every session began with re-explaining all the non-obvious domain jargon before anything productive happened. The replacement, **/grill-with-docs**, is grill-me's exact text plus documentation layers: it reads a `context.md` glossary at the start, challenges language against it during the session, and writes Architectural Decision Records for non-obvious decisions (next section). In a demo, its very first move was to surface a glossary tension before any implementation talk: "context.md is rich. Standalone video is already defined as a video with lessonId = null… before going further I want to surface a tension with the glossary." The rule of thumb: "When you have a codebase, use grill-with-docs. When you don't have a codebase, use grill-me." He also recommends grill-with-docs at the very start of a new project — that's exactly when shared language is being established. Grill-me is not dead — it moved to the "productivity" category for non-code use (one user grilled their way to a eulogy for their mother). The lesson he draws from iterating on his own most-praised skill: "there's improvements to be made at every single part of my process."

**Stage 2 → 3: Wayfinder for big, foggy ideas.** Grill-with-docs still had a scaling problem: managing a huge planning effort inside one session meant "the anxiety of managing my session… having to hand off, worry about the smart zone." **/wayfinder** is the newest answer, and Pocock wants users to "default to Wayfinder instead" of grill-with-docs for such work. Its own framing: "A loose idea has arrived, too big for one agent session and wrapped in fog. The way from here to the destination isn't visible yet." It charts the way as a shared map — a parent issue on the repo's tracker — with every open decision saved as a sub-issue with blocking relationships, each scoped to one agent session and typed as one of four ticket kinds:

- **research** — an AFK task run via the /research skill;
- **grilling** — a decision that needs an interview session with you;
- **prototype** — "raise the fidelity of the discussion by making a cheap rough concrete artifact to react to";
- **task** — provisioning, config, moving data into shape: "the boring stuff that doesn't need a grilling decision and can't really be automated by AI."

You work the tickets one at a time, one session each, "until the route is clear," then run /to-spec on the completed map. Because the map lives in the issue tracker, it is collaborative and shareable across the team — shared maps beat private session state. Pocock uses it "for literally everything, even non-coding stuff," and recommends it for anything touching front-end code because those efforts always contain prototype-type questions. The map's closed tickets remain as "primary sources for what was captured."

### The map model, frontier, and fog of war — what Wayfinder actually manages

The dedicated Wayfinder explainer makes the mental model explicit, and the model matters because it shapes how you drive a run. As he lands it: "Conceptually, what we're looking at here is a map. We are creating a map of how we're getting to our destination. This is why it's called wayfinder."

A map has three parts:

- A **start point** (where the repo and your understanding are today),
- A **vague destination** (where you want to end up — often "a buildable spec", not the implementation itself, so the planning work has a single concrete end product), and
- A **fog of war** between them — the open decisions you cannot yet make because you lack the research, the prototype, or the grilling to settle them.

Wayfinder tracks two sets of decisions from that fog: the **frontier** — decisions you can take *right now* — and the **fog** — decisions you cannot yet take because something else must land first. Blocking relationships model the dependency (some decisions only become makable once others are made), and as you resolve frontier tickets, new tickets unblock. You then "re-read the map to see where the frontier moved." This is why Wayfinder is distinct from a list of pre-broken tasks: it expects, and manages, that "you can't make your way cleanly to the destination. You have to clear the fog of war."

### The two reuse prompts: chart the map, then walk it

No literal prompts are taught verbatim, but the talk demonstrates a two-prompt structural pattern worth naming:

- **Chart the map** — the kickoff: invoke Wayfinder with a free-text description of the destination. State the single destination up front ("I would like the ability in the CVM to add an icon picker… search other diagrams… copy things…") and let Wayfinder's grilling sub-step clarify whether that destination should be a spec-to-implement or something to build directly. His run created 7 decision tickets immediately, only 3 of which were on the *current* frontier — the rest were blocked/fogged.
- **Walk the map** — the per-ticket loop: for each takable ticket, call Wayfinder *again* in a fresh session, pointing it at both the map and the specific ticket by its full name (example: "transfer lucid SVG geometry to path builder"). The ticket resolves in its own session, and the outcome is written back up into the parent map — so all decisions accumulate in one place rather than scattering across chat histories.

> **Rule:** Use Wayfinder for *both* charting the map initially and walking each ticket — "you use Wayfinder for both, both for charting the map initially and then walking through each ticket." Don't hand-drive the per-ticket sessions with ad-hoc prompts.

### How Wayfinder avoids being waterfall

The obvious objection to the map model is that it looks like Big-Design-Up-Front. Pocock names the objection directly: "Some folks look at Wayfinder and they think, 'God, that's a lot of planning. Doesn't that look like waterfall?'" His answer is that the **prototype tickets** are precisely what prevents it:

> "Huge amounts of low-fidelity upfront planning. A prototype is a high-fidelity way to get feedback on what you're actually building."

So the recipe is **low-fi planning + high-fi feedback**: the map captures a dense set of decisions cheaply (text, in the tracker), and prototype tickets force concrete, human-in-the-loop answers to the taste questions inside that fog. He credits the density of prototyping for the output quality — "the fact that Wayfinder encourages you to build so many prototypes means that the output is unbelievably good" — and flags cutting prototypes as the way to turn Wayfinder into waterfall by accident.

### Turning a finished map into a spec, then into implementation tickets

Once the map is complete, call `/to-spec` on the wayfinder map, then `/to-tickets` to split the spec into implementation tickets, then implement each and run `/code-review` at the end. Two properties of the produced spec matter, and both are improvements on grill-with-docs:

- **The spec links back to the original decision tickets.** "So you can actually go and the agent can go and view the primary source if it's confused about anything." This fixes a real weakness of grill-with-docs, where "you were really relying on the spec to be the source of truth, but the spec is always just a summary of what was actually said in the meeting" — the primary-source linkage gives a later confused agent somewhere to go.
- **Specs can get very dense — don't be surprised.** In his demo the first spec draft exceeded GitHub's character limit for an issue — an honest signal of how much decision content the map carries, and a reason to let the spec hold the detail rather than duplicating it into tickets ([Chapter 6](06-tickets-and-planning.md)).

### The decision-ticket ≠ implementation-ticket distinction

A common confusion, "when people first use Wayfinder," is to mistake the decision tickets on the map for implementation tickets. They are not. Wayfinder's **decision tickets** resolve *what to build* (research, grilling, prototype, task). Once the map is complete, `/to-spec` and then `/to-tickets` produce a *separate* set of **implementation tickets** whose job is to *implement* the now-set destination. The map's tickets get worked in their own sessions; the to-tickets output gets implemented separately afterward. Keeping those two sets straight is what makes the whole loop chain correctly rather than implementing half-resolved decisions.

### Wayfinder for non-coding work

Because the map model is just "map → destination → fog," it generalizes past code. Pocock's personal examples: planning a garden office (commissioning a site survey, researching firms that could build it, figuring out contacts) and planning courses, not just engineering. Any domain with a start, a vague destination, and a fog of unresolved decisions in between is fair game — the prototype/grilling/research ticket types adapt to the domain.

### Worked run: a command-K palette in the CVM

The explainer runs Wayfinder end to end on his course video manager, building a spec for a command-K palette (icon picker, search across other diagrams, copy things). The shape of the run is the reference pattern:

1. Chart the map: Wayfinder explored the repo, invoked its grilling sub-skill, interviewed him (asked what "done" looks like, recommended a buildable spec as the destination), then created the first map as a parent issue with 7 sub-issue decision tickets immediately — only 3 immediately takable (icon-names source, component storage schema, palette information architecture + keyboard nav). The other 4 were blocked/fogged.
2. Walk the map: resolve takable frontier tickets one at a time, each in a fresh session calling Wayfinder on the ticket. Each resolution is written back up into the map. As decisions land, new tickets unblock; re-read the map to see where the frontier moved.
3. Final map in his run: 17 tickets, 14 done; the remaining work was to "actually build the skill this whole map is built around" and revisit some other items once the skill shape was clear.
4. Map complete → call `/to-spec` on it (the draft exceeded GitHub's character limit on the first try) → `/to-tickets` → implement each ticket → `/code-review` at the end.

A fancier per-ticket setup available once you have the hang of it: use the **/handoff** skill to auto-write the walk-the-map prompt and spawn a Claude sub-agent per ticket, so you don't babysit each session by hand. This is optional — the plain loop also works — but it removes the manual step of re-invoking Wayfinder per ticket.

### Anti-patterns specific to Wayfinder

- **Constraining what you *build* to fit the agent's single-session context window.** What he was doing before; "doesn't feel right" and limited his ambition. Wayfinder's point is to remove that cap by splitting the work across sessions so you build what's worth building.
- **Trying to single-session-path work that's genuinely too big for it.** You spend the whole session managing the smart zone and grilling, only to get lost in fog mid-grilling and waste tokens.
- **Pre-breaking work into tiny chunks up front by hand** — "I'll just bite off this little bit" repeatedly. The naive attempt at what Wayfinder automates — done manually, and worse.
- **Treating Wayfinder decision tickets as implementation tickets.** They decide; the `/to-tickets` output implements. See the distinction above.
- **Thinking Wayfinder is waterfall.** The prototype tickets prevent that; cutting prototypes turns it into waterfall.
- **Using Wayfinder when one session would suffice.** His own guardrail: "if you think the work that you're doing can be completable and plannable in a single session, then plan it in a single session." Don't reach for it when you already know the path.
- **Spawning a Wayfinder prototype too sparse.** Because "Wayfinder encourages you to build so many prototypes," cutting them cuts output quality.

> **Rule:** Codebase work that fits one session → `/grill-with-docs`. Too big or foggy for one session, or front-end-heavy → `/wayfinder`. `/grill-me` only when there is no codebase.

## Ubiquitous Language: Document the Words as You Go

Grilling sessions constantly mint vocabulary, and that vocabulary is a first-class output. The idea comes from Domain-Driven Design (Eric Evans): a **ubiquitous language** is one shared vocabulary spoken by the codebase, the developers, and the domain experts — and in AI-driven development, *you* are the domain expert and the LLM is the developer. The same techniques that align human teams "also, it turns out, work with AI."

The mechanics during grilling:

- **context.md** — a glossary file at the repo root (the "context" is a DDD bounded context; massive monorepos use a context map of several). Structure: a short description of what the repo is, then precise entity definitions ("standalone video: a video with lessonId = null"), verbs ("materialize: the act of transitioning a ghost entity to a real entity by creating its on-disk representation"), named composite concepts ("materialization cascade"), and *aliases to avoid* ("create on disk", "realize"). Wire it up with a pointer in the local CLAUDE.md so agents find it (see [Chapter 3](03-preparing-your-codebase.md)).
- Grill-with-docs actively maintains it: challenge language against the existing glossary, sharpen fuzzy language, discuss concrete scenarios, cross-reference with code, update as you go. A useful mid-session prompt, verbatim: "Could you save what we have into context.md so far. If there's anything we haven't figured out, grill me about that before you make the adjustments."
- **ADRs** capture the non-obvious decisions that vocabulary can't: create one only when the decision is hard to reverse, would be surprising without context, AND resulted from a real trade-off. Interchangeable library picks do not qualify.

One naming note from skills v1.3: the file is now **`glossary.md`**, renamed from `context.md`. "Context.md just felt way too vague. It didn't sort of trigger the agent to pull it in at the right moment." The name is a trigger — the agent must recognize from the filename alone that this is the shared vocabulary to load when domain terms appear — and many other skills rely on seeing a `glossary.md` to use the domain language. This guide still says "context.md" where the older sources did; the artifact is the same.

Language debates feel like bike-shedding, but the terms chosen become every variable name, file name, and UI label — "this is going to affect every part of the code that's generated." The payoff compounds: shared language makes the agent's replies *and its thinking traces* shorter and better aligned ("AI uses language to think to itself"), and one tester reported that 4–5 sessions in, Claude "magically aligned" with his thoughts. Still, cut debates off when good enough: "That's good enough. Let's ship with this. We can always change and refactor to new language later."

## The Nine Mistakes People Make With Grill Skills

The complaint that "it just asked me 200 questions" is, per Pocock, user technique — the skills relentlessly question *by design*, so their effectiveness depends on the human answering. The nine failure modes:

1. **Answering high-fidelity questions in the session.** Some questions are **grillable** (answerable with pure Q&A — "what URL should this route live on?") and some are **ungrillable** (they depend on *feel* — "should we split these form fields into multiple pages or one enormous form?"). The language comes from Ryan Singer's *Shape Up*. Forcing ungrillable questions into Q&A produces guesses, not decisions — hand off to a prototype instead (below).
2. **Grilling too large a scope.** Two problems: hidden high-fidelity questions you don't notice until deep in, and blowing past the smart zone mid-interview, forcing awkward handoffs. Pre-break the scope: ask the agent to decompose it first, then grill each piece. "It's always easier to build off of something that you know works… rather than trying to endlessly plan scope out into the future."
3. **Scheduling days of AI tasks into the future.** People who do this "end up with crap because they aren't building on a foundation that they are aligned with."
4. **Being too passive.** Sitting back while the agent asks 540 questions, explodes the scope, or drills into way-too-low-fidelity detail. "Remember, it's a conversation, not an interview" — you lead it.
5. **Being too active/pigheaded.** Endlessly grilling low-fidelity minutiae instead of getting to code. When you need to see something to decide, go build it.
6. **Throwing away the grilling context.** Worst case observed: clearing the context and running the spec skill in a fresh window — "you've got this 100,000 tokens of really good design decisions and you're just going to chuck it away." Every decision made in the session must end up as code or in a handoff/spec artifact.
7. **Poor context-management awareness generally.** Careless clearing, compacting, and handing off — "probably this is just a skill issue."
8. **Using too dumb a model.** Grilling relies on parametric knowledge; a small model can't judge question fidelity or prompt strong design.
9. **Grilling one session at a time.** Run two grilling sessions in parallel and bounce between them — answer A's question while B thinks. "Really the only way I found of increasing throughput" — it doubles planning output, and "really it's just managing two separate Slack threads at the same time." Cap at two (three "if I'm feeling spicy," when one is off doing long-running research).

By this logic, Wayfinder likely heads off mistakes 2, 6, and 7 by construction — the map manages session scoping and persistence for you — which fits why it's the newest recommendation for large work.

A closing reframe for anyone who finds these phases slow: they are the **day shift** — the human thinking work — and they only *feel* slow because "you're trying to extract ideas out of your human brain. And while this is happening, you've got AFK agents running in the background implementing your previous grilling sessions." Grilling is also a skill you genuinely improve at; as you do, you can take on more parallelism and more throughput. Once scope is nailed down, "from here it's pretty much all on Rails… we have done the human in the loop bit." The night shift — agents executing what you specified — is [Chapter 9](09-afk-and-parallel-agents.md)'s territory.

## Research: Cache It for the Sprint, Then Delete It

The research phase is conditional: run it when the idea involves external dependencies or explore phases that are difficult or expensive for a fresh-context agent — a Stripe integration, an uncommon API. The economics are about fresh contexts: every time an agent works, it re-explores in a new context window, so anything expensive to re-derive should be cached once. Have the agent do the research and save it as an asset — e.g. `research.md` — in the repo or somewhere the agent can access.

The dedicated **/research** skill (also invoked by Wayfinder's research tickets) is tiny, near-verbatim: "Spins up a background agent to do the research so you keep working while it reads. Investigate the question against primary sources. Write the findings to a simple markdown file and save it where the repo already keeps such notes — match the existing convention." It runs AFK — a natural thing to have going while you grill something else.

> **Warning:** "This research generally only lives for the lifetime of this sprint… research can go out of date or it can just rot away… and actually cause our agent to take a wrong turn." Delete research assets when the sprint ends. Cached-but-stale research is worse than no research, because agents trust it.

## Prototyping: Raising the Fidelity of the Discussion

Prototypes exist to answer the ungrillable questions. "You essentially need to use prototypes as research, as spikes, as a way to essentially flush out design decisions before committing to them." Use them "when you have some unknown unknowns that you can really only figure out by looking at code," and specifically when "'how should it look' or 'how should it behave' is a key question." Do it early: "by the time we get to the PRD it's a little bit too abstract. You really need concrete feedback first."

The **/prototype** skill has two modes, because logic and UI "react quite differently":

- **UI prototypes** — for "what should this look like / feel like / how should it behave on the page." It generates several *radically different* variations rendered in the actual route where the UI will live, with a floating button to toggle between them. Then you walk down the design tree: "I like this about this variation, maybe this from that variation — take a bit of A and B and combine it into a new one and discard the others."
- **Logic prototypes** — for stateful business logic that changes over time (an entity whose state shifts with user actions). It builds "a tiny interactive terminal app that pushes the state machine through cases that are harder to reason about on paper."

An earlier framing of the same idea: ask the LLM to "chuck up a bunch of different ideas on a throwaway route," iterate human-in-the-loop over a couple of sessions, pick the best. The prototypes are throwaway artifacts ("that's the theory") — but commit the winning variant to the codebase so the implementing agent can actually see it later; otherwise the taste decisions don't transfer. Prototyping also isn't only for UI: it applies to software architecture decisions and to testing an external service.

**The grill ↔ prototype handoff loop.** A lot of Pocock's sessions follow this shape: grilling session → hit an ungrillable question → **/handoff** to a fresh prototyping session → prototype until the question is answered → hand off back ("Here's what we learned from prototyping. Now go back to grilling") → continue with the remaining grillable questions. The reason for the handoff rather than prototyping in-session: a grilling session at ~60k tokens leaves only ~40k of smart zone to prototype, give feedback, and iterate — awkward and wasteful. A handoff gives the prototyping work a full fresh context window while carrying learnings in both directions.

What makes the handoff work for this loop specifically: the handoff document must transfer not just the facts but "the vibe of the context window and the intent of the context window" — it suggests which skills the next session should use, so a handoff out of grilling tells the new agent it is prototyping, and the hand-back tells the original agent to resume the interview. Pocock calls this pattern a **DIY sub agent**: "It's kind of like you've got a sub agent, but you are in control of the sub agent, and the sub agent is not hampered in the same way that sub agents are" — it has a full context window of its own and can spawn its own subagents. Full handoff mechanics live in [Chapter 7](07-execution.md). Note also that under Wayfinder this choreography disappears: prototype tickets get their own sessions by construction, and /prototype is model-invoked so Wayfinder can call it itself.

**Why prototyping is non-negotiable for front-end.** Asked how to make AFK agents good at front end, Pocock's answer was: prototyping. "You really do need a human to sit in the loop with the agent to give it feedback on what looks good because UI is so dependent on taste, so dependent on style in the application, and often the AI just simply can't see what it's building." Do the taste work interactively via prototypes; only then let AFK agents implement. This is also why Wayfinder — with its built-in prototype ticket type — is recommended for anything touching the front end.

**When to skip it.** Prototyping is a judgment call, not a ritual. In one real feature build, Pocock hit a UI decision he "couldn't get a sense for which way to go until I saw it in reality" — and consciously chose to build it one way and give feedback afterwards rather than pause for 3–5 prototype variants: "I don't mind jumping to code and fixing it there." For cheap-to-reverse decisions in an interactive workflow, iteration beats an extra phase; reserve prototypes for decisions that would be expensive to unwind or that gate the rest of the design.

## Writing the Spec

When the grilling (or the Wayfinder map) is done, the accumulated understanding gets compressed into a **spec** — the destination document.

**Naming evolution, explicitly:** this skill was originally **/to-prd**, and was renamed **/to-spec** in v1.1 of the skills repo. The rename fixed a real problem: what was being created was never actually a PRD (a PRD describes the product itself), and non-PRD material kept leaking in. "Specification is a much broader term… can be technical, non-technical, or blend the two." Its sibling /to-issues became /to-tickets for the same reason — "issues" was tracker-biased terminology. Use the new names.

**Spec = destination.** "The spec is the destination that we're heading to… and the tickets is the description of how we're going to get there." The spec defines the end state; tickets are the journey ([Chapter 6](06-tickets-and-planning.md)). Structure of a generated spec:

- **Problem statement** and solution
- **User stories**
- **Implementation decisions**
- **Testing decisions** — these matter because they make the implementing loop "more likely to follow TDD and create feedback loops as it's going"

> **Rule:** Run /to-spec **inside** the grilling session, never in a fresh window. The spec is a compression of the context you just built (one real session: 46.1k tokens of discussion compressed into one document); regenerating it from nothing discards every design decision you made.

**The fork after grilling.** You don't always need a spec. If the remaining work fits inside the session's remaining smart zone, just say "let's implement this" in the same session — the design decisions are already in context. If the work spans multiple sessions, run /to-spec then /to-tickets in the same session, clear, and implement ticket by ticket. Either way, every decision made during grilling must be banked — turned into code, a spec, or a handoff document.

**Why you mostly do not hand-review the spec.** This surprises people, but the reasoning is sound: the spec is a *summary of a conversation you already steered*. "LLMs are really, really good at summarizing things" — you pre-reviewed the content by having the conversation, question by question. The same applies to the tickets generated from it ("Absolutely not… it's just expanding out stuff that's in the PRD").

What you *do* review, the spec skill surfaces deliberately before writing anything: it sketches the major modules being changed and asks which of them you want tests for. This is where your engineering judgment lands. In the ghost-courses build, the sketch proposed a new `materializeCourseAndLesson` method; the alternative — adding an extra parameter to the existing `materializeGhost` — would have been "dodgy API-wise," so the new method won. "Notice how I'm thinking about the interface more than the implementation… I want to make sure this is testable and that the rest of the repo and any future AI agents can understand what it's doing." The overall posture: "I'm reviewing inputs and outputs… every so often I'll go have a little poke around in the code just to make sure it's on the right track." You also police scope at this gate — when the sketch tried to fold in deprecating an old feature as a sixth module, he cut it: "I do want to deprecate plans at some point, but not as part of this PRD." Finally, you review ticket slicing granularity ([Chapter 6](06-tickets-and-planning.md)). Review interfaces and slicing, not prose.

**Why grilling transcripts make great spec fodder — Q&A colocation.** "I freaking love question and answer because it collocates the question with the answer… it shows up as a hot spot for the LLM in terms of its attention mechanism." Every open question in the session sits directly beside its resolution, so the summarizing pass has unusually well-structured source material. This is the deep reason the grill → to-spec pipeline works better than writing a spec cold.

One guardrail on the artifact itself: specs are not implementation targets. "Don't implement PRDs, only implement actual issues" — the spec deliberately does not get the ready-for-agent triage label, because an agent that picks up a whole spec will try to do the whole journey in one context window.

A second guardrail, sharpened in the dedicated Wayfinder explainer: **specs are non-persistent — delete them once the code embodies them.** This is a deliberate divergence from much of the "spec-driven development" world, which treats the spec as a living source of truth you keep and edit. Pocock's position:

> "What I'm essentially trying to say is that these specs are non-persistent... once the spec is present in the code, then you can just delete the spec."

On the Wayfinder path in particular, the produced spec is a *summary* of the decision tickets, linked back to them as primary source — so the durable record lives in the closed decision tickets on the tracker, not in a kept-and-edited spec document. He "rarely if ever refer[s] to it again" once the implementation has landed. The practical consequence: don't invest in spec maintenance tooling, don't treat spec drift from code as a defect to chase, and let closed decision tickets be your audit trail rather than a long-lived spec document (see **wayfinder map** in [Chapter 13](13-glossary.md)).

Finally, remember the boundary of what any spec can achieve: "the specs-to-code approach is just never going to work" as a *complete* methodology, because QA always surfaces edge cases "that are really hard to plan for before" (in one build, a showstopper rollback bug in non-git directories that grilling never touched). The spec is the destination, not a prophecy — plan well, then iterate through the QA loop ([Chapter 8](08-review-and-qa.md)).

## The Artifacts This Phase Produces

Everything in this chapter exists to convert an ephemeral resource — your thinking, and the context window it fills — into durable artifacts the rest of the workflow consumes. The full inventory:

| Activity | Artifact | Lifetime |
|---|---|---|
| Grilling | Design decisions in the session context; updated `context.md`; new ADRs | Context: one session (spend or bank it). Docs: permanent |
| Wayfinder | Map issue + typed, blocked sub-issues on the tracker | Sprint; closed tickets remain as primary sources |
| Research | `research.md` in the repo | The sprint only — then delete (research rot) |
| Prototyping | Throwaway variants on a real route; the committed winner | Variants: disposable. Winner: until implemented |
| Grill ↔ prototype bridge | Handoff document at a temp path | Minutes — "explicitly NOT designed to be kept around" |
| /to-spec | The spec on your issue tracker | The destination for the whole sprint |

The one resource with no place in this table is an unbanked grilling context — the ~100k tokens of design decisions that mistake #6 warns about. Every row above is a way of making sure that never gets thrown away.

## Checklist

- [ ] Seed the grilling session with a rough, dictated idea — include the WHY, not just the WHAT
- [ ] Pick the right skill: no codebase → `/grill-me`; codebase, one-session scope → `/grill-with-docs`; too big/foggy or front-end-heavy → `/wayfinder`
- [ ] Pre-break oversized scope: have the agent decompose it before grilling each piece
- [ ] Use a frontier model for grilling (parametric knowledge); save cheaper models for implementation
- [ ] Verify your grill skill has the essentials: one-question-at-a-time with the reason stated, explore-code-before-asking, facts-vs-decisions wording, and the confirmation gate ("do not enact the plan until I confirm")
- [ ] Lead the conversation: redirect irrelevant or scope-exploding questions; stop grilling low-fidelity minutiae and go build
- [ ] Classify each question as grillable (answer in-session) or ungrillable (needs a prototype) — never guess at feel questions
- [ ] Hand off ungrillable questions to a fresh prototyping session; hand learnings back
- [ ] Use UI prototypes (radically different variants on the real route) for look/feel; logic prototypes (terminal state-machine app) for stateful behavior; commit the winning variant
- [ ] Never let AFK agents do front-end without a human taste loop via prototypes first
- [ ] When using Wayfinder: chart the map once, then walk each takable ticket by calling Wayfinder again per session — don't hand-drive the per-ticket loop
- [ ] When using Wayfinder: don't confuse its decision tickets (research/grilling/prototype/task) with the `to-tickets` implementation tickets produced at the end — decision tickets resolve *what to build*, implementation tickets *build* it
- [ ] Treat specs as non-persistent: once the spec is present in the code, delete it — don't maintain a living spec document; the closed decision tickets on the tracker are your audit trail
- [ ] Cache expensive external research as `research.md` in the repo — and delete it when the sprint ends
- [ ] Update `context.md` with new terms during grilling; write ADRs only for hard-to-reverse, surprising, trade-off decisions
- [ ] Cut off language bike-shedding: ship the vocabulary, refactor it later
- [ ] Bank the session: implement in-session if the smart zone allows, otherwise run `/to-spec` **inside** the grilling session — never in a fresh window
- [ ] Skip hand-reviewing spec prose; review interfaces, modules, testing decisions, and ticket slicing instead
- [ ] Run two grilling sessions in parallel once you're comfortable — it doubles planning throughput

## Sources

- 9 Things People Get Wrong With My /grill-* skills
- I stopped using /grill-me for coding. Here's what I use instead
- I was an AI skeptic. Then I tried plan mode
- New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- New Skills! v1.2 brings /wait-what, /writing-for-agents, and fixes /grill-me
- Building a REAL feature with Claude Code: every step explained
- The 7 phases of AI-driven development
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- /wayfinder: Nothing is too big to plan anymore

See also: [Chapter 1](01-how-llms-actually-work.md) for the smart zone and parametric vs contextual knowledge; [Chapter 3](03-preparing-your-codebase.md) for context.md, ADRs, and CLAUDE.md wiring; [Chapter 4](04-the-workflow.md) for where these phases sit in the end-to-end flow; [Chapter 6](06-tickets-and-planning.md) for turning the spec into tickets; [Chapter 7](07-execution.md) for handoff mechanics and implementation sessions; [Chapter 8](08-review-and-qa.md) for the QA loop that catches what no spec can; [Chapter 10](10-building-skills.md) for the skill-authoring lessons behind the grilling fixes.
