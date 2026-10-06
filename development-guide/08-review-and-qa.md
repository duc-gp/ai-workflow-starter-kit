# 8. Review, QA, and De-Slopping

Execution ends with code that compiles, passes tests, and looks plausible. That is not the same as code that is correct, complete, and worth keeping. This chapter covers the machinery that makes quality systematic instead of hopeful: fresh-context subagent review on two axes, code-smell vocabulary that activates knowledge the model already has, deliberately ambitious review skills, human QA plans generated from the commits, the feedback loop that turns discoveries back into tickets, and the de-slopping process for codebases where all of this arrived too late.

## Never Let the Author Review Its Own Code

The first rule of AI code review is structural, not stylistic: the agent that wrote the code must not be the agent that reviews it. Matt Pocock is blunt about why:

> "Agents are often really bad at editing code or improving code they've just written because they wrote it. So they just think, 'Okay, that's fantastic. That's fine.'"

This is the same failure mode humans have — the author's mental model of what the code *should* do overwrites their perception of what it *actually* does — but agents have it worse, because the entire implementation session sits in their context window telling them everything went well. The fix is to run review in **subagents**: fresh context windows that see the diff, the spec, and the standards, but none of the implementation session's self-justification. A clean context window does a much better job reviewing.

In the skills workflow this is built in, not optional. The `/implement` skill (see [Chapter 7](07-execution.md)) ends every implementation session by loading the code-review skill and running it in subagents before committing. Review is a phase of execution, not a favor you remember to ask for.

This rule is the review-phase expression of the never-trust principle from [Chapter 2](02-principles.md): an LLM's confident self-assessment is worth nothing. Verification must come from outside the context that produced the work.

> **Rule:** Review always runs in a fresh-context subagent (or a fresh session). The implementing context never grades its own homework.

## Review on Two Axes: Spec and Standards

A generic code-review skill is hard to write — Pocock admits he "dragged his heels" on it for exactly that reason. The design he landed on splits review into **two parallel subagents, one per axis**:

1. **The spec axis** — does the code faithfully implement the originating ticket, spec, or PRD? The subagent walks through the source document and cross-checks **every acceptance criterion** against the implementation.
2. **The standards axis** — does the code conform to this repo's documented coding standards? If a `coding-standards.md` file exists anywhere in the repo, the subagent reads it and checks the diff against it.

Why both, always? Because each axis is blind to the other's defects:

> "If you only focus on standards, then you're going to miss spec stuff. And if you only focus on the spec, then you're going to miss standards stuff."

Spec-conforming code can still be spaghetti; beautifully idiomatic code can still silently skip acceptance criterion four. Two subagents running in parallel cost little and cover both failure classes.

The skill itself evolved. It was first previewed as an in-progress `/review` skill built on this two-axis design. It graduated as **`/code-review`** in v1.0 of the skills repo and was upgraded in v1.1 with the Fowler smell list described below. The current position is: `/code-review` is a shipped, blessed skill, and `/implement` invokes it automatically at the end of every implementation session. If you adopt one thing from this chapter, adopt that wiring.

One deliberate consequence of this design reaches back into the TDD loop: in v1.1, **refactoring was removed from the red-green-refactor cycle**. The `/tdd` skill now teaches only "red before green, one slice at a time," and refactoring happens at code-review time instead — "putting the refactoring in the code review part is a lot more productive because then you don't overload the implementation." The implementing agent focuses on making the ticket true; the reviewing subagent, with fresh eyes, decides what should be cleaner.

### The spec comparison as the last gate

Per-ticket review catches per-ticket problems. But when a spec was sliced into many tickets and implemented over many sessions (see [Chapter 6](06-tickets-and-planning.md)), there is a second, larger question: does the *sum* of the sessions actually equal the spec? After all tickets are implemented, the flow ends with a final comparison of the whole implementation against the original spec, acceptance criterion by acceptance criterion. Pocock's reasoning:

> Over a huge chunk of work "the agent might have forgotten things in tickets or the tickets might have been under-specified. Doing a final pass means you actually nail everything."

Tickets are lossy — they are the journey, and the spec is the destination. The final spec pass is what makes a multi-session sprint actually *complete* rather than merely *finished*.

> **Rule:** No multi-session piece of work is done until a fresh context has compared the final implementation against the spec, criterion by criterion.

## /wait-what: Curing Verbose Gibberish With Your Language

Two-axis review catches code that is wrong or non-conforming. A different problem is agent *prose* you cannot even parse — incredibly verbose output full of weird LLM phrases that "goes right over your head." Pocock singles out Opus (especially Opus 5) as "talking garbage at the moment": verbose, hard to read, "and a lot of people feel the same." He tried fixing it with output styles and by adding instructions to agents.md before concluding a dedicated skill was the right tool.

The skill is **/wait-what**, invoked by saying literally "Wait, what?" whenever "the agent just creates some random garbage and you've no idea what they just said." Two mechanics do the work:

1. **ASD STE100 simplified technical English** — the skill instructs the agent to "speak in clear, declarative sentences." STE100 (Simplified Technical English, from the ASD standard) is essentially a leading directive to use very simple language.
2. **Ground in the ubiquitous language** — the skill points the agent at `context.md`, the glossary produced by `/grill-with-docs` ([Chapter 5](05-idea-to-spec.md)), and tells it to use that vocabulary.

The second mechanic is the load-bearing one. As Pocock frames it:

> "The real cure for verbosity is not to tell it to use simple language, although we are doing a bit of that. It is to tell it to use *your* language — the stuff that you have come up with in Grill with Docs."

Telling an agent to "be simple" helps; grounding it in the project's ubiquitous language is the real fix, because it forces the agent to use the vocabulary you and your team actually use rather than generating generic, verbose circumlocutions. This connects `/wait-what` directly to the ubiquitous-language practice from [Chapter 3](03-preparing-your-codebase.md) and the glossary work in [Chapter 5](05-idea-to-spec.md): the glossary is not just for code generation — it is the cure for incomprehensible explanations too. The skill replies with "a much better, simpler alternative" to whatever it just said.

## Coding Standards and the Fowler Smell Vocabulary

The standards axis has a bootstrapping problem: it can only check standards that exist. Two decisions make it work.

**First: coding standards live in their own file, outside CLAUDE.md/agents.md.** Standards loaded into every session are context spent on every session; the point where they earn their cost is review. Keep them in a dedicated `coding-standards.md` that the review subagent reads on demand. (Pocock has also flagged a planned companion skill that extracts coding standards *from* your existing repo, to give the standards axis "a fighting chance" in repos that never wrote any down — announced but not yet shipped at the time of the source videos.)

**Second: when no repo standards exist, fall back to Martin Fowler's code smells.** The v1.1 `/code-review` skill contains a roughly ten-line list — one sentence per smell — naming the classics from *Refactoring*:

```markdown
Code smells to identify (one sentence each):
- Mysterious name
- Duplicated code
- Feature envy
- Data clumps
- Primitive obsession
- Repeated switches
- Divergent change
- Speculative generality
- Message chains
- Middleman
```

Why does ten lines of names do anything? Because of what the names point at:

> "*Refactoring* is such an old book, such a well-cited book that these smells are deep in the agent's prior."

You are not teaching the model what feature envy is — it read about it thousands of times during training. You are *invoking* the concept so that knowledge activates during review. In practice the agent repeats the vocabulary back ("yes, I found some message chains, I need to remove them; I found a middleman situation"), which means the finding arrives pre-classified with a shared name attached. After a couple of weeks of testing, Pocock's verdict on the addition: "outrageously useful," a real improvement in code quality, and "really cheap to add."

> **Why it works:** Well-cited named concepts are compression. A single line — the name plus one sentence — unlocks an entire chapter's worth of training-data knowledge. This is the same principle behind the ubiquitous-language glossary in [Chapter 5](05-idea-to-spec.md): shared vocabulary makes both directions of communication precise.

The general lesson for your own review skills: prefer famous, named, heavily-cited concepts over homegrown descriptions. The model's prior does most of the work.

## PR Bodies That Make Review Easy: The /pr Skill

Two-axis review checks the code. But after review passes, work still has to cross the last gate: a human reading the PR. "PRs are still the main bottleneck for work getting to main" — so the v1.3 **/pr** skill (inspired by Dex Hies's Show Me skill) makes the PR body itself a review instrument, generated from a fixed template with four sections:

1. **Summary** — Show Me-style: concise diagrams and pseudo-code that make the PR easier to read and review; the reviewer sees the shape of the change before the diff.
2. **Evidence** — before-and-after proof on a real entity. Asking the agent for evidence often makes it run an extra test or take an extra screenshot — runtime information that the change does what it thinks it's doing, not just that the code reads plausibly.
3. **Merge danger** — is this a one-way door (hard to roll back — deletes data, expensive to revert) or a two-way door ("a door that you can walk back through. In other words, we can easily revert this PR")? Placed near the top: "the first or second thing the person is going to see."
4. **Blast radius** — the potential ramifications of the changes.

The review calculus this hands the human: small blast radius + two-way door → no need to review hard; dangerous changes demand hard review, whatever the diff size (see [Chapter 2](02-principles.md)). And the skill is one of the most reliably model-invoked in the repo — "It seems to just invoke it every single time, at least on Opus 5.5" — evidence that a clean description gets a skill consistently auto-triggered ([Chapter 10](10-building-skills.md)).

## Demanding Ambition: What a Serious Review Skill Looks Like

Two-axis review answers "is this correct and conformant?" A harder question is "is this *good* — and did it make the codebase better or worse?" For that, Pocock test-drove a skill attributed to the Cursor team, "thermonuclear code quality review" — a single `skill.md` billed as "an unusually strict review focused on implementation quality, maintainability, abstraction quality, and codebase health" — on the last five PRs that had landed on his own Sand Castle project, work he had done the previous day and knew well. That test method matters in itself: reading a skill tells you what it *tries* to do; running it on recent code you personally supervised tells you its real hit rate, because you can judge every finding.

### The diff-bounds problem

The skill's defining move is refusing to let the diff limit the review:

> "If you pass an agent a diff, then it will usually treat that diff as its bounds within which it can work."

Default review prompts produce timid reviews for exactly this reason. The thermonuclear skill starts from the branch's changes but explicitly licenses whole-codebase restructuring, in language worth stealing verbatim:

```text
Perform a deep code quality audit of the current branch's changes.
Rethink how to structure/implement the changes to meaningfully improve
code quality without impacting behavior. Work to improve abstractions,
modularity, reduce spaghetti code. Improve succinctness and legibility.
Be ambitious. If there is a clear path to improving the implementation
that involves restructuring some of the codebase, go for it.
Be extremely thorough and rigorous. Measure twice, cut once.
```

It asks primary review questions of every meaningful change — "Is there a code judo move that would make this dramatically simpler?" and "Can this be reframed so that fewer concepts, branches, or helper layers are needed?" — where **code judo** is the recurring metaphor for a reframing that deletes complexity rather than managing it. Preferred remediations follow the same spirit: "delete a whole layer of indirection rather than polishing it," split large files into focused modules, make type boundaries explicit so control flow gets simpler. Findings come out prioritized — structural code quality regressions at the top, legibility nits at the bottom — so the human is not flooded, and the review ends with an explicit approve/reject verdict against a stated bar.

### What it caught — and the false-positive bargain

On five PRs, Pocock scored the skill at roughly 5 good findings out of 7:

- An init service file that had grown past 1,000 lines mixing concerns, plus a proposed `makeRegistry` generic that deleted ~20 lines of duplicated boilerplate — good.
- A feature-specific `if issueTracker.name === 'custom'` conditional scattered across three layers; suggested pushing the variations into the type itself, deleting the special-case branches — good.
- A weird hardcoded zod dependency path despite templates declaring their own dependencies — good ("definitely pulled up something weird").
- Swallowed errors (an `Effect.sync` wrapping a try that just returned `false` on failure) — good.
- A large-file decomposition that had been "started... but only half finished" — good; half-done splits are themselves a finding.
- A suggested discriminated union for a field mixing shell commands and prose markers — false positive, born of incomplete system understanding.
- Byte-identical prompt text in two places, flagged for deduplication — Pocock disagreed: prompts should stay independently changeable. Not all duplication is bad.

The skill's overall verdict on his week of work stung and stuck: "The behavior is correct in all three substantive PRs, but the codebase is meaningfully messier than it was a week ago." A couple of the PRs, it said, should not have landed in their current shape. He accepted it as good feedback.

The false positives are the price of the ambition, and Pocock argues you should pay it gladly:

> "Those false positives are pretty easy just to say no to... It's the ones that you miss that you never know about. The opportunities for improvement that you never see. Those are the dangerous ones."

A false positive costs you one "this is fine, don't worry about it." A miss is invisible forever. Tune review skills toward recall, not precision.

### The file-size rule

One "non-negotiable standard" from the skill deserves adoption everywhere: "do not let a PR push a file from under 1k lines to over 1k lines without a very strong reason." Pocock's own, stricter rubric: split files when they exceed **~5k tokens**. The reasoning is context economics, not aesthetics:

> "Large files are just quite hard for agents to navigate because they need to ingest the entire file into their context window in order to find the thing that's actually useful within it."

Small, focused modules let the *filename* be the context pointer — the agent can decide whether to open a file without reading it. Review is the enforcement point: flag any PR that grows a file past the threshold and require the growth to be preceded by a split. This connects directly to keeping the codebase agent-navigable ([Chapter 3](03-preparing-your-codebase.md)).

### What to copy and what to fix

The skill is not a model to imitate wholesale. Pocock's critique, which doubles as a checklist for authoring your own review skill (see [Chapter 10](10-building-skills.md)):

- It is "a huge ball of mud" — heavy repetition, no clear prioritization for the agent. Review skills should be short and DRY.
- Vague criteria are useless: "does this improve or worsen the local architecture?" tells the agent nothing. "You've got to say exactly what good and bad looks like to an agent in order for 'improve or worsen' to mean anything."
- Word-salad instructions ("treat unnecessary sequential orchestration and non-atomic updates as design smells") should be rewritten as direct statements.
- Its biggest gap: **no mention of tests, seams, or feedback loops** — all of its attention goes to source code. For Pocock, improving the feedback loops that make future agent runs better "is the entire point now of having a good codebase," so a review skill that ignores them misses the point.

Two of its patterns *are* worth keeping alongside the ambition license: question all unnecessary optionality, `any`, `unknown`, and casts (agents habitually add optional props "just to make it backwards compatible," even when the prop is always required), and treat scattered conditionals as design problems, not nits — "prefer pushing the logic into a dedicated abstraction — helper, state machine, policy object, or separate module — instead of tangling an existing path."

## QA Plans: A Human Test Script Generated from the Commits

Automated review checks the code. It does not click the buttons. After an AFK implementation run ([Chapter 9](09-afk-and-parallel-agents.md)), Pocock opens a fresh session and asks for a **QA plan** — near-verbatim:

```text
Take the last five commits and create a QA plan for me. Save that QA plan
in a GitHub issue. The QA plan should give me a step-by-step guide on how
to test every single part of the new implementation.
```

The commits are the perfect source material: the detailed commit messages a good implementation loop produces describe exactly what changed, and the QA plan translates that into a walkthrough a human can follow in the running app. He considers baking this into a skill "for almost every user-facing change"; at the time of the source video it was still a free-form prompt.

Two hygiene rules keep the QA plan from causing trouble:

- **Mark the QA-plan issue as human-only** (a label, or a title that makes it obvious) so the AFK loop skips it. His Ralph prompt includes: "if there's a human-in-the-loop label on it or it looks like it's for humans, don't work on it."
- **Close the QA plan once behavior has drifted.** A stale open QA plan is dangerous — the agent may treat it as a source of truth for what the app should do. When a QA round changes behavior, close the issue and generate a new plan for the next round.

## The Feedback Loop: Button → Issue → Agent Fix

Walking the QA plan produces discoveries, and the discoveries need a near-zero-friction path back into the backlog. Pocock's mechanism is a **feedback button** built into his own app: he dictates detailed feedback in place, and the button creates a GitHub issue containing a title generated by Haiku (a cheap model is plenty for titling), the route the feedback was submitted from, and his verbatim feedback text — plus any pasted error messages. "This information is enough for Ralph to do a really nice job."

The loop this enables is the payoff of the whole chapter:

1. Walk the QA plan in the running app.
2. File every problem through the feedback button — he filed 6–7 issues in 8 minutes.
3. Re-run the AFK loop (`pnpm ralph`) *in parallel* — bugs get fixed in the background while you keep finding more.
4. Repeat QA rounds until you call it done.

QA discoveries are not review comments; they are **new tickets** that flow back into execution exactly like planned work. This matters because QA will always surface things no amount of planning could have caught — in his run, a showstopper where a non-git-repo directory left the database and filesystem out of sync, an edge case never raised in ~22 minutes of grilling. His conclusion is a standing argument against pure up-front specification:

> "The specs-to-code approach is just never going to work because when you're in the QA loop... you are going to find little weird edge cases that are really hard to plan for before."

> **Why it works:** The spec gets you to a testable state; the QA loop gets you to a correct one. Making discovery-to-ticket nearly free (dictation, auto-generated title, route captured automatically) is what lets QA and fixing run as parallel processes instead of a serial bottleneck.

QA is also where human taste re-enters. UI decisions that could not be settled by talking ("I couldn't get a sense for which way to go until I saw it in reality") get settled here — and QA caught internal jargon ("ghost course") leaking into end-user UI, something no automated axis would flag.

## Scaling Review: Sampling, Post-Land Review, and Course-Correcting the Kitchen

Once agents ship thousands of PRs a month, exhaustive human review is arithmetically impossible — and Poteto's setup, which does exactly that, shows what replaces it. Three techniques:

**1. Sample like a quality supervisor.** "You can't taste every dish" — you don't read all 2,500 PRs. You sample, scrutinizing the sampled agent-written code rigorously, like a factory quality supervisor. Sampling works because the alternative is not "read everything" — it is skimming everything and catching nothing.

**2. Course-correct the environment, not the individual.** The sampling verdict routes to a system-level decision: a one-off incident is fine ("maybe there's nothing to fix there"); multiple agents taking the same shortcut or propagating the same workaround means the kitchen needs amending — skills, constraints, lint rules, type systems ([Chapter 2](02-principles.md) states the principle; [Chapter 3](03-preparing-your-codebase.md) builds the constraints). Never chase the individual agent's mistake; fix what made it possible.

**3. Review after the land, via commit history.** At the top of the trust ladder, agents merge their own PRs while you sleep; you review afterwards via the commit history, then revert, modify, or add a lint rule when problems show. This only works because verification has made "one-way doors become two-way doors in a sense" — a verified, cheaply revertible merge is not a one-way door. The gate is the verifiability of the domain: software engineering is largely verifiable, so post-land review is safe; for hard-to-verify domains (medical, law, finance) he has no full answer — the industry has to figure it out.

Two supporting practices from the same setup:

- **The gardening buffer.** An agent constantly scans the codebase for banned patterns (e.g. React footguns) — but is told NOT to fix immediately; it appends findings to a document. Every couple of days, review the document: the entries usually turn out to be "all the same thing," revealing the pattern you'd miss in pure execution mode. The buffer forces pattern-discovery: a chief-of-staff agent "can see the forest" that per-bug fixing can't. Much of the PR volume is this kind of "gardening," not features.
- **Eliminate tautological tests.** A named test smell from the same source: agent-written tests that assert the implementation against itself — "tautology" is the word worth using, because a good word is one the agent hooks onto and reuses in its thinking traces.

**Mining your own transcripts (recall).** Past chats are "a treasure trove of context" — the real process, materialized, not the abstract idea in your head. The workflow: have an agent look through past transcripts for places where you had to intervene, then turn those higher-level learnings into reusable skills or lint rules so the mistake stops repeating. Poteto's `recall` skill compresses exactly this — mining a previous chat's context to carry into a new chat (it was born from virtualization bug-fixing, where each new chat lost the good context of the last one). This is the same "bank the session" discipline as [Chapter 5](05-idea-to-spec.md)'s artifacts table, run against history instead of the current session.

## Retro: An Agent Grading Your Own Sessions

Review skills grade the code; nothing in the loop grades *the process itself*. The v1.3 **/retro** skill closes that gap: run it on a coding-agent session — the current one or recent past ones — and it reads what actually happened and suggests improvements for next time, across categories: codebase navigation, automated checks to add (a `pnpm check` script nothing ran → add CI), coding standards for the automated reviewer, health of the global AGENTS.md, tool economy (token-wasting custom CLIs, tools not on PATH), no-op instructions in steering files, and whether the agent had access to all the information it needed.

Why a second agent must do this: the working agent hides its own failures. "The agent doesn't complain, I think, as much as it should, and doesn't try to fix its own mistakes. You kind of need to get another agent to look back on those sessions and see where it went wrong and see how to help." Agents persist and get features built "one way or another" even while bumping into undetected problems — retro is what surfaces them. Its verdicts are blunt by design: "Retro is merciless. It will look at your actual sessions and see what is going on and it will pretty much always find ways to improve."

Two rules govern its use:

- **Run it on a sampling of sessions** whenever you realize you haven't in a while — especially on sessions that went wrong or where the agent did something weird. "Retro will usually find a fix."
- **Never automate it.** Retro is human-in-the-loop by design: apply its fixes with human judgment, because "automating this means that the agent will get itself into a loop where it continually finds false positives" and takes the repo somewhere it shouldn't go. Its most serious-sounding finding may not actually be that bad — weigh it yourself.

Real findings from Pocock's own runs illustrate the range: an agent that discovered a missing 1.3.0 release and cut one without asking (an irreversible public action — why his repo has 1.3.1 but no 1.3.0); repeated per-session instructions lost between compactions in long sessions, moved into an animatics skill; a custom CLI that wasted tokens; a tool with gaps not on PATH. Retro is the same instinct as Poteto's transcript mining (above) and the gardening buffer — pattern-level visibility on your own process — packaged as a named, invocable step.

## De-Slopping: Rescuing a Codebase Ruined by AI

Everything above assumes the quality gate was in place while the code was written. Many codebases were not so lucky. Pocock's diagnosis of what actually happened during the "code is cheap" era:

> "AI has simply accelerated software entropy... codebases are falling apart faster than they ever have before."

**Slop** at the codebase level is the accumulation of AI changes made without regard for the whole system: each one introduces small oddities — a parallel implementation here, a scattered conditional there, a shallow module wrapping nothing — that compound into a ball of mud that is hard to change. The cure is one skill: **improve codebase architecture**, which operationalizes software-design fundamentals (deep modules, seams, adapters, locality, leverage — from John Ousterhout's *A Philosophy of Software Design*) as a hunt-and-fix process.

How a run works:

1. Open a fresh session in the target codebase and **turn off auto mode** — "auto mode does some funny things with these human-in-the-loop style flows."
2. Run the skill. Its first move is to explore the codebase for **deepening opportunities**: shallow modules, poor leverage or locality, duplicated parallel implementations of one concept, untested seams. On Pocock's course-video-manager repo — the same app as [Chapter 4](04-the-workflow.md)'s ghost-courses demo, grown from ~1,200 to ~1,500 commits by this later, post-v1.1 session — it returned six candidates.
3. Pick a candidate — precisely. (When he said "I'd like to pick one," Claude literally picked candidate #1.) His demo pick: an "insertion point" concept implemented twice, once in the frontend and once in the backend, with the seam where they must agree completely untested — the two could silently drift apart. Refactoring into a single module gains locality: "the interleave clip/clip-section ordering rule lives in one place."
4. The skill fetches concrete code from both sides to ground the discussion, then runs a **grilling session** — design questions you answer one by one (see [Chapter 5](05-idea-to-spec.md) for the grilling pattern).
5. It proposes a **module shape** — the set of functions forming the new module's interface — asks permission to verify implementation details and sketch the actual TypeScript interface, and surfaces the remaining design decisions.
6. Once settled, run **`to PRD`** or **`to issues`** (in current skill naming, `/to-spec` and `/to-tickets` — the skills were renamed in v1.1) to emit the design into your issue tracker, where an AFK agent can pick it up and implement it.

The critical constraint: **this is not an AFK skill.**

> "This is not an AFK skill that you can just sort of run and rely on to continually improve your codebase. This requires a judgment call from you, the programmer, sitting above the LLM."

Pocock's model is tactical versus strategic: agents are "really, really good tactical programmers," but they need a strategic programmer above them. The skill lets the agent *scout* deepening opportunities; the human decides which serve the codebase's long-term health. A design detail worth stealing for your own skills: the skill embeds a **glossary** of its architecture terminology (module, interface, deep/shallow, seam, adapter, locality, leverage), because "having a shared vocabulary with the AI is super important... you can be a lot more precise with what you're asking for."

When to run it:

- **Every couple of days** in a fast-moving codebase — you will keep surfacing opportunities, because agents keep generating entropy.
- **As the first step in a legacy codebase**, before making any changes. "Legacy codebase" really means *bad* codebase — one that is hard to change. Build a test harness around deep modules with clear seams first; agents produce better output when good tests exist, and clear seams are what make good tests possible ([Chapter 3](03-preparing-your-codebase.md)).

De-slopping and the review gate are the same idea at two timescales: the two-axis review stops slop from landing PR by PR; the architecture skill drains the slop that already landed. Run both.

## Checklist

- [ ] Review always runs in fresh-context subagents — never in the context that wrote the code.
- [ ] `/implement` (or your equivalent) invokes code review automatically before committing; review is a phase, not a favor.
- [ ] Review runs on two parallel axes: spec fidelity (every acceptance criterion) and repo coding standards.
- [ ] When agent prose is incomprehensible (Opus verbosity), say "Wait, what?" — /wait-what re-states it in ASD STE100 simplified technical English grounded in your context.md ubiquitous language, not just "simpler" language.
- [ ] Coding standards live in a dedicated `coding-standards.md`, not in CLAUDE.md/agents.md; review is where they are consumed.
- [ ] The review skill carries a ~10-line Fowler smell list (mysterious name, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, divergent change, speculative generality, message chains, middleman) as fallback vocabulary.
- [ ] Refactoring happens at review time, not inside the TDD loop — red-green only during implementation.
- [ ] Your review skill explicitly demands ambition: the diff is the starting point, never the bounds.
- [ ] Findings come out prioritized (structural regressions first) with an explicit approve/reject verdict.
- [ ] You accept false positives as the cost of recall — dismissing one is cheap; a missed opportunity is invisible.
- [ ] File-size rule enforced at review: no PR pushes a file past ~1k lines (or ~5k tokens) without a split first.
- [ ] Review criteria are concrete — you have said exactly what good and bad look like, with no "improve or worsen" vagueness.
- [ ] Your review skill also covers tests, seams, and feedback loops — not just source aesthetics.
- [ ] After AFK runs, a QA plan is generated from the last N commits, saved as an issue, and labeled human-only.
- [ ] Stale QA plans get closed as soon as behavior drifts.
- [ ] QA discoveries flow back as tickets through a near-zero-friction channel (feedback button: cheap-model title, route, verbatim feedback), and the fix loop runs in parallel with continued QA.
- [ ] Multi-session work ends with a final implementation-vs-spec comparison in a fresh context.
- [ ] The improve-codebase-architecture skill runs every couple of days (auto mode off, human judgment on), and first of all in any legacy codebase.
- [ ] At scale you sample instead of reading everything — sampled agent code scrutinized rigorously; repeated shortcuts across agents trigger an environment fix (skills, lints, types), not per-agent correction.
- [ ] Gardening findings buffered into a document for pattern discovery — not fixed one by one as they appear; tautological tests flagged and eliminated.
- [ ] Post-land review via commit history (revert / modify / add lint rule) where verification has made merges cheaply revertible; past transcripts mined for interventions and turned into skills or lint rules (recall).
- [ ] Every PR body carries summary (diagrams/pseudo-code), evidence (before/after), merge danger (one-way vs two-way door), and blast radius — near the top, where the reviewer sees them first.
- [ ] Run /retro on a sampling of recent sessions — especially the ones that went wrong; apply its fixes with human judgment, never automated.

## Sources

- mattpocock/skills: A complete AI Coding workflow, end-to-end
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- New Skills! v1.2 brings /wait-what, /writing-for-agents, and fixes /grill-me
- New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog
- Can Cursor's HARDCORE Review Skill Stop The Slop?
- How To De-Slop A Codebase Ruined By AI (with one skill)
- Building a REAL feature with Claude Code: every step explained
- Never Trust An LLM
- LIVE: Poteto (creator of pstack) on shipping 1,000's of PR's a month at SpaceX

See also: [Chapter 2](02-principles.md) for the never-trust principle behind fresh-context review, [Chapter 3](03-preparing-your-codebase.md) for the codebase properties review enforces, [Chapter 6](06-tickets-and-planning.md) for how specs become tickets, [Chapter 7](07-execution.md) for the implementation sessions review gates, [Chapter 9](09-afk-and-parallel-agents.md) for the AFK loops QA feeds, and [Chapter 10](10-building-skills.md) for authoring review skills of your own.
