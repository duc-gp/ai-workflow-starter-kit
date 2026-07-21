# 7. Execution: Implementation Sessions That Do Not Degrade

By the time you reach execution, the thinking is done: the spec describes the destination, the tickets describe the journey, and each ticket is sized to fit one context window. This chapter covers the craft of the implementation session itself — how an agent turns a well-sized ticket into verified, committed code without the slow quality decay that kills long sessions. The tools are old ones: test-driven development, small commits, disciplined branching. As Matt Pocock puts it, "AI coding is not that different from human coding. It's just that you need to be a lot more aware of the constraints and you need to be able to teach the AI about all the fundamentals that we've known for 30 years."

## The /implement Skill: Minimal by Design

The named entry point for execution in the skills flow is **/implement**. Its full contents, near-verbatim:

```markdown
Implement the work described by the user in the spec or tickets.
Use TDD where possible at pre-agreed seams.
Run type checking regularly. Single test files regularly.
Full test sweep once at the end.
Once done, use code review to review the work and then commit
your work to the current branch.
```

That is the whole skill. Pocock almost didn't ship it, because it mostly restates what the agent's training and the harness already teach it to do. He shipped it anyway because it "earns its place" as the named step: when every phase of the workflow has a slash command, nobody has to ask "what's the flow?" — the skill at each stage tells the agent (and the human) what comes next.

> **Why it works:** The skill leans on the model prior. Harness training already covers how to implement, typecheck, and commit; a long skill re-teaching that would just burn context. The skill's job is to pin down the few decisions the prior gets wrong by default — test-first at pre-agreed seams, a verification cadence, review before commit — in as few words as possible. The same principle powers the Fowler-smells trick in [Chapter 8](08-review-and-qa.md): one named concept from a well-cited book unlocks knowledge that is already deep in the agent's prior.

Note the phrase "pre-agreed seams": the seams were agreed during grilling and spec-writing ([Chapter 5](05-idea-to-spec.md)), where interface changes and testing decisions are confirmed with the human. Execution is not where interfaces get designed — it is where they get built.

What /implement actually does in a run, observed end to end:

1. Implements the ticket or plan.
2. Runs typecheck and build.
3. Performs extra behavioral verification (in one demo: checking that `ai-hero internal --help` shows only the one remaining command).
4. Loads the code-review skill and runs the review **in subagents** — never in the main agent (see [Chapter 8](08-review-and-qa.md) for why fresh context matters for review).
5. Commits to the current branch when clean.

To kick off a multi-session build after planning, clear context and seed the fresh session with the tickets:

```text
/clear
@tickets /implement this
```

Because the spec decides where you're going and the tickets decide how you get there, the fresh agent has everything it needs — no conversation history required.

## TDD With an Agent: Red Before Green, One Slice at a Time

Pocock's strongest claim about execution quality: "TDD has been the most consistent way that I've improved agents' outputs." Red-green — a 20-to-30-year-old practice, most prolifically advocated in Kent Beck's *Extreme Programming Explained* — turns out to fit coding agents unusually well. He cites Simon Willison: "The most disciplined form of TDD is test-first development... this turns out to be a fantastic fit for coding agents."

The mechanics with an agent:

1. **RED.** The agent writes a failing test first, before any implementation exists — even before the API method or database schema it exercises. Confirm the test actually fails (visible in CI or the agent's output).
2. **GREEN.** The agent writes a **minimal** implementation to make the test pass — without changing anything about the test. CI goes green.
3. Repeat for the next behavior.

> **Why it works:** Two reasons. First, feedback loops impose **back pressure**: "AI is so eager to create code and find the fastest solution to your problem, you need to impose some back pressure on it to essentially keep it in a stable state." Tests and strong types are that back pressure. Second, red-then-green is an **anti-fake trust signal**: if the agent writes a test, watches it fail, adds the implementation, and the untouched test passes — "if it's a reasonable agent, it's pretty hard for it to fake that." The sequence itself guards against the classic failure mode of the agent quietly modifying a test to make it pass.

That trust signal changes how much you have to read. Because Pocock saw the suite go red and then green, "I don't necessarily read all of the implementations" — he skims test titles to understand what is being tested, then relies on the QA pass ([Chapter 8](08-review-and-qa.md)) to catch what the tests missed and flush out any bad tests.

### One test at a time

The single most important rule in the loop: **only one test at a time**. Left alone, LLMs "love to create huge horizontal layers" — one massive file edit adding, say, 90 tests, followed by an attempt to one-shot an implementation that passes all 90. It can work, but "you end up with a lot of crap tests." One test at a time keeps each test focused on the behavior currently being implemented, so the tests actually guide the implementation. In Pocock's words: "This one test at a time idea is really focused on improving the quality of your tests."

### The evolution: refactoring moved out of the loop

The TDD skill has changed shape over time, and the change matters:

- **Originally**, the skill encoded classic red-green-**refactor** plus interactive steps: confirm interface changes with the user, confirm which behaviors to test, design interfaces for testability, then loop — failing test, minimal pass, look for refactor candidates.
- **The refactor step underperformed.** Pocock observed that an LLM is "quite reluctant to change" code sitting in its own context window — it just wrote it, so it approves it. The interactive steps also clashed with AFK use: "you should be able to pass an AFK agent the TDD skill and it should just work."
- **Current position (recommended):** the /tdd skill is **reference material only**. It prescribes no interactive steps — only the ordering rule: **"red before green, one slice at a time."** Refactoring is split entirely out of the implementation loop and into the code-review step, because "putting the refactoring in the code review part is a lot more productive because then you don't overload the implementation" — and because review runs in subagents with clean context, which are not precious about code they didn't write.

So the loop during execution is red-green only. The refactor still happens — just later, with fresh eyes, as part of review ([Chapter 8](08-review-and-qa.md)).

One prerequisite worth restating from [Chapter 3](03-preparing-your-codebase.md): TDD "demands a lot of your codebase." In a badly structured codebase, test boundaries are unclear and the loop flails. With deep modules and thin interfaces, you test at the boundaries and the loop hums.

## Tests and Types on Every Commit

Whatever else varies between sessions, this does not:

> **Rule:** Run tests and typechecks on every commit. When Pocock describes what makes his AFK loop work, the "crucial success factor" is "making sure it runs tests and types on every single commit."

The /implement skill encodes a cadence tuned for cost and signal:

- **Type checking regularly** — types are a back-pressure loop alongside tests, and catch drift immediately.
- **Single test files regularly** — run the file you're working in, not the world, while iterating.
- **Full test sweep once at the end** — one complete pass before review and commit.

This is the execution-time payoff of the environment work in [Chapter 3](03-preparing-your-codebase.md): a repo where tests and types run fast and reliably is a repo where every commit is verified without anyone deciding to verify it. In the observed Ralph-loop run, every one of the six commits landed with tests and types green and a detailed commit message — with no human at the keyboard.

This is what makes the **day shift / night shift** split work: the human does the thinking — grilling, specs, tickets — in the day shift, while agents execute AFK in the night shift. The gated cadence above is precisely what lets that night-shift work run unattended without degrading: every commit is self-verified, so there is no need for a human to babysit it.

## Context Hygiene: Clear Between Tickets, Budget the Smart Zone

Quality decay in long sessions is not mysterious — it is the **smart zone** filling up ([Chapter 1](01-how-llms-actually-work.md)). Pocock treats the context window as "ending or getting significantly dumber at around the 140k mark"; past it comes attention degradation — "it ends up getting stupider, does weird hallucinations." (In an earlier video he put his felt limit lower, around 120k: "really for proper smart tasks you've only got about 120k to work with." Either number leads to the same discipline.) "Being conscious about the context window that you're using, the tokens that you're using, is essential to using AI well."

The execution rules that follow:

- **One ticket per session.** Tickets were sized to one smart zone in planning ([Chapter 6](06-tickets-and-planning.md)); stacking them into one session defeats the sizing. Do NOT say "do every single ticket."
- **Check the budget after each ticket.** If you finish a ticket well short of the limit, you can sometimes squeeze in one more — but the default is:
- **Clear between every ticket** (`/clear`), then re-seed with `@tickets /implement this`. The spec and tickets are the durable state; the conversation is disposable.

### Side quests without polluting history

Two mechanisms keep quick detours from contaminating the session:

- **"By the way" side questions.** Claude Code lets you ask a quick question that does **not** enter the chat history — Pocock used it mid-session to ask "describe what's going on with the course write service — its shape and capabilities," then exited with space-enter or escape. Use it for orientation questions you don't want permanently occupying context.
- **Explore subagents.** When the agent needs to understand a chunk of the codebase, an explore subagent reads "tons and tons of files" in its own context window and hands back only a summary. This is why a whole /implement run can land at just 42.7k tokens despite heavy codebase reading. Pocock's one complaint: "I do wish that explore was faster. You need it in every single session, sometimes multiple times a session."

One more mid-session correction worth knowing: when the agent confidently claims something false about the codebase ("there's no existing test harness for course write service"), don't argue — say **"look harder."** In Pocock's session it then found the entire existing suite.

## /handoff: Compressing Session State for a Fresh Start

Mid-implementation, work appears that doesn't belong in the current session: an out-of-scope bug, a refactor idea, a question that needs its own investigation. The bad options are extending the current session (diluted context, guaranteed dumb-zone entry, "half working on one thing, half the other") or `/compact` (which clobbers the current session's focus to switch tasks). The right tool is **/handoff**: compress the relevant slice of the current session into a disposable markdown document that seeds a *different* session — possibly a different harness entirely.

The skill's instructions, near-verbatim:

```markdown
Write a handoff document summarizing the current conversation so a
fresh agent can continue the work.
Save it to the temporary directory of the user's operating system,
not the current workspace.
Include a suggested-skills section suggesting skills the next agent
should invoke.
Do not duplicate content already captured in other artifacts —
use pointers instead.
Redact any sensitive information: API keys, passwords, or PII.
If the user passed arguments, treat them as a description of what
the next session will focus on and tailor the document accordingly.
```

Each line encodes a lesson:

- **Temp directory, not the workspace** — "these handoff files are disposable. They are not something to be kept around... to rot in your codebase as documentation."
- **Suggested skills** — skills "define the flavor of that session"; naming them in the doc means the next session auto-invokes the right mode (diagnose, prototype, grill-with-docs) without you thinking about it.
- **Pointers over duplication** — handoff docs bloat if they restate content that already lives in issues or markdown files; reference them instead.
- **Redaction** — you don't want secrets floating around in markdown files in random places.
- **Always state the purpose.** Pocock always passes arguments describing *why* he's handing off and what the next session will focus on (dictation makes this fast): "I just can't see how you would write a good handoff document otherwise."

**When to hand off vs. compact:** if you must barrel on at the *same* problem — long debugging especially — `/compact` is still right: compact away the options already tried, keep going, compact again ("save your state essentially"). Handoff is for *splitting scope*: the new task gets a fresh full smart zone, and the original session's context stays pure. Repeated compaction also leaves a "sediment of different layers" from previous conversations — workable, but inefficient.

Because the handoff artifact is plain markdown, it is harness-agnostic: session one can be Claude Code and the recipient Codex or Copilot CLI — "a very very simple way" to hand work between different agents, including for adversarial review. And the pattern round-trips: a session can hand off to a prototype session (which grew to 169k tokens in Pocock's example — far more than would have fit in the parent), then hand the compressed learnings *back* — "almost like you've done a kind of DIY sub agent." The full prototype round-trip lives in [Chapter 5](05-idea-to-spec.md).

Pocock's meta-lesson: he resisted making /handoff a skill because it seemed too simple — then noticed "I was doing this so freaking often that I just decided, okay, I need a skill for this." Frequency of use, not complexity, justifies packaging ([Chapter 10](10-building-skills.md)).

## Parallel Sessions With Git Worktrees

Git worktrees give you multiple branches checked out simultaneously in separate folders of one repo — and Claude Code now manages them natively via **`claude --worktree`**. Pocock's verdict: "I'm not sure why you wouldn't want to use git worktrees like every single time you use Claude." Each agent gets its own isolated checkout, so multiple sessions run in parallel without interfering, and "parallelization becomes a lot more free than it was before": every idea can instantly get its own worktree, be worked on by an agent, and flow back to main as a PR.

Mechanics:

1. From your repo, run `claude --worktree`. Claude creates a worktree at a path like `.claude/worktrees/cheerful-coalescing-worth` (auto-generated names) using plain `git worktree` under the hood, and runs the session inside it.
2. Work normally: the agent edits, commits, and can push and open a PR from inside the worktree.
3. On quitting the session, Claude prompts you to **keep or remove** the worktree.

> **Warning:** If you remove the worktree without having pushed, all changes and commit history in it are lost. Push first, then remove.

> **Warning — the branch tracks its source.** A Claude worktree's branch tracks the branch it was created from (usually main): `git status` inside the worktree reports "up to date with origin/main," and a plain `git push` pushes **to main**. In Pocock's first experiment a commit landed on main unexpectedly ("my first paper cut"); only his push-blocking safety hook caught the second one. The fix: the agent must push to an explicitly named branch — `git push origin <worktree-branch-name>`. "If your main branch is not protected and you create a worktree from it, you might end up accidentally pushing commits to main when you wanted to push them to a separate branch." Mitigations: prompt the agent to push to the named branch, protect main, and run a hook that blocks agent-initiated pushes so you confirm the exact command ([Chapter 3](03-preparing-your-codebase.md)).

The appeal is lifecycle alignment: one worktree per agent per unit of work, created and destroyed with the session — "I just love it when a tool kind of absorbs the complexity of another tool into itself and helps you manage its lifecycle." The manual baseline still works when you want it: `git worktree add <name>` creates the folder on a new branch of the same name; VS Code's Source Control panel shows each worktree as a separate repository you can stage, commit, and PR from; clean up with `git worktree remove <name>` (roughly equivalent to `rm -rf <folder>`), and `git pull` in the main checkout after merging.

Subagents support worktrees too: a parent agent can spin up a subagent in its own worktree and have it PR back to main, orchestrated "from above" — but it appears to be **opt-in**; you must ask Claude to use worktrees for its subagents. That pattern scales up into the fleet setups of [Chapter 9](09-afk-and-parallel-agents.md).

## Commit Discipline

Commits during execution are frequent, verified, descriptive, and agent-authored:

- **Frequent and verified.** The unit of progress is a commit with tests and types green — in the observed AFK run, 5 iterations over ~1.5 hours produced 6 commits, each gated on the full feedback loop.
- **Descriptive, with issue references.** Agent commit messages are detailed and reference the ticket they implement; in the Ralph-loop flow the agent also comments on the issue (e.g. "a pure function document editing engine with 28 tests covering all acceptance criteria") and closes it, which unblocks the next one.
- **Agent-authored to the current branch.** /implement commits to the current branch itself once review passes; in worktree sessions the agent runs `git add` / `git commit` and pushes on request. Pocock still occasionally commits by hand (his glossary update after a grilling session), but the default is that the agent owns its commits.
- **Human-gated pushes.** Verify branch state with `git status` / `git log`, keep a hook that blocks agent pushes so you confirm the exact command, and always push to a named branch from worktrees.

Frequent verified commits are also what makes the rest of the workflow cheap: the QA-plan generation in [Chapter 8](08-review-and-qa.md) is literally "take the last five commits and create a QA plan" — it only works when the commit history is a clean, descriptive record of what changed.

## Checklist

- [ ] Kick off each ticket in a fresh session: `/clear`, then `@tickets /implement this` — spec and tickets carry the state, not conversation history.
- [ ] Keep /implement minimal: TDD at pre-agreed seams, typecheck regularly, single test files while iterating, full sweep at the end, review, commit.
- [ ] Run TDD red-before-green: failing test first, confirm the failure, minimal implementation without touching the test.
- [ ] Enforce one test at a time — never let the agent splurge a horizontal layer of tests and one-shot the implementation.
- [ ] Keep refactoring OUT of the implementation loop; it happens at code review, in subagents with fresh context.
- [ ] Skim test titles rather than reading every implementation — the red-to-green sequence is your trust signal; QA catches the rest.
- [ ] Gate every commit on tests and types passing.
- [ ] Treat ~120–140k tokens as the smart-zone limit; check the budget after each ticket and default to clearing between tickets.
- [ ] Use "by the way" side questions and explore subagents to keep detours and codebase reading out of the main context.
- [ ] Say "look harder" when the agent confidently denies something exists in the codebase.
- [ ] /handoff out-of-scope work with an explicit purpose; /compact only to barrel on at the same problem (e.g. debugging).
- [ ] Keep handoff docs in the OS temp dir, pointer-based, redacted, with a suggested-skills section.
- [ ] Run parallel sessions in worktrees (`claude --worktree`); push to a named branch (`git push origin <worktree-branch>`) before removing the worktree.
- [ ] Protect main and keep a push-blocking hook so agent pushes get human confirmation.
- [ ] Require frequent, descriptive, agent-authored commits that reference their tickets.

## Sources

- Red Green Refactor is OP With Claude Code
- I'm using claude --worktree for everything now
- /handoff is my new favourite skill
- New Skills! v1.1 brings /wayfinder, /research, /implement, /to-spec, /to-tickets
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- 5 Claude Code skills I use every single day
- Building a REAL feature with Claude Code: every step explained

See also: [Chapter 1](01-how-llms-actually-work.md) (smart zone and context windows), [Chapter 3](03-preparing-your-codebase.md) (feedback loops and hooks), [Chapter 4](04-the-workflow.md) (where execution sits in the flow), [Chapter 6](06-tickets-and-planning.md) (sizing tickets to one context window), [Chapter 8](08-review-and-qa.md) (the review that receives the refactoring), [Chapter 9](09-afk-and-parallel-agents.md) (Ralph loops and agent fleets).
