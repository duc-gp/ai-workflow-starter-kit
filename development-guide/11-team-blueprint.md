# 11. The Team Blueprint: Quality By Process, Not Talent

Everything in this guide so far has been addressed to you, one developer with one harness. This chapter assembles it into a workflow a whole team can run — one where the quality of what ships does not depend on who happened to be prompting that day. The mechanism is simple to state and takes discipline to install: every instinct that makes one developer good with agents gets encoded into shared, versioned skills and deterministic gates, so the process carries the skill instead of the person. This is the chapter you implement on Monday morning.

## No Such Thing as a Skill Issue — Because the Process Owns the Skill

Andrej Karpathy's diagnosis of the current moment is that model capability now exceeds most people's ability to harness it, so "everything is skill issue": when an agent fails, it usually means your instructions, your memory tooling, or your orchestration weren't good enough — "I just didn't give good enough instructions in the agents.md file." That is an empowering framing for an individual. For a team, it is a threat: if outcomes hinge on each person's private prompting instincts, your output quality has the variance of your least-practiced developer on their most tired day.

Matt Pocock's answer is to move the skill out of people's heads and into the repo. His framing of agents explains why this works: they are "a fleet of middling to good engineers… but they have no memory." Memoryless engineers need "extremely strict, well-defined processes" — and once he encoded his process into skills so the AI has "a really strict path it can walk down every single time," the code quality the agents produced "shoot[s] up." The same logic applies one level up, to the humans: a skill file is a process document that reads, in his words, like "a little mini markdown book of processes for humans." When the whole team runs the same skills, everyone's agent walks the same strict path.

The evidence that this scales beyond content creators: Bassam Daidi, a senior engineer at GitHub, reports that ~90% of his production code is written by agents, shipping features to internet-scale infrastructure — and describes his own role as shifting to operations, correctness, and business outcomes, steering the agent's style and direction. The code-writing skill moved into the process; the engineering judgment stayed with the human.

> **Why it works:** Skills are versioned files in the repo. When one developer discovers a fix — a confirmation gate that stops premature implementation, a one-sentence Fowler-smell list that sharpens review — it lands in the skill via a pull request and every developer's agent behaves better the next morning. Individual talent still matters (judgment, taste, domain knowledge), but it compounds into the shared process instead of evaporating when that person is on holiday.

Two distinct failure sources must both be closed:

1. **Agent-side variance** — closed by skills: the agent follows the same grilling, spec, ticketing, implementation, and review procedure regardless of who invoked it.
2. **Human-side variance** — closed by gates and onboarding: confirmation gates, triage state machines, hooks, and QA plans that catch the mistakes humans make when driving the flow (covered below), plus deliberate coaching of the human-side skills the flow still requires.

## The Adoption Plan

A prescriptive rollout, phased so each week's work makes the next week's possible. (The phasing is this guide's organization; every practice inside it comes from the sources.)

**Week 1 — Readiness: repo and shared skill set.**

1. Make the repo AI-ready per [Chapter 3](03-preparing-your-codebase.md): deep modules with simple interfaces, tests that lock down behavior, a near-empty CLAUDE.md pointing at docs. This comes first because "your codebase, way more than the prompt that you used, way more than your agents.md file, is the biggest influence on AI's output" — a gate no skill can compensate for.
2. Install the skills repo at **project scope** (see next section) and run the setup skill: pick the issue tracker the team already uses, accept the triage labels, choose single-context domain docs.
3. Start `context.md` (the ubiquitous-language glossary) and the ADR convention; wire the pointer into the local CLAUDE.md ([Chapter 5](05-idea-to-spec.md)).
4. Convert every deterministic CLAUDE.md rule into hooks (see "Hooks" below) and check `settings.json` into the repo so enforcement travels with the code.

**Week 2 — Run the standard flow, human-in-the-loop.**

5. Every developer runs the main flow ([Chapter 4](04-the-workflow.md)) on real features: grill → spec → tickets → implement, staying at the keyboard. The goal this week is fluency, not throughput.
6. Coach the human-side skills the flow needs (see "Onboarding" below): question fidelity, active grilling, context preservation, model selection.
7. Institute the review posture: humans review interfaces and inputs/outputs, not every line — "I'm reviewing inputs and outputs… every so often I'll go have a little poke around in the code just to make sure it's on the right track."

**Week 3 — Turn on the gates and the backlog.**

8. Adopt the triage state machine on the team backlog ([Chapter 6](06-tickets-and-planning.md)): every issue carries exactly one category label and one state label; nothing reaches `ready for agent` without a brief.
9. Make the two-axis subagent review and the QA-plan loop mandatory on every piece of agent-produced work ([Chapter 8](08-review-and-qa.md)).
10. Open the skills themselves to contribution: skill changes go through the same PR review as code, and the team modifies skills together — the explicit reason project-scoped installation exists.

**Week 4 and beyond — AFK execution and scale.**

11. With gates proven, let agents work the `ready for agent` queue unattended ([Chapter 9](09-afk-and-parallel-agents.md)) — sandboxed, never in YOLO mode.
12. Adopt the day-shift/night-shift rhythm: humans do grilling, specs, and QA during the day; agent loops implement overnight. "It's slow because you're trying to extract ideas out of your human brain. And while this is happening, you've got AFK agents running in the background implementing your previous grilling sessions."
13. Schedule the de-slop cadence (see "Escalation Paths") and revisit your provider/economics setup (see "Economics").

## One Skill Set, Project-Scoped

The first installation decision is scope, and for teams it is not a judgment call:

> **Rule:** Teams install skills at **project scope**, not global. Everyone shares the same skill set per project and can contribute to skills together. Global scope is fine for a solo developer only.

The mechanics, from the end-to-end walkthrough of the mattpocock/skills repo:

```bash
# In the repo root (works identically for brownfield and greenfield —
# for a new project, run it in an empty directory)
npx skills@latest add mattpocock/skills
```

During the interactive install: select the official ("blessed") skills, pick the agents your team actually uses (the installer configures universal harnesses like Cursor, Codex, Cline by default; Claude-skills-based harnesses you select yourself), choose **project** scope, and choose **symlink** as the install method — the copy alternative duplicates files across folders and is "not a nice way to do it."

Then run the one-time setup skill in the agent:

```text
/setup-mattpocock-skills
```

Three decisions matter for a team:

- **Issue tracker.** The skills save specs and tickets somewhere, so pick the tracker your team already lives in — GitHub, Jira, Linear, beads, local markdown, "literally anything." There is no integration work: you just tell the agent during setup ("set it up with Jira") and it configures itself. This kills the most common adoption objection before it's raised.
- **Triage labels.** Accept the defaults unless you have a reason not to; the triage gate below depends on them.
- **Domain docs.** Single context is right for 99% of teams; multi-context is only for big monorepos with genuinely separate bounded contexts. Setup writes pointers into CLAUDE.md at `docs/agents/…` so every session discovers the tracker config, labels, and domain docs.

Two properties make a shared skill set cheap to standardize on. First, the context tax is trivial: because the skills are user-invoked with short, precise descriptions, the entire set consumes only ~660 tokens of context (verify with `/context`) — unlike skill repos whose descriptions "leech their way" into every session. Second, there is a built-in tutor: `/ask-matt` is "essentially me as a skill" — a new team member can ask it "how do I get started? What is the main flow I should use?" and get the canonical answer.

**Maintaining the shared set.** Skill renames are not auto-migrated by the installer (`/to-prd` → `/to-spec` and `/to-issues` → `/to-tickets` required deleting and re-adding). Assign an owner for skill upgrades: re-run `npx skills add`, then audit the skills folder so no stale skills linger — "make sure you're intentionally grabbing all the right skills." If your team has modified skills locally, point your agent at the upstream repo and the release notes and have it pull down the changes.

## The Standard Flow Every Developer Follows

The team runs one pipeline. Each stage is detailed in its own chapter; what matters here is that the *same* sequence, with the *same* decision points, is what every developer does — and that each skill tells the agent what the next step is, so nobody has to remember the flow.

```text
idea
 └─ fork: big/foggy or front-end-heavy? → Wayfinder map on the tracker (Ch 5)
    else → /grill-with-docs            ← interview to shared understanding (Ch 5)
     ├─ (question needs a runnable answer?) → /prototype via /handoff, then back
     └─ fork:
        ├─ fits remaining smart zone → "/implement this" in-session
        └─ multi-session work → /to-spec → /to-tickets → /clear
                                  └─ /implement, ONE ticket per session (Ch 7)
                                      └─ built-in: typecheck, build, verification,
                                         /code-review in subagents, commit (Ch 8)
                                          └─ QA plan → human QA → new tickets → loop (Ch 8)
```

Both branches converge on the same shared understanding before `/to-spec`; the difference is only whether that understanding is built in one session or charted as a map across several.

Decision points every developer applies identically:

- **Which entry skill?** The sources evolved here, and the newest position wins: `/grill-me` was the original (and remains for non-codebase work); `/grill-with-docs` replaced it for codebases because it persists shared language into `context.md` and ADRs instead of losing it every session; and for ideas "too big for one agent session and wrapped in fog," **Wayfinder** is now the recommended default — it charts the pre-spec work as a shared map on the issue tracker (a parent issue with typed, blocked sub-issues: research, grilling, prototype, task), each sub-issue sized to one agent session. Matt Pocock recommends defaulting to Wayfinder over grill-with-docs for big work and for "almost anything that touches front-end code." Crucially for teams: the map lives in the tracker, "so it's collaborative and shareable across the team," replacing "the anxiety of managing my session… having to hand off, worry about the smart zone" with state anyone can pick up. ([Chapter 5](05-idea-to-spec.md))
- **Implement now or spec first?** Estimate the remaining smart-zone budget after grilling. Fits → implement in the same session. Doesn't → `/to-spec` then `/to-tickets` in the same session (never in a fresh one — see anti-patterns), then clear. "The spec is the destination… and the tickets is the description of how we're going to get there." ([Chapter 6](06-tickets-and-planning.md))
- **One ticket per session.** Each ticket is sized to a single context window. Implement one, check the smart zone, maybe squeeze in one more — but usually clear between every ticket. ([Chapter 7](07-execution.md))
- **AFK or attended?** Work that has passed the gates and carries the `ready for agent` label can be executed by a loop unattended ([Chapter 9](09-afk-and-parallel-agents.md)); everything else stays human-in-the-loop.

Because "the skill at each stage tells the agent what to do next," the flow is self-navigating — a developer who forgets what comes after `/to-spec` will be told by the harness, not by a senior colleague.

## The Quality Gates That Do Not Depend on Talent

Each gate exists because a specific, observed failure mode slips past unstructured prompting. None of them require the developer to be good at prompting — they require the developer to not skip the gate.

| Gate | What it catches | Enforcing mechanism | Chapter |
|---|---|---|---|
| Repo readiness | Agents lost in jumbled modules; no feedback on whether a change worked | Deep modules, tests at seams, docs pointers; `improve-codebase-architecture` cadence | [Ch 3](03-preparing-your-codebase.md) |
| Grilling + confirmation gate | Building the wrong thing; agent jumping to code before shared understanding | `/grill-with-docs` with "Do not enact the plan until I confirm we've reached a shared understanding" | [Ch 5](05-idea-to-spec.md) |
| Facts vs decisions split | Agent "self-grilling" — answering design questions it should ask the human | Grilling reference skill: facts are agent-discoverable; decisions belong to the user | [Ch 5](05-idea-to-spec.md) |
| Prototype for high-fidelity questions | Guessed answers to "how should it look/behave" questions | `/prototype` (UI or logic), bridged via `/handoff`; Wayfinder prototype tickets | [Ch 5](05-idea-to-spec.md) |
| Spec gate | Scope drift; agents implementing destination documents directly | `/to-spec` compresses the grilling session; rule: "don't implement PRDs, only implement actual issues" | [Ch 6](06-tickets-and-planning.md) |
| Ticket sizing | Smart-zone blowout mid-implementation; attention degradation | `/to-tickets` sizes every ticket to one context window; slicing negotiable ("do it in one slice instead") | [Ch 6](06-tickets-and-planning.md) |
| Triage state machine | AFK agents "stumbling around on crap tasks that aren't ready" | `/triage`: exactly one category + one state label; `ready for agent` requires a written brief | [Ch 6](06-tickets-and-planning.md) |
| Implement with built-in verification | Untested, unbuilt, unverified commits | `/implement`: TDD at pre-agreed seams, typecheck regularly, full test sweep at the end, then review, then commit | [Ch 7](07-execution.md) |
| Two-axis review in fresh subagents | Writer-bias approval; spec omissions; standards drift | `/code-review`: parallel subagents — spec axis (every acceptance criterion) + standards axis (repo standards, Fowler-smells fallback) | [Ch 8](08-review-and-qa.md) |
| QA plan + human walkthrough | Edge cases no spec anticipated | Agent-generated step-by-step QA plan saved as a human-only issue; a human walks it | [Ch 8](08-review-and-qa.md) |
| Feedback loop | Findings dying in chat | QA findings filed as new tickets → execution loop → QA again, until convergence | [Ch 8](08-review-and-qa.md) |

Three of these deserve emphasis because they are the ones most directly built to neutralize talent differences:

**The confirmation gate.** Users on different models reported that grilling sessions would just end and go straight into implementation. The fix was one sentence in the shared skill — "Do not enact the plan until I confirm we've reached a shared understanding" — and the failure mode disappeared for everyone at once. That is the team-blueprint dynamic in miniature: one person's debugging became everyone's guarantee.

**Fresh-subagent review.** "Agents are often really bad at editing code or improving code they've just written because they wrote it. So they just think, 'Okay, that's fantastic. That's fine.'" Running review in subagents with clean context windows is not a preference; it is the structural fix for writer bias — and because `/implement` invokes it automatically, no developer can forget it. The spec axis matters most on multi-session work: "the agent might have forgotten things in tickets or the tickets might have been under-specified. Doing a final pass means you actually nail everything."

**The QA loop.** "The specs-to-code approach is just never going to work because when you're in the QA loop… you are going to find little weird edge cases that are really hard to plan for before." A human — "yes, a human" — walks the QA plan; findings become tickets; the loop reruns. Teams that treat the spec as the end of quality assurance quietly reintroduce the biggest skill issue of all: believing the plan survives contact with reality.

## Hooks: Deterministic Enforcement Where Instructions Are Not Enough

The block-npm.sh PreToolUse pattern, the exit-code-2 mechanics, and the CLAUDE.md-to-hooks migration prompt are covered in full in [Chapter 3](03-preparing-your-codebase.md). For a team, there is an additional problem hooks solve that a solo setup doesn't hit: an instruction in CLAUDE.md only protects the developer who remembered to write it, while a hook enforces the same rule for every developer and every AFK agent identically.

That parity only holds if the hooks themselves are shared, not personal. Check `settings.json` and the hook scripts into the repo — the same way skills go through PR review (see above) — so a fix one developer discovers becomes a guarantee for the whole team the next morning, rather than living only in their local config.

> **Rule:** Any rule that CAN be enforced deterministically MUST be a hook or a lint rule, not an instruction. Instructions are for judgment; hooks are for rules. Check `settings.json` and the hook scripts into the repo so enforcement is identical for every developer and every AFK agent.

## Onboarding a New Developer

A new hire meets the workflow in three layers.

**Layer 1: the workflow explains itself.** Because skills are project-scoped, day one is `git clone` and opening the harness — the whole skill set is already there. `/ask-matt` answers "how do I get started, what is the main flow?" interactively, and each skill in the flow points to the next. The repo's own docs do the rest: `context.md` gives the newcomer (and their agent) the team's ubiquitous language, and ADRs explain the non-obvious decisions. This is the same "AI as new starter" logic from [Chapter 3](03-preparing-your-codebase.md) applied to humans — a codebase prepared for memoryless agents is, by construction, prepared for new colleagues.

**Layer 2: teach-based onboarding.** For learning the codebase itself, Matt Pocock proposes replacing static onboarding documentation with the stateful `/teach` skill: start the new hire in their own teach workspace, point the skill at the codebase, and let them learn independently — "you've got a productive employee in record time." The reasoning: static onboarding docs are "a real pain in the ass" — they must be kept up to date, *and* they sit outside any individual's zone of proximal development (one person knows the stack but not the domain; another knows the domain but "has no idea what TypeScript is"). A stateful teacher-agent persists a mission, lessons, learning records, and a glossary to the file system, so across sessions it always resumes exactly where the learner is. Karpathy independently lands on the same idea from the other direction: write a skill that scripts the curriculum an agent should walk a learner through, because the agent "explains with infinite patience, at the learner's level, three different ways on request."

**Layer 3: coach the human-side skills.** The grill-family skills "are designed to aid you as an engineer, not replace you as an engineer" — their output quality depends on the human answering. From the catalog of things people get wrong, the onboarding curriculum for the human is:

1. **Question fidelity.** Low-fidelity questions ("what URL should this route live on?") get answered in the grilling session; high-fidelity questions ("how will this UI feel?") cannot be — hand off to a prototype instead of guessing.
2. **Scope sizing.** Too-big scopes hide high-fidelity questions and drag the session into the dumb zone; ask the agent to decompose the scope first (or start in Wayfinder).
3. **Active grilling.** "It's a conversation, not an interview" — redirect irrelevant questions, but also stop grilling and go build when only low-fidelity minutiae remain.
4. **Context preservation.** A finished grilling session holds ~100k tokens of design decisions; either implement in-session or run `/to-spec` *inside* the session. Clearing and re-running to-spec fresh is "totally crazy… you're just going to chuck it away."
5. **Model selection.** Grilling leans on parametric knowledge → use a frontier model; implementation is mostly contextual → a dumber model suffices.
6. **Parallelism, gradually.** Two grilling sessions in parallel is sustainable ("really it's just managing two separate Slack threads at the same time"); more comes with practice.

Note the source's own framing: complaints like "it just asked me 200 questions" were diagnosed as "probably… just a skill issue" in the human's context management. That is exactly the variance this chapter exists to remove — so put these six items in the onboarding material, not in tribal memory.

## Escalation Paths When the Flow Fails

The flow will fail. The blueprint's job is to make each failure mode route to a named procedure rather than to improvisation.

**Slop got merged → de-slop.** When agent output has accumulated into a mess — "AI has simply accelerated software entropy… codebases are falling apart faster than they ever have before" — run the `improve-codebase-architecture` skill ([Chapter 8](08-review-and-qa.md)): it scouts the repo for deepening opportunities, grills you through the redesign of *one* candidate at a time, and exits via to-spec/to-tickets into the normal pipeline. Two hard constraints: turn auto mode off (it "does funny things" with human-in-the-loop flows), and never run it fire-and-forget — "this requires a judgment call from you, the programmer, sitting above the LLM." Cadence: weekly, or every couple of days in a fast-moving codebase, and always after "a sudden surge of development." This is also the mandated first step in any legacy codebase, before AI changes anything.

**The backlog got messy → triage.** Team backlogs fill with other people's ideas — un-reproduced bugs, out-of-scope feature requests. `/triage` works the queue through the label state machine, auto-closes enhancement requests that match the `.out-of-scope/` ADRs (durable records of what the project will NOT build), and forces a brief before anything becomes `ready for agent`. Managing AFK agents "is essentially queue management. We're just pruning a queue and acting as a translation layer between the humans creating these tickets and the AI that's going to implement them." When the triage agent gets "a little bit too credulous" about a reporter's claims, chain the `diagnose` skill in the same session — "diagnose this yourself" — so the bug is reproduced (regression test first) before it's actioned.

**The session went sideways → handoff.** Mid-session discoveries — an out-of-scope bug, a question that needs a prototype, a session drifting toward the dumb zone — are handled by `/handoff` ([Chapter 7](07-execution.md)): compress the session into a disposable document (content, "the vibe of the context window and the intent of the context window," plus suggested skills for the next session), and seed a fresh agent with it. Always state the purpose when invoking. Because the artifact is plain markdown, the recipient can be a different harness entirely — which is also the simple mechanism for adversarial cross-agent review. And because it's a document, it works between *people* as naturally as between sessions.

**The agent is confidently wrong → push back.** Never argue from your own memory; make it verify. When an agent falsely claimed no test harness existed, the two-word correction "look harder" found the whole suite. The general rule from [Chapter 2](02-principles.md) applies with force in a team, where a wrong claim can propagate into tickets: never trust, always verify against the code.

## Collaborating With Stakeholders Outside the Agent Session

Not everyone you need input from lives in the agent session — or is AI-native. A stakeholder, a spouse, a teammate without Slack/Teams access may hold decisions only they can make, but they are not sitting next to your harness. The **to-questionnaire** skill (v1.2) bridges that gap: during a grilling or Wayfinder session, it pulls the decisions and questions out into a shareable markdown document. You put that document into a Google Doc (or equivalent), send it to the stakeholder, walk through it together while they comment and answer in the doc, then pull the answers back into the agent.

Pocock's worked example: he used Wayfinder (with to-questionnaire) to plan a garden office, and the real stakeholder was his wife — not in the agent session, not AI-native. The questionnaire exported the open decisions into a document she could annotate on her own terms, and the answers flowed back into the planning. The same pattern applies to any teammate or decision-maker who cannot be tagged into the agent's channel.

> **Why it works:** The person you really need to speak to often isn't in the agent session; to-questionnaire bridges the agent-human collaboration gap for people without Slack/Teams or who aren't AI-native. It is a patch for a current limitation, not a permanent fixture — the aspirational end state is the agent living in Slack/Teams where stakeholders can tag it in, collaborate and answer questions together in-channel, then the agent implements directly. Pocock explicitly hopes to delete the skill once that gap closes. Treat it as a workaround with a retirement condition, not as permanent process.

For a team, the implication is twofold: install the questionnaire path now for stakeholders who cannot join the agent's channel, and pursue the better future state — getting the agent into the team's collaboration tool so stakeholders can tag it in directly. The questionnaire is the bridge; in-channel collaboration is the destination.

## Economics and Model Strategy

A team workflow is also a token-spend workflow, and the ground shifted under it: Anthropic's "dedicated monthly credit" (effective June 15) capped programmatic usage — the Claude Agent SDK, `claude -p`, Claude Code GitHub Actions, and third-party Agent-SDK apps — at a credit matching your plan price (Pro $20, Max 5x $100, Max 20x $200/month; Team plans likewise), with no rollover, while human-in-the-loop usage (Claude Code in the terminal/IDE, the web/desktop apps) stays on normal subscription limits. Framed as a bonus, it is the opposite for AFK-heavy teams: because a 20x Max subscription had been estimated at up to ~$5,000/month of API-credit-equivalent value, capping programmatic use at $200 "feels more like a 5x or a 10x cut." Anthropic is explicitly prioritizing human-in-the-loop usage "way above" AFK.

The strategic response Matt Pocock adopted, and the pattern to copy:

- **Split workloads by bucket.** Keep the Claude subscription for human-in-the-loop work — planning especially, which he calls "basically half my work" — and move AFK/programmatic workloads to a provider without an AFK/human-in-the-loop split (at the time, Codex: "you've got a subscription, you can use it for anything," with the caveat "we'll see how long that lasts").
- **Follow the subsidies.** Choose providers by raw bang-for-buck per workload type, and expect to re-decide as pricing changes. He also notes the announcement's silver lining: the old rules were an untenable pile of edge cases, and the new policy "cuts through the Gordian knot" — clarity has value for anyone budgeting a team.
- **Check compliance for factories.** If you run your own AFK orchestration, note that Anthropic is "a little bit funny" about subscription-driven automation — use API keys for sandboxed factory runs and check current guidance.

**Effort levels** are a second lever. The skills are explicitly designed to work "across harnesses, models, and effort levels"; Matt's own setup is Opus-class on *medium* effort for the standard flow, while the Steinberger-style parallel-delegation workflow Karpathy describes uses *high* reasoning effort, at which properly-prompted tasks take ~20 minutes each. Combine this with the grilling rule from onboarding — frontier model for design work (parametric knowledge), cheaper model for implementation (contextual knowledge) — and even micro-spend follows a policy rather than a habit. (His feedback-button pipeline uses Haiku just to generate issue titles: the cheapest model that can do the job.)

**Token throughput is the resource to manage.** Karpathy's framing: treat tokens the way a PhD student treats GPU flops — "I feel nervous when I have subscription left over — that just means I haven't maximized my token throughput." For a team this means: while any agent runs, queue more non-interfering work; if one provider's quota is exhausted, switch harnesses; and treat an idle subscription as a signal that the humans, not the models, are the bottleneck. The counterweight is his own caution: don't push autonomy past what current capability supports — "if you try to go too far ahead, the whole thing is actually net not useful."

## When You Outgrow Off-the-Shelf: Building on the AI SDK

At some point a team's process wants shapes the harness doesn't ship: a planner that reads your tracker, N parallel implementers, a reviewer per branch, a merger with your standards baked in. The sources' position is to own your own process rather than adopt a vendor's opinionated workflow — demonstrated by Sandcastle, an open-source TypeScript library whose single primitive, `sandcastle.run({agent, sandbox, prompt})`, composes into exactly that pipeline: planner → parallel implementers → reviewer (on any branch with more than one commit) → merger, all in sandboxes, agent-agnostic per step (Claude Code for implementation, Codex for adversarial review, "the power of owning your own process"). Its review prompt has a fill-in coding-standards section — your team's standards become part of the machinery, not a wish. See [Chapter 9](09-afk-and-parallel-agents.md) for the full factory treatment.

For teams building such tooling in TypeScript, the AI SDK is the recommended substrate — one SDK over every provider's ("it really cuts down the amount you have to learn"), and **v6** brings two features that matter for internal team tooling:

- **Tool execution approval (`needsApproval: true`)** — human-in-the-loop gating baked into the framework: a tool marked `needsApproval` pauses before executing; the frontend (`useChat`) renders Approve/Deny; `addToolApprovalResponse` plus the `sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses` helper handles the re-send loop. This is the harness permission prompt, reproduced in your own tools — and it encodes the safety principle every internal tool needs: "Giving the LLM too much power is bad, but giving the LLM not enough power is also bad… give the LLM the option to do these things, but check it before it does it." Hand-rolling this state machine was previously "so so painful and complicated"; framework-native, it's beginner-course material. The cautionary tale is Cursor's early YOLO mode: auto-approving every tool call got users "entire directories deleted."
- **The agent abstraction (`ToolLoopAgent` / `Agent` interface)** — declare an agent (model, instructions, tools) separately from where it's used, with the prediction that teams will eventually "grab agents off a registry just like pre-made components." Honest caveat from the source: at review time the custom `Agent` interface "doesn't really work yet" (unexported types, thin migration guide) — build on the stable `streamText` + `stopWhen` loop (the deterministic step-count backstop that defines an agent) and adopt the abstraction as it matures.

> **Warning:** Whatever you build, sandboxing is non-negotiable for anything unattended: "In order to get agents to run properly AFK, you need them to be sandboxed" — the alternative is an agent that "will do mad things on your system like delete your home directory," plus enterprise-grade exfiltration risk.

## Measuring Success

The sources do not hand over a metrics dashboard, but they are consistent about what counts:

- **Business impact with numbers, not craftsmanship.** Bassam's rule for engineering value predates AI and survives it: reward what lands — revenue, growth, customers, hard problems solved, developer experience — not architectural impressiveness. His concrete AI-era data points are the kind worth collecting: ~90% of production code agent-written; a 2–3 day benchmarking task done in 20 minutes by delegating "write three distinct benchmarks, run them, analyze them" to an agent.
- **Throughput of the system, not busyness of the humans.** Karpathy's KPI — "what token throughput do you command?" — translated to a team: is the `ready for agent` queue full? Are agents idle while developers type? Matt's parallel-planning claim gives the human-side number: two concurrent grilling sessions roughly doubles planning throughput.
- **Gate health as a leading indicator.** The observable improvements the sources report all follow from process, and regress when process is skipped: "as you keep running this [architecture skill]… the quality of the agents' output goes up"; the Fowler-smells review addition was "outrageously useful" for code quality at a cost of ~10 lines; the reviewer catching what the implementer missed is the pattern that "has been incredibly powerful." Track whether the gates are actually running — reviews on every change, QA plans on every user-facing change, briefs on every ready-for-agent ticket.
- **Beware Goodhart.** The moment you optimize a metric with an autonomous loop, the loop will overfit it — Karpathy's mitigation is to keep expanding metric coverage. And "if you can't evaluate it, you can't auto-research it": only put numbers on things you can actually verify. The sources also model honest epistemics about your own process changes — "I'm not doing evals here. Maybe I should be" is the correct level of humility when a skill tweak ships on vibes.

## Anti-Patterns That Quietly Reintroduce Skill Issues

Each of these looks like a harmless shortcut; each one silently makes output quality depend on individual talent again.

- **Global or per-person skill installs on a team.** The moment developers run private skill variants, one person's fix stops propagating and the flow diverges. Project scope, contributions by PR.
- **Skipping the confirmation gate / letting plan mode plan.** Plans that appear before shared understanding is reached are exactly the failure grilling was built against — plan mode "will tend to just spit out a plan really early."
- **Implementing PRDs directly.** "Don't implement PRDs, only implement actual issues." Specs are destinations; only session-sized tickets are executable.
- **"Do every single ticket."** Stacking tickets in one session blows the smart zone and degrades everything after ~140k tokens — attention degradation, "weird hallucinations." One ticket, check budget, usually clear.
- **Letting the writer review its own code.** The agent "already has written the code" and approves it. Fresh subagents, always — the same reluctance shows in refactoring: "while its own code is sitting in its own context window, it's quite reluctant to change it."
- **Clearing context before banking it.** Never `/clear` a grilling session until its decisions live in a spec, tickets, or a handoff document.
- **Ready-for-agent without a brief; PRDs labeled ready-for-agent.** Both let AFK agents pick up work that isn't executable, wasting runs and producing slop.
- **Instructions where hooks belong.** Every deterministic rule left in CLAUDE.md is a probabilistic rule — and a per-developer one, if their local settings differ.
- **Auto mode on human-in-the-loop skills; YOLO mode anywhere.** The first breaks judgment flows (de-slop, triage); the second is how directories get deleted.
- **Stale research and stale QA plans.** Research assets live only for the sprint — stale research "cause[s] the agent to take a wrong turn." Close QA-plan issues once behavior changes, or the agent treats them as source of truth.
- **Scheduling days of AI tasks into the future.** Teams that queue speculative work "end up with crap because they aren't building on a foundation that they are aligned with." Build on something that works; plan the next slice from there.
- **Skipping the human taste loop on UI.** "The AI just simply can't see what it's building" — front-end work without a prototype-and-feedback phase produces slop no review skill recovers.
- **Trusting confident output.** The foundational discipline from [Chapter 2](02-principles.md): reproduce bugs, verify claims ("look harder"), read the sources on anything critical. A team that stops verifying has re-personalized quality — it now depends on whoever happens to be credulous.

## Checklist

- [ ] Repo passes the [Chapter 3](03-preparing-your-codebase.md) readiness bar: deep modules, tests at seams, minimal CLAUDE.md with docs pointers
- [ ] Skills installed at **project scope**, symlinked, from one shared repo; context tax verified with `/context`
- [ ] Setup skill run: team's real issue tracker configured, triage labels accepted, domain docs (context.md + ADRs) wired into CLAUDE.md
- [ ] Skill changes go through PR review; one owner handles upstream skill upgrades and audits for stale/renamed skills
- [ ] Every developer runs the same flow: grill (Wayfinder for big/foggy work) → spec → tickets → implement → review → QA
- [ ] Confirmation gate active: no implementation until the human confirms shared understanding
- [ ] Tickets sized to one context window; one ticket per session; clear between tickets
- [ ] Triage state machine live: one category + one state label per issue; `ready for agent` requires a brief; `.out-of-scope/` ADRs recorded
- [ ] `/implement` runs typecheck, build, verification, and two-axis subagent review on every piece of work — automatically
- [ ] QA plans generated for every user-facing change; a human walks them; findings become tickets
- [ ] Every deterministic rule enforced by hooks/lint (PreToolUse blockers, git-push safety hook, pre-commit tests/lint/typecheck), with `settings.json` in the repo
- [ ] New developers onboarded via `/ask-matt`, a teach workspace pointed at the codebase, and the six human-side grilling skills
- [ ] Escalation paths named and known: de-slop cadence scheduled, `/triage` for the backlog, `/handoff` for session splits
- [ ] For stakeholders outside the agent session (non-AI-native, no Slack/Teams), use to-questionnaire to export decisions to a shareable doc, collect answers, and pull them back in; pursue in-channel agent collaboration as the destination.
- [ ] Workloads split by economics: subscription for human-in-the-loop, API/alternate provider for AFK; effort levels and model tiers set per phase
- [ ] AFK execution sandboxed, label-gated, never YOLO; internal tooling (if any) gates powerful tools behind approval
- [ ] Success measured in landed impact and gate health, with Goodhart's law in mind
- [ ] Anti-pattern list reviewed with the team — quarterly re-read recommended

## Sources

- mattpocock/skills: A complete AI Coding workflow, end-to-end
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- Anthropic's "dedicated monthly credit" is actually a huge cut
- AI SDK 6 is SWEET
- System Design at GitHub Scale: Build Simple, Solve Today's Problems — with Bassam Daidi (Senior SWE, GitHub)
- Andrej Karpathy on No Priors: Agentic Coding, Claws, Auto-Research & the Post-December Workflow Shift
- Your codebase is NOT ready for AI (here's how to fix it)
- 5 Claude Code skills I use every single day
- Learn anything with the /teach skill
- 9 Things People Get Wrong With My /grill-* skills
- I stopped using /grill-me for coding. Here's what I use instead:
- New Skills! /handoff, /prototype, /review and /writing-* | Skills Changelog
- /handoff is my new favourite skill
- New Skills! v1.2 brings /wait-what, /writing-for-agents, and fixes /grill-me
- The 7 phases of AI-driven development
- Building a REAL feature with Claude Code: every step explained
- How to actually force Claude Code to use the right CLI (don't use CLAUDE.md)
- Claude Code tried to improve /init... Is it any better?
- Frontend is HARDER for AI than backend (here's how to fix it)
- I'm using claude --worktree for everything now
- How To De-Slop A Codebase Ruined By AI (with one skill)
- Burn through the backlog from hell with /triage
- Can Cursor's HARDCORE Review Skill Stop The Slop?
- I Open-Sourced My Own AFK Software Factory
- How I use Claude Code for real engineering
- Never Trust An LLM

See also: [Chapter 3 — Preparing Your Codebase](03-preparing-your-codebase.md), [Chapter 4 — The End-to-End Workflow](04-the-workflow.md), [Chapter 5 — From Idea to Spec](05-idea-to-spec.md), [Chapter 6 — Tickets and Planning](06-tickets-and-planning.md), [Chapter 7 — Execution](07-execution.md), [Chapter 8 — Review, QA, and De-Slopping](08-review-and-qa.md), [Chapter 9 — AFK and Parallel Agents](09-afk-and-parallel-agents.md), [Chapter 10 — Building Skills](10-building-skills.md), [Chapter 12 — Skill Catalog](12-skill-catalog.md).
