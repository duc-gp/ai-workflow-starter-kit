# 6. Tickets and Planning: Slicing the Journey

The spec tells you where you are going; it says nothing about how to get there. This chapter covers the planning phase: turning a spec into tickets sized so that each one fits a single agent session, wiring blocking relationships between them so agents (and humans) always know what can be worked on right now, and keeping the whole apparatus tracker-agnostic. It also covers the two planning tools that sit outside the happy path: `/triage`, for backlogs full of other people's ideas, and Wayfinder maps, for ideas too big and foggy to spec at all yet.

## Spec Is the Destination, Tickets Are the Journey

Matt Pocock's framing is the anchor for this whole phase:

> "The spec is the destination that we're heading to... and the tickets is the description of how we're going to get there."

And in an earlier form, from his real-feature walkthrough: "If the parent PRD is the destination, then these issues are the journey to get there."

The distinction matters because the two documents do different jobs. The **spec** describes the end state — problem statement, solution, user stories, implementation decisions, testing decisions (see [Chapter 5](05-idea-to-spec.md)). The **tickets** slice that end state into an ordered sequence of agent sessions. Neither can substitute for the other: a spec alone is too big to execute in one context window, and tickets alone lose the global picture the agent needs to verify against at the end.

Where this sits in the main flow (the full pipeline is [Chapter 4](04-the-workflow.md)):

1. Grilling produces shared understanding; `/to-spec` compresses it into a spec published to your issue tracker.
2. **In the same session — do not clear** — run `/to-tickets`. The spec and the grilling discussion are still in context, which is exactly why the generated tickets are trustworthy (more on that below).
3. Clear context, then implement ticket by ticket: `@tickets` + `/implement this`. Because the spec decides where you're going and the tickets decide how you get there, the fresh agent has everything it needs.

There is a fork in the road before any of this: if, after grilling, the remaining work fits inside the remaining smart zone of the current session, skip tickets entirely and just say `/implement this`. In his end-to-end demo, Pocock estimated "we've got 100k of budget here to remove 10 commands — super easy" and could have gone straight to implementation. Tickets exist for the other case: **work that spans multiple sessions needs durable state**, because the smart zone is finite and nothing survives `/clear` except what you wrote down.

A naming note, because the names encode the model. These skills were originally `/to-prd` and `/to-issues`. Pocock renamed them in v1.1 of his skills repo to `/to-spec` and `/to-tickets` — "a little bit of friction, but good friction because it names it properly." "Issues" was biased toward GitHub/Linear terminology; "tickets" is tracker-neutral: "you have a spec and then underneath the spec you have the tickets that are the journey that you take to actually enact the spec." Use the new names; if you installed the old skills, note that the installer does not auto-migrate renames — delete the old skills and re-add.

## The Sizing Rule: One Ticket = One Smart Zone

> **Rule:** Each ticket is sized to fit a single context window — one smart zone, one agent session. "Each one of these tickets is supposed to just be the size of a single context window or a single smart zone."

This is the single most important property of a good ticket, and it comes directly from the mental model in [Chapter 1](01-how-llms-actually-work.md): the context window "ending or getting significantly dumber at around the 140k mark" — above that comes attention degradation and "weird hallucinations." A ticket that cannot be completed inside that budget will be completed badly.

The rule cuts both ways:

- **Too big → context blowout.** The agent runs past the smart zone mid-ticket and the tail end of the work degrades. This is also why you implement tickets one at a time and usually clear between every single ticket — do NOT say "do every single ticket." Each ticket was sized to one smart zone; stacking them defeats the sizing.
- **Too small → session startup overhead.** Every agent session pays a startup cost: the agent re-explores the repo in a fresh context window before doing anything useful. Pocock's example: "hide the publish/export UI" is a tiny change — spinning up an entire agent for it wastes that startup cost. Merge it into a neighboring ticket. A ticket that touches UI + schema + API together is decently sized.

**Slicing is negotiable — this is your review point.** The skill proposes a slicing; you push back on granularity before the tickets are created:

```text
do it in one slice instead
```

```text
merge two and three together
```

In his real-feature build, the skill proposed six issues; he merged them down to four. In the skills-repo demo it proposed three slices for small work and he collapsed them to one. You are not editing ticket text here — you are adjusting portion sizes.

> **Why it works:** The sizing rule is context budgeting made structural. Instead of watching the token counter and hoping, you pre-commit every unit of work to a size the agent can handle at full intelligence. "Being conscious about the context window that you're using, the tokens that you're using, is essential to using AI well."

## Ticket Anatomy

Each generated ticket contains:

- **A link to the parent spec/PRD.** The implementing agent pulls in the parent, so the destination is always one hop away. In `/triage`-fed pipelines the same rule holds: tickets based on PRDs carry a parent reference, and the AI picking up the ticket sees the parent PRD as well.
- **What to build in this session.** Each ticket is "literally what do you build in this session" — short, because the heavy content lives in the spec.
- **Acceptance criteria.** How the agent (and the final review) knows this slice is done.
- **Blocked-by relationships.** Which tickets must complete first.
- **The user stories from the parent spec that this ticket addresses.**

Keep the tickets short. Pocock flagged his own demo tickets as "a bad example" because they duplicated the PRD content. His real-world reference point — a "removal spree" spec with 11 sub-issue tickets — had each ticket quite short, with acceptance criteria living mostly in the main spec. The ticket is a pointer plus a session-sized instruction, not a second copy of the spec. Duplicated content drifts, and drift between spec and ticket is exactly the kind of ambiguity that sends an unattended agent down the wrong path.

The slicing rule the `/to-tickets` skill applies is: "each issue is a thin **vertical slice** that cuts through all integration layers, not a horizontal slice of one layer" — a good slice touches UI + schema + API together rather than splitting a feature into a "frontend ticket" and a "backend ticket" that can't ship independently. Slices are also ordered to flush out unknown unknowns first — tracer bullets — so the riskiest unresolved question gets built and proven early rather than last. See [Chapter 12](12-skill-catalog.md) for the full construction notes.

## Why You Don't Hand-Review Generated Tickets

This surprises people: after adjusting the slicing, Pocock does not read the generated ticket text. Asked whether he reviews the issues — "Absolutely not... it's just expanding out stuff that's in the PRD." Same for the spec text itself: "LLMs are really, really good at summarizing things," so accept it on faith.

The reasoning is not blind trust (see [Chapter 2](02-principles.md) — the rule is still *never trust an LLM*). It is that the review already happened, upstream, in a form far more effective than proofreading:

- The tickets are generated **in the same session** as the spec, which was generated in the same session as the grilling conversation. Everything the tickets contain was said, challenged, and confirmed by you during grilling. You "pre-reviewed" them by having the conversation.
- Summarizing in-context material is the one task LLMs are reliably excellent at. The failure modes worth your attention are elsewhere: wrong slicing granularity (which you *do* review) and wrong decisions (which grilling already caught).

So the human review budget for this phase is spent on exactly two things: **is the slicing right** (merge/split), and — earlier, during spec creation — **are the module interfaces right**. Everything else is mechanical expansion.

## Blocking Relationships and the Kanban Board

A **kanban board**, in this workflow, is nothing more than a list of tickets with blocking relationships between them ("blocked by #1"). Those relationships do two jobs:

1. **They serialize what must be sequential.** Schema changes before the API that uses them; the key architectural decision before everything that depends on it.
2. **They expose what can be parallel.** At any moment, the set of *unblocked* tickets is the parallelization frontier: you can spin up one agent per unblocked ticket.

This is precisely how the AFK machinery consumes the board. In Sandcastle (Pocock's open-sourced AFK software factory, covered in [Chapter 9](09-afk-and-parallel-agents.md)), the planner agent gathers all labeled open issues, their labels and comments, and "works out which issues can be done *right now*" — only unblocked issues get picked up and handed to parallel implementers. The blocking graph you create at planning time is the schedule the agent fleet runs on.

That said, don't over-parallelize. Pocock's own experience, per the notes: usually a single sequential agent working through each ticket is enough. Parallelization is rarely needed; a single loop working the board in order gets you nearly all of the value with none of the merge-conflict cost. Reach for parallel agents when the board is wide (many genuinely independent tickets) — not by default.

On tracker support for blocking relationships, the sources evolved:

- In the earlier 7-phases video, Pocock used GitHub Issues for both PRD and board but noted GitHub had no built-in blocking-relationship representation, suggesting Linear (which has one) as a better fit for dependency-aware planning.
- The newer material works the relationships on GitHub anyway: Wayfinder saves its maps as GitHub parent issues with **sub-issues and blocking relationships**, and his Ralph-loop tickets carry "blocked by #N" references that the planner respects.

The newer position — and the recommendation — is that the blocking graph lives in the ticket *content and structure*, expressed in whatever tracker you use; a tracker with first-class dependency support like Linear is a convenience, not a prerequisite.

## Tracker-Agnostic by Design

The skills do not care which issue tracker you use. During the one-time `/setup-mattpocock-skills` run, you pick where specs and tickets get saved — and the choices are "effectively infinite": GitHub Issues, local markdown files, Jira, Linear, beads, "literally anything." There is no adapter to write. You configure it conversationally:

```text
set it up with Jira
```

```text
I'm just going to set it up with local markdown please.
```

The setup skill reads local configuration and configures itself; it then writes links into `CLAUDE.md` pointing at issue-tracker docs, triage-label docs, and domain docs under `docs/agents/` (see [Chapter 3](03-preparing-your-codebase.md) for the full setup). Every downstream skill — `/to-spec`, `/to-tickets`, `/triage`, `/implement` — reads that configuration rather than hardcoding a tracker. Pocock notes people constantly ask "how do I make the skills work with Jira/beads/Linear?" — the answer is that they already do; just say so during setup.

Which tracker should you actually pick? The notes support a few heuristics:

- **Local markdown** (e.g. a `tickets.md` in a scratch directory) is the lowest-friction option and what Pocock chose for his own demo repo. Fine for solo work.
- **GitHub Issues** is his workhorse for anything AFK or collaborative: the Ralph loop and Sandcastle both pull work by querying issues, Wayfinder maps live there, and PRs can reference issues so merging auto-closes them. "AFK agents need a way to pick up tickets and know what to do next" — a shared tracker is that interface.
- **Linear** if you want first-class blocking-relationship support (see above). **Jira** if your team already lives there — the skills genuinely don't mind.

The team-relevant point: because Wayfinder maps and specs live on the repo's issue tracker rather than inside one person's chat session, planning becomes "collaborative and shareable across the team" — shared maps beat private session state.

## /triage: The Backlog From Hell

Everything above assumes *you* generated the work, freshly, from a spec. Teams don't get that luxury. Most skill-based AI setups are "great for solo developers, but not so great when you get into teams" — in a team you must triage *other people's* ideas: decide whether they're worth building, whether a bug needs reproduction, whether a request was already rejected months ago. The `/triage` skill turns a messy human backlog — GitHub Issues, Jira, any backlog — into fully-specified, agent-actionable tasks. Pocock runs it on every open-source repo he maintains.

### The label state machine

Triage is driven by a label-based state machine. Every triaged issue carries **exactly one category label and exactly one state label** — "This is a good old state machine." Illegal combinations (an issue that is both `ready for human` and `needs triage`) are impossible by construction.

| Role | Labels |
|---|---|
| Category (pick one) | `bug`, `enhancement` |
| State (pick one) | `needs triage`, `needs info`, `ready for agent`, `ready for human`, `won't fix` |

The states mean: `needs triage` — paused until a maintainer looks at it; `needs info` — waiting on the reporter; `ready for agent` — fully specified, ready for an AFK agent to "go and slam through the task"; `ready for human` — needs a human to implement it now; `won't fix` — will not be actioned. Pocock marks the taxonomy as provisional — categories "may change in future," states are "up for grabs" — but it currently works.

The load-bearing state is `ready for agent`. His Sandcastle plan prompt only touches issues explicitly carrying that label — this is the coupling point between triage and autonomous execution:

> **Rule:** AFK agents only pick up work explicitly marked ready for them. "Having specific labels for each of those means that the agent is not going to stumble around on crap tasks that aren't ready for it yet."

And the transition into that state has a cost attached: "In order to move something to ready for agent, you need to write a brief for the agent that's going to pick it up." The skill contains an **agent brief template** for exactly this — the same specification bar a `/to-tickets` ticket meets, applied to inbound work.

### How a triage session runs

The skill supports three invocation modes: triage a specific issue, scan the whole backlog ("Show me anything that needs my attention now"), or transition a ticket ("Okay, let's move this one to ready for agent"). A typical backlog-clearing session, as demonstrated on his Sandcastle repo (nine untriaged issues):

1. Open a fresh session in the repo. Say `triage` and: "just give me all of the open issues — or rather just the ones that I haven't triaged yet." The skill explores the repo and detects which tracker is in use.
2. Batch the cheap decisions: "Could you just walk through each of these and add the basic labels to them? Just doing initial triage for me so that I don't need to make that many decisions." Every issue gets `bug`/`enhancement` plus `needs triage`.
3. Work down from the bugs first "since those are going to be a little easier to grok," one at a time: "Could you start with 477 for me?"
4. The skill returns a recommendation per issue (e.g. "It is a bug, move it to ready for agent — the issue already had substantial triage notes pinpointing the exact root cause, reproduced with a stack trace").

> **Warning:** Don't accept reporter-supplied evidence at face value. In the demo the agent recommended `ready for agent` purely on the strength of the reporter's stack trace — Pocock flagged it as "being a little bit too credulous" and forced independent verification by chaining his `diagnose` skill in the same session: "diagnose this yourself." The diagnose skill reproduces the bug and builds the regression test *first*, then fixes inside that feedback loop (the TDD pattern — [Chapter 7](07-execution.md)).

Once diagnosed, you can fix right there in the same session if context budget allows — Pocock keeps a running mental budget ("I sort of have a budget of 100K for this session") and at 46.5k tokens used judged there was room to diagnose and fix a small bug. Ship via a PR that references the issue so merging auto-closes it (his usual preference over pushing to main). While triaging, he often runs two sessions in parallel: one triaging the next issue, another on main fixing the last one.

### Encoding rejections: the `.out-of-scope/` directory

The recurring cost of enhancement triage is re-litigating things you already decided not to build. Pocock's answer is a `.out-of-scope/` directory at the repo root — "essentially an architectural decision record but specifically for features that we're not going to implement." Example entry:

```markdown
Sandcastle does not provide an abstraction layer for composing
Docker files or managing base images programmatically.
```

When the triage agent processes enhancements, it checks these files and can close matching requests straight away. A one-time "won't do" decision becomes an automatic future triage rule.

The mental model underneath all of this:

> "It's funny how much of AI and how much of managing AFK agents is essentially queue management. We're just pruning a queue and acting as a translation layer between the humans creating these tickets and the AI that's going to implement them."

## Wayfinder Maps: When the Journey Needs a Map First

`/to-tickets` assumes you already have a spec. Some ideas can't get that far: "A loose idea has arrived, too big for one agent session and wrapped in fog. The way from here to the destination isn't visible yet." For those, Pocock's `/wayfinder` skill inserts a mapping stage *before* the spec — and he now recommends defaulting to it over `/grill-with-docs` for big work (he uses it "for literally everything, even non-coding stuff," including planning his own course).

Wayfinder "charts the way as a shared map on the repo's issue tracker": a parent GitHub issue is the map, and every decision that needs making becomes a **sub-issue with blocking relationships** — the key decision at the start blocks everything downstream. Two properties make these planning artifacts rather than just more tickets:

1. **Each sub-issue is scoped to the size of one agent session.** The sizing rule applies to planning work exactly as it applies to implementation work.
2. **Each sub-issue carries a ticket type**, defined at the bottom of the map ticket:

| Type | What it is |
|---|---|
| **research** | An AFK task — the agent goes off, investigates against primary sources, comes back (uses the `/research` skill) |
| **grilling** | A decision that needs an interview session with you |
| **prototype** | "Raise the fidelity of the discussion by making a cheap rough concrete artifact to react to" — via the `/prototype` skill; use when "how should it look" or "how should it behave" is a key question |
| **task** | Config, provisioning, moving data into shape — "the boring stuff that doesn't need a grilling decision and can't really be automated by AI" |

(The research, grilling, and prototype techniques themselves are [Chapter 5](05-idea-to-spec.md); here they appear as *typed nodes in a plan*.)

You work the tickets one at a time, each in its own session, "until the route is clear" — close a session, open the next Wayfinder ticket. When all tickets are closed, the captured information is saved onto the map, with the closed tickets remaining as "primary sources for what was captured." Then the completed map feeds the normal pipeline: "once the map is done... you just go to to-spec and you're good to go" — and from spec to `/to-tickets` as usual.

Why this beats grinding through one giant planning session: "Instead of having the anxiety of managing my session with Grill with Docs, having to hand off, worry about the smart zone, with Wayfinder it's kind of all managed for me." The map absorbs the session-management problem — every unit of thinking is pre-sliced to session size, and the state lives in the tracker, not in a chat history. Pocock recommends Wayfinder for almost anything touching front-end code, because those efforts nearly always contain "how should it look" or "how should it behave" questions that need prototype tickets.

## Planning Is Not a One-Shot Activity

One caution to close on, because it frames how much to invest in the ticket pile: the board is not a promise, it's a starting position. Pocock is blunt that "the specs-to-code approach is just never going to work" as a complete methodology — QA always surfaces edge cases "really hard to plan for before" (his example: a non-git-repo directory leaving DB and filesystem out of sync — a showstopper never raised in grilling). The last phases of the workflow loop: execution → QA → **new tickets on the board** → execution again ([Chapter 8](08-review-and-qa.md) covers the QA side). So slice well, wire the blocking graph, and then expect the board to keep filling — from QA findings, from the feedback loop, from triage. That's not planning failure; that's the plan working.

## Checklist

- [ ] After grilling, check the fork: does remaining work fit the current smart zone? If yes, `/implement this` now — no tickets needed.
- [ ] For multi-session work, run `/to-spec` then `/to-tickets` **in the same session, without clearing**.
- [ ] Verify every ticket is sized to one context window / one smart zone — one agent session each.
- [ ] Push back on slicing granularity: merge tickets too small to justify agent startup cost ("do it in one slice instead"); a UI + schema + API slice is about right.
- [ ] Confirm each ticket has: parent-spec link, what to build this session, acceptance criteria, blocked-by relationships, user stories addressed — and is short, not a spec copy.
- [ ] Do NOT proofread generated ticket text — you pre-reviewed it in the grilling conversation. Review slicing only.
- [ ] Wire blocking relationships so the unblocked set is always a valid parallelization frontier; default to a sequential agent unless the board is genuinely wide.
- [ ] Pick your tracker at setup time by just telling the setup skill (GitHub, local markdown, Jira, Linear, beads — anything); prefer a shared tracker for AFK and team work.
- [ ] Implement one ticket per session; clear between tickets; never say "do every single ticket".
- [ ] For inbound backlogs, run `/triage`: exactly one category label + one state label per issue; write an agent brief before anything moves to `ready for agent`.
- [ ] Make AFK agents pick up only `ready for agent` work — never let them stumble onto unready tasks.
- [ ] When the triage agent trusts a reporter too readily, force reproduction: "diagnose this yourself."
- [ ] Record rejected features in `.out-of-scope/` files so future triage auto-closes them.
- [ ] For ideas too big and foggy to spec, run `/wayfinder` first: a map issue with typed, session-sized, blocking-linked sub-issues (research / grilling / prototype / task), then `/to-spec` off the finished map.
- [ ] Expect QA to add tickets to the board — plan for the loop, not for a one-shot plan.

## Sources

- mattpocock/skills: A complete AI Coding workflow, end-to-end
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- Burn through the backlog from hell with /triage
- The 7 phases of AI-driven development
- Building a REAL feature with Claude Code: every step explained
- I Open-Sourced My Own AFK Software Factory

See also: [Chapter 4](04-the-workflow.md) for where planning sits in the end-to-end flow, [Chapter 5](05-idea-to-spec.md) for producing the spec that tickets slice, [Chapter 7](07-execution.md) for implementing the tickets session by session, [Chapter 8](08-review-and-qa.md) for the QA loop that feeds new tickets back onto the board, and [Chapter 9](09-afk-and-parallel-agents.md) for the AFK machinery that consumes `ready for agent` work.
