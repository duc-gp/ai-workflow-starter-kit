# 9. AFK and Parallel Agents: Ralph Loops, Factories, Fleets

Everything in this guide so far assumed one human steering one agent session. This chapter is about removing that constraint: autonomous loops that work through a backlog overnight, sandboxed "software factories" that plan, implement, review, and merge without a human at the keyboard, and fleets of parallel agents treated as a workforce. It also covers the part that matters more than the automation itself — the guardrails that make **AFK execution** (an agent working without a human at the keyboard) produce working code instead of a hundred commits of slop.

## The Ralph Wiggum Technique: A For Loop, Not an Orchestrator

The single most important idea in AFK development, in Matt Pocock's telling, is embarrassingly simple. After trying agent swarms, meshes, orchestrators, and elaborate multi-phase plans, the setup that actually ships working code overnight is a bash loop:

> "What if I told you that the way to get this to work is with a for loop."

This is the **Ralph loop** (the "Ralph Wiggum technique", credited to Geoffrey Huntley, whose article was published July 14): a bash script that invokes a CLI coding agent again and again against a backlog until every item passes. "Ralph is a bash loop. You give the LLM some task to complete or list of tasks and you run it again and again and again until it's complete." It is agent-agnostic — Claude Code, opencode, or Codex all work, as long as the harness is invocable from the CLI — and it only recently became viable because the underlying models (Opus 4.5, GPT 5.2 in Pocock's assessment) got good enough that simple orchestration beats clever orchestration.

### Anatomy of the loop

Pocock's `plans/ralph.sh` has this structure:

```text
plans/ralph.sh <max_iterations>
  - error mode on: any error in the script throws
  - REQUIRE the max-iterations argument; error out if missing
    (the backstop "in case the LLM decides never to complete")
  - for each iteration up to max_iterations:
      - log a line
      - invoke the coding agent CLI (Claude Code here; opencode/Codex work too),
        pointing it at plans/prd.json and progress.txt, with the loop prompt below
      - capture the agent's output in a variable, echo it to the terminal
      - if the output contains the completion sentinel "PROMISE_COMPLETE": break
  - on completion, call `notify` — his homemade TypeScript CLI that sends
    a WhatsApp message saying it's complete after X iterations
```

The loop prompt, reconstructed near-verbatim from his walkthrough:

```text
1. Find the highest priority feature to work on and work only on that feature.
   This should be the one that YOU decide has the highest priority,
   not necessarily the first in the list.
2. Implement the feature.
3. Update the PRD with the work that was done (mark items passes: true).
4. Append your progress to the progress.txt file. Use this to leave a note
   for the next person working in your codebase.
5. Make a git commit of that feature.
6. Only work on a single feature.
7. If while implementing the feature you notice the PRD is complete,
   output PROMISE_COMPLETE.
```

Every word of that prompt was earned by a failure:

- Without "highest priority", the agent just picks the first item in the list.
- Without "append" (rather than "update") for `progress.txt`, the agent rewrites the whole file each iteration.
- Without "only work on a single feature", the agent bites off more than it can chew, bloats its context, and produces crappy code.
- Without the sentinel and the max-iterations backstop, the loop can run forever.

### The two files the loop lives on

**`plans/prd.json`** is a JSON array of user stories, each with a `passes: true/false` flag — simultaneously a PRD and a to-do list (`passes: true` means done, skip it). The JSON format is a recommendation from Anthropic's "Effective harnesses for long-running agents" article. Each item describes the desired end behavior *plus explicit verification steps*. His example item for a "beats" feature in his video editor: "In the UI, beats should display as three orange ellipses dots below the clip. Add a beat to a clip. Verify that three orange dots appear below the clip. Verify they're orange colored. Verify they form an ellipses pattern." Iterate on this file with an LLM, and size every task small and *uniformly* — one enormous task among small ones will swallow the LLM.

**`progress.txt`** is an append-only free-text log: "the LLM's memory for this sprint." Each iteration the agent appends what it learned — in his demo it left itself the note "next you might want to think about this PRD item or maybe the beat playback item." Together with git history (one commit per iteration, so later iterations can query what was done), it substitutes for the context lost between iterations. At the end of a sprint he usually just deletes it.

### Why fresh-context loops beat one long session

The whole design follows from one fact covered in [Chapter 1](01-how-llms-actually-work.md): "LLMs get really stupid as you add more tokens to the context window." One agent doing the whole backlog in one context fails — the tasks collectively don't fit, the AI gets confused, and the code degrades. The loop instead gives every task a *fresh* context window that only has to hold one small ticket plus its verification.

> **Why it works:** The Ralph loop mirrors how real engineers work a kanban board — pull the highest-priority ticket, complete it, return to the board, repeat until the sprint is done. And it changes what the human designs: you specify the *end state* (what "done" looks like), not the path. Adding a task is adding one list item; with his old multi-phase plan-mode markdown plans, inserting a task meant finding the exact slot and reworking all the ordering "arrows" by hand. Pocock explicitly abandoned multi-phase plans for Ralph — "this new style of coding… feels so much more intuitive than the stuff we were doing even 3 months ago" — and now writes most of his code this way. He also notes the AI angle on sprints: "the AI has infinite amounts of endurance and can work forever in theory," so a sprint is just an ordered list of tasks, not a time box.

There is also a human-in-the-loop variant, **`ralph-once.sh`**: the same prompt, run for a single iteration in an interactive terminal. Use it for difficult features where you want to steer heavily, and as the best way to *learn* what Ralph can do before trusting it overnight. Even this version felt more productive to him than building a multi-phase plan.

After any loop finishes, the human steps back in: "you go through, read the code, test everything works, and then change the PRD if you need to."

### Three ways to run the tickets — and where implement-spec sits

The v1.3 skills release names three tiers of ticket orchestration, ranked:

1. **Manual loop (worst).** You say "implement ticket one," wait, clear, repeat — "you're kind of acting like a for loop there. It's not really workable."
2. **Sub-agent orchestration (the beginner on-ramp).** The **/implement-spec** skill reads the spec and tickets, explores in its own sub-agent, creates an integration branch, spawns implement sub-agents per ticket (TDD, work trees), merges to the integration branch via a sub-agent, pings off more implement sub-agents until all the work is done, then runs code review on the integration branch, cleans up, and opens a single PR. Use it "where you don't have your like software factory dialed in" — a good on-ramp to AFK workflows before a deterministic loop exists. It is worse than a deterministic loop (deterministic runs the same way every time); stacked PRs are a further alternative.
3. **Deterministic loop (most reliable).** A script that reads each ticket and runs implement on it — the Ralph loop and Sandcastle below. Reliable and cheap (no agent or human burning tokens running the loop), but complicated and patience-consuming to set up; out of range for beginners.

What recently made the middle tier viable: **sub-agents can now spawn sub-agents.** They "used to be nerfed" but are now "as powerful as orchestrator agents" — so "an agent does the babysitting instead of a human."

## Feeding the Loop: Backlogs and Labels

The prd.json version is the minimal Ralph. Pocock's setup evolved: his current loops pull **GitHub issues** as the backlog instead of a local JSON file — issues created by the PRD-to-issues flow ([Chapter 6](06-tickets-and-planning.md)), by his in-app feedback button, and by teammates. A shared issue tracker is what lets AFK agents coexist with humans, and that requires explicit signals about which tickets are agent-safe:

- **Human-in-the-loop labels.** His Ralph prompt includes: "if there's a human-in-the-loop label on it or it looks like it's for humans, don't work on it." He uses this to keep the loop off QA-plan issues, which are instructions for *him*, not the agent.
- **`ready for agent` labels.** His `/triage` skill's state machine (covered in [Chapter 6](06-tickets-and-planning.md)) only lets a ticket carry `ready for agent` once someone has written a brief for the agent that will pick it up — and his factory's plan prompt *only* touches issues explicitly marked with that label. "Having specific labels for each of those means that the agent is not going to stumble around on crap tasks that aren't ready for it yet."

As he puts it: "It's funny how much of AI and how much of managing AFK agents is essentially queue management. We're just pruning a queue and acting as a translation layer between the humans creating these tickets and the AI that's going to implement them."

## Sandcastle: The Open-Source AFK Software Factory

Running an agent AFK immediately hits the permissions problem: an unattended agent can't stop to ask "may I run this command?". The naive fix — YOLO mode, bypassing all permissions — is dangerous:

> **Warning:** "If you do that [YOLO mode], Claude will do mad things on your system like delete your home directory." In enterprise contexts, add data exfiltration and code being sent to third parties to the risk list. Pocock's hard rule: "In order to get agents to run properly AFK, you need them to be sandboxed."

He tried hard to make existing options work — Docker Sandboxes had "so many problems with running it AFK", and every third-party tool "was trying to sell me some third-party service." What he wanted was "a simple TypeScript function that I could run and just say, 'Run this prompt inside this sandbox using this agent.'" So he built and open-sourced **Sandcastle** (the library behind his Ralph runs — it appeared first as `pnpm ralph` with the provisional name Sandcastle, then as the published `ai-hero/sandcastle` package).

### The core primitive

Sandcastle is one function: `sandcastle.run({name, agent, sandbox, prompt, promptArgs})`. The result (branch, commits) comes back as a return value, so you compose pipelines in plain TypeScript — "with this simple function, you can build really, really complex systems." It is deliberately unopinionated: templates are suggestions, agents are swappable per step (Claude Code, Codex), sandbox providers are pluggable (Docker is first-class; you can implement your own). "That's the power of owning your own process."

### The sandbox mechanics

- A **Dockerfile** defines the sandbox — "the instructions for setting up the Docker container" the agent runs inside. The default installs the important system dependencies, the GitHub CLI, and Claude Code, and renames the home directory to `agent`. Install anything you like; everything the agent needs lives inside the container.
- Your **working directory is mounted inside** the container; any commits the agent makes are **pulled out as patches and applied to your local repo**. The agent gets full autonomy inside the walls; only git commits cross back over.
- Behavior is driven by plain **markdown prompt files** plus the Dockerfile. Prompt files support arguments, and a syntax borrowed from Claude skills: prefix a fenced code block with `!` and the command executes at prompt-resolution time, its output injected — the review prompt uses this to run `git diff <source-branch> <branch>` so the reviewer sees the real diff.

### Setting it up

```bash
npm install ai-hero/sandcastle
npx sandcastle init
# choose: agent (Claude Code / Codex), sandbox provider (Docker),
# backlog manager (GitHub issues), and one of the shipped templates
```

Five templates shipped at recording time ("there may be many more by the time you run this"); Pocock's demo picks the maximal one, "parallel planner with a review step."

Init scaffolds a `.castle` directory (a `main.mts` orchestration script, the prompt markdown files, the Dockerfile, an `.env.example`), and — with GitHub issues as backlog — creates a `sandcastle` label: only issues bearing the label get picked up. Build the Docker image, set `ANTHROPIC_API_KEY` and a GitHub token in `.castle/.env`, add a `sandcastle` script to `package.json` that runs `npx tsx .castle/main.mts`, file a labeled issue, and run it. One gotcha: Anthropic is "a little bit funny" about using a Claude *subscription* (rather than an API key) for this kind of automation — check the dedicated GitHub issue in the Sandcastle repo for current advice.

### The factory pipeline: planner → parallel implementers → reviewer → merger

The maximal shipped template ("parallel planner with a review step") composes four roles:

| Stage | What it does |
|---|---|
| Planner | Reads all open `sandcastle`-labeled issues plus labels and comments; determines which are *unblocked* and doable right now; outputs its plan as JSON wrapped in `<plan>` tags, which the orchestrator extracts programmatically |
| Implementers | One sandbox per issue, in parallel, each on its own branch; the prompt is parametrized with issue title and task ID, and the prompt appears to push TDD — the demo shows the agent writing the test first, red-green-refactor style |
| Reviewer | Runs on any branch with more than one commit; prompt injects the real diff, then: understand the change → analyze for improvements → check correctness → maintain balance — plus a fill-in **coding standards section** for your project's rules |
| Merger | Given all branches and their issues, merges them back to main, runs type checks, closes issues with comments |

Two of these roles deserve emphasis. First, implementer/reviewer separation: "the implementer can make mistakes, but the reviewer generally picks it up" — Pocock calls this pattern "incredibly powerful" (it is the same two-role insight as [Chapter 8](08-review-and-qa.md)'s subagent review, applied AFK). Second, the merger: merge conflicts between parallel branches "can sometimes be pretty gnarly", so "we get like a senior merger developer to pull them back into main" — a powerful agent, not a human, resolves them. And because `sandcastle.run` is agent-agnostic, you can go further: adversarial review (Codex reviews Claude Code's work), or best-of-N (multiple different agents implement the same issue; a reviewer picks the best branch or mixes them).

While a run executes, the terminal prints each agent kickoff with clickable log links (bash commands, issue views, plan output, context-window usage at the bottom). You can watch — or "go and have a cup of tea." His verdict: "Just this setup has massively increased my velocity and it works super duper well."

Note the parallelism evolution here, because it matters. Pocock's early attempt at parallel AFK — 16 agents, one per task — was "absolutely hellish": merge conflicts everywhere plus hidden inter-task dependencies. He retreated to the strictly sequential Ralph loop. Sandcastle reintroduces parallelism *safely* by adding the two missing pieces: a planner that only dispatches unblocked issues (so hidden dependencies can't collide), and an agent merger that absorbs the conflict cost. If you can't provide both, run sequentially — the 7-phases video argues that usually a single sequential agent working through each ticket is enough and parallelization is rarely needed.

## Day Shift, Night Shift: The Economics of AFK

The phrase **day shift / night shift** (coined by Pocock's friend Jamon on Twitter) names the division of labor: the human does the thinking work — grilling, PRDs, ticket slicing, QA — and agents do the implementation in the background. In his full feature walkthrough the loop looked like this: grill → PRD → issues → run `pnpm ralph` (Docker, max 100 iterations, tests and types on every commit) → walk away — "walk, tea, or start another grilling session in another terminal."

The numbers from that real run make the economics concrete: the Ralph run took 5 iterations, about 1.5 hours, producing 6 commits with detailed messages. Then QA: a fresh session generated a QA plan from the last five commits (saved as a human-labeled GitHub issue), he walked through it in the running app, and filed **6–7 feedback issues in 8 minutes** via his in-app feedback button (each issue: a Haiku-generated title, the route, his verbatim dictated feedback plus any pasted errors — "this information is enough for Ralph to do a really nice job"). Then the key move: **re-run the loop while you keep QAing**. Bugs get fixed in the background while you find more. Your own QA session and the agent's fix session run in parallel — you are never blocked on the agent, and it is never blocked on you.

This reframes the apparent slowness of the front-loaded workflow: "It's slow because you're trying to extract ideas out of your human brain. And while this is happening, you've got AFK agents running in the background implementing your previous grilling sessions." Pocock even notes that the gaps between loop runs are a feature — they give him time to deep-focus on the next grilling session or a big QA pass.

## Worktrees: Isolation That Makes Parallelism Cheap

Parallel sessions on one machine need isolated checkouts, and git worktrees are the mechanism — full mechanics, the branch-tracks-source gotcha, and the push-before-remove warning are covered in [Chapter 7](07-execution.md); the same discipline applies here, just scaled up to back a fleet of AFK sessions rather than one interactive one. The property that matters for fleets specifically is that **worktree lifecycle = agent lifecycle**: every issue gets an instant isolated workspace, an agent does the work, and the result flows back to main as a PR, orchestrated "from above" by a parent agent — but it appears opt-in; you must ask for it.

Even without the flag, a lighter version of parallelism is just multiple sessions: while triaging his backlog, Pocock runs two Claude sessions at once — one investigating an issue, another on main actually fixing one. His skills repo even has a PRD for worktree *locking* to prevent concurrent agents from touching the same worktree.

## The Many-Agent Pattern: Fleets and Token Throughput

Andrej Karpathy (interviewed on the No Priors podcast) describes the same scaling move from the researcher's side, and it is worth keeping his claims clearly attributed. His personal shift: around December 2025 he went from writing ~80% of his code by hand to essentially zero typed lines — "I don't think I've typed a line of code probably since December"; his job became "expressing my will to my agents for 16 hours a day." His diagnosis is that capability now exceeds most people's ability to harness it, so nearly every failure is a skill issue ("I just didn't give good enough instructions in the agents.md file" is his archetype).

The fleet workflow he describes — crediting Peter Steinberger's setup as the model — looks like this:

1. Keep ~10 repo checkouts (multiple working copies so agents don't collide — the same isolation worktrees give you).
2. Run many concurrent agent sessions (Steinberger tiles his monitor with Codex agents).
3. Prompt each one correctly and use a **high reasoning-effort setting** — with that, each task takes ~20 minutes.
4. Delegate in **macro actions**: whole functionalities, not lines of code. "Here's a new functionality — delegate it to agent one. Here's a new functionality that's not going to interfere with the other one — give it to agent two." Choosing *non-interfering* tasks is the delegation skill.
5. Diversify roles: one agent researching, one writing code, one drafting a plan for a new implementation.
6. Cycle between sessions assigning work and reviewing output "as best as you can, depending on how much you care about that code" — review depth is an explicit, deliberate trade-off.

The resource model underneath: you were bottlenecked by typing speed; now the binding constraint is you. Karpathy treats **token throughput** the way a PhD student treats GPU flops — "I feel nervous when I have subscription left over — that just means I haven't maximized my token throughput." Practically: while any agent is running, queue more parallel work; if you exhaust quota on one provider, switch harnesses and keep going. "The name of the game now is to increase your leverage… you have to remove yourself as the bottleneck."

## Persistent Agents and Auto-Research

Karpathy goes one level further than loops-over-backlogs, and again these are *his* patterns and predictions, reported as such.

**Claws.** A "claw" is a layer above an agent harness that "takes persistence to a whole new level": it keeps looping, has its own sandbox, acts on your behalf when you're not looking, and has a more sophisticated memory system than the default compact-when-context-overflows. He credits Peter Steinberger's **OpenClaw** with innovating several pieces at once: a **SOUL.md** crafted-personality document, the advanced memory system, and a single WhatsApp portal to all your automation. Karpathy's own claw ("Dobby") reverse-engineered and now runs his entire smart home — but note his own caution: he has *not* given it access to his email, calendar, or full digital life, because these tools are "very new and rough around the edges" on security and privacy. The pioneer of the pattern deliberately limits its blast radius.

**Auto-research.** The fully autonomous version of a Ralph loop is an agent loop that improves a system against an objective metric with the human entirely out of the loop. Karpathy's recipe: provide an **objective**, a **metric** (e.g. validation loss), and **boundaries** of what the agent can and cannot do; write a **program.md** — a markdown file describing how the auto-researcher should operate ("do this, then that, try these kinds of ideas — look at architecture, look at the optimizer"); hit go, let it run overnight, and verify candidate improvements against the metric.

The result on his own testbed is the striking part. nanochat is a training harness he has tuned with two decades of experience — "I've trained this model thousands of times." An overnight auto-research run found real improvements he had missed: forgotten weight decay on value embeddings and insufficiently tuned Adam betas, plus the observation that these hyperparameters jointly interact. His conclusion: "I shouldn't be running these hyperparameter search optimizations. I shouldn't be looking at the results. There's objective criteria — you just have to arrange it so it can go forever." He generalizes program.md into a claim about organizations: a research org is "a set of markdown files that describe all the roles and how the whole thing connects" — and once the org is code, you can optimize the code itself (his contest idea: many people write competing program.md files, measure which yields the most improvement, feed the results back to a model to write a better one).

Three caveats, all his:

> **Rule:** Karpathy's verifiability gate — "If you can't evaluate it, you can't auto-research it." Full autonomy only works where there is an objective, cheaply evaluable metric — CUDA kernel optimization (same behavior, faster), training loss, a passing test suite. Expensive-to-find, cheap-to-verify problems are the sweet spot; everything else still needs a human judge.

- **Goodharting**: an autonomous loop over metrics will overfit them; his mitigation is using the system itself to devise more metrics for better coverage.
- **Don't outrun capability**: "the whole thing is still bursting at the seams… if you try to go too far ahead, the whole thing is actually net not useful." Calibrate autonomy to what actually works today.

Poteto's hill-climbing observation is the same loop from the engineering side: once the agent can verify its own work against a rubric or score (the verification skill), it can continually try to improve the result in a loop — the practical form of Karpathy's rubric-based auto-research ([Chapter 3](03-preparing-your-codebase.md) covers building the verification skill itself).

## Connecting the Inner Loop and the Outer Loop

The AFK machinery so far automates the **inner loop**: agents building code toward a snapshot of your intent. Poteto's framing names the other half: the **outer loop** is everything that makes that snapshot stale — Slack, X, email, Linear, bug reports — and traditionally *you* are the proxy shoveling that context to agents. Scaling past one agent means automating the outer loop too:

1. Wire an outer-loop watcher: Poteto's **Grokbot** (his product — a desktop app with connectors to email, calendar, Slack, Linear, X) watches channels and forwards triggers into the inner loop; a Slack MCP or a harness with a Slack subscription does the same job simply.
2. Give the inner-loop agents a standing instruction — the **subscribe-and-triage pattern**: "subscribe to the Slack channel; every time a bug report arrives, triage it — reproduce the issue on main (using your verification skills), check it's not the user's setup, data, or a missing dependency, then fix."
3. The payoff: "when you connect those two loops, it's very very powerful because now all of a sudden your agents have the ability to get context for themselves" — and you are removed from the equation. This is the same "where am I the bottleneck?" question from [Chapter 2](02-principles.md), answered with infrastructure.

Two cautions from the same source. First, **group related issues**: when a burst lands (e.g. 30 performance issues, possibly with a similar fix), have the coordinator group them into one project instead of one agent per task — spawning one agent per bug report loses the thread, duplicates work, and misses the higher-level problem (several slightly different bug reports often reveal the real location of the bug). This is the same lesson as Pocock's "16 parallel agents… absolutely hellish": ungrouped parallelism collides. Second, skepticism about "company brain" / "context graph" abstractions: those terms are "unnecessarily complex or even abstract" — the whole thing is simply teaching the agent to fetch information you'd otherwise have to pass yourself.

## Coordinator Agents: Chiefs of Staff in the Cloud

Above the outer loop sits a delegation layer. Cursor's **projects** feature gives you a coordinator agent in the cloud with its own computer — it does not do the work itself; it delegates, orchestrates, and manages sub-agents (Poteto's metaphor: "executive chef / chief of staff"). Grokbot can message projects directly — you don't even have to open Cursor — and can create a project for a related series of tasks. Coordinator agents can spawn different agent topologies and figure out how to efficiently distribute tasks.

The scale this reaches: Poteto runs "the equivalent of like more than 10 chiefs of staff, each working on a different area" — one on performance of the desktop app, one on user-reported bugs, one even exploring a rewrite in a different language as a toy. The multi-agent lesson for the fleet patterns above: parallelism needs a *manager* — the Sandcastle planner ([Chapter 9](#the-open-source-afk-software-factory)'s factory) is the same role, dispatching only unblocked work and grouping related issues. And a chief-of-staff agent "can see the forest" — pattern-level visibility across sub-agents that any single worker agent lacks (the gardening buffer in [Chapter 8](08-review-and-qa.md) exploits exactly this).

**Full autopilot with fuzzing verifiers.** The most intense form: a per-PR verification loop (a PAC capability) that spawns a bunch of verifier agents per PR — they fuzz the running application, click around, use it like a real human, look for regressions and bugs, fix what they find, and repeat until the PR is in a state where it can land. It is quite token-intensive (verifier count is tunable, ~10 down to 1). Verification plus a constrained environment is exactly the combination that lets agents merge their own PRs unattended — the top rung of the trust ladder.

## The Trust Ladder and the Dark Factory

Poteto's scaling story is a **trust ladder**: as trust in agents grows you delegate more and scale to more agents; low trust forces "lock in and micromanage," which eats all your capacity for higher-level work. Each rung is earned by the machinery in this chapter and [Chapter 3](03-preparing-your-codebase.md) — the verification skill first ("the thing that first let me ascend the trust ladder"), then deterministic CLIs, then constrained environments, then connected loops — until agents self-merge their own PRs while you sleep. His honest caveat: "It's very hard to get to this point. I don't want to sell this as something that you can just do easily by using PAC" — it takes time and effort observing failures and setting guard rails thoughtfully. The first night of agents self-merging was scary ("what if I break something overnight?"); now "I'm sleeping so much better."

He calls the end state a **dark factory** — dark only in the sense that *he* goes to sleep while agents work 24/7: "It's not dark in the sense that — so it's dark in the sense that I go to sleep." This is deliberately NOT Karpathy's vibe-coding dark, where the code barely exists: "If the code in the environment are bad, then you will get bad outputs. Garbage in, garbage out." The code and the environment remain essential; maybe a dimmer switch — some parts dark, some lit. (Contrast the never-trust principle in [Chapter 2](02-principles.md): this is not trust in the agent, it is trust in the environment's verification.)

The domain gate for self-merging is **verifiability** — the same two-way/one-way-door framing: verification makes "one-way doors become two-way doors in a sense," because a verified merge is cheap to check and revert. Software engineering is largely verifiable; mathematics partially, via proofs; for hard-to-verify domains (medical, law, finance) he has no answer and predicts the industry will need agent-oriented programming languages that marry programming with proofs (he points to Bend, which compiles to a proof of correctness, as the hopeful direction; Lean/TLA+ are the old way — construct the proof in a separate language, then use a solver). "If it compiles, right, if the proofs show you that it's correct, then why wouldn't you just merge it?"

## When AFK Works — and When a Human Must Stay in the Loop

Pulling the sources together, AFK execution is safe under specific preconditions, and the human re-enters at specific points:

**AFK works when the thinking is already done.** The 7-phases model ([Chapter 4](04-the-workflow.md)) is explicit: with research cached, a prototype committed, a PRD written, and a kanban board of right-sized tickets, "you can totally run this execution loop AFK and the results will be really good." Once scope is nailed in grilling, "it's pretty much all on Rails… we have done the human in the loop bit."

**AFK works when tasks are verifiable.** Types, tests, and browser automation give the loop its own judge; Karpathy's verifiability gate is the same principle at the limit. No objective feedback loop → no unattended run.

**Humans must stay in the loop for:**

- **QA.** "Then a human, yes, a human… actually walks through and QAs the completed work." QA is where reality bites: his run surfaced a showstopper (a non-git-repo directory leaving database and filesystem out of sync) that never came up in grilling. This is why he says "the specs-to-code approach is just never going to work" — you must iterate execution → QA → new tickets, not fire-and-forget.
- **Post-loop review.** Read the code, test that everything works, adjust the PRD/backlog. In the fleet pattern, review depth is a conscious trade-off per Karpathy — decide how much you care about each piece of code.
- **Hard, steering-heavy features.** Use `ralph-once.sh` interactively rather than the AFK loop.
- **Under-specified tickets.** If nobody has written the brief that earns a `ready for agent` label, the ticket is human work (triage) first.
- **Taste and unverifiable judgment.** Prototyping, UI decisions you "couldn't get a sense for which way to go ... until I saw it in reality", and anything outside an objective metric.

## Provisioning and Secrets: The Wizard Skill

Not every step in the workflow can or should go to an agent. Provisioning infrastructure — logging into AWS, pasting API keys, saving values into GitHub secrets — involves secrets and human-only console actions. Letting an agent do it via computer use "just felt pretty icky"; Pocock wanted control. The **wizard** skill (v1.2) is the alternative: it generates an **interactive bash wizard — a deterministic script, not an agent call** — that walks the human through the steps only they can perform.

How a run works:

1. Kick off the wizard (e.g. for migrating to a remote box or AWS provisioning).
2. It produces a deterministic bash script with a "nice little UI" that opens the exact page or script you need, directs you to log in, change the exact thing, and paste in API keys.
3. It saves values into the files needed — and even into GitHub secrets where required — walking through separate stages until done.
4. Advance each stage with a natural phrase: "Ready to start? Yes, please."

The load-bearing property is determinism: **nothing is sent to an LLM**. Because the wizard is a script, not an agent call, API keys and secrets stay local — no Anthropic round-trip, no third party. The human keeps control over the whole flow while the wizard makes it "as easy as possible." Pocock's verdict on the impact: "this takes provisioning services from incredibly painful to weirdly joyful."

> **Why it works:** Deterministic scripts are the right tool for sensitive human steps the way hooks are the right tool for deterministic CLI rules ([Chapter 3](03-preparing-your-codebase.md)). When a step needs secrets or human judgment at a console, a bash wizard gives you control + ease without putting secrets in an agent's context window — the same logic that rejects YOLO mode for AFK execution applies one level down, to the provisioning step inside the flow.

This is the human-in-the-loop counterpart to the AFK machinery: the wizard handles the steps a loop cannot, deterministically, so the boundary between "agent does this" and "human does this" is explicit and safe rather than blurred by computer use.

## The Guardrails That Make AFK Safe

Every successful AFK setup in the sources rests on the same short list. Skip any one of them and the failure mode is predictable.

1. **Tests and types on every commit; CI stays green.** Pocock calls this the crucial success factor of his loop, and the rule is absolute: "Whenever your Ralph loop commits, CI has to stay green." His investment priorities: "You want more tests. You want higher quality tests. You want non-flaky tests… and most of all, you want types, types, types, types, types." Flaky tests and weak typing silently disable the only judge the loop has. (Building these loops is [Chapter 3](03-preparing-your-codebase.md)'s job.)
2. **Force end-to-end verification.** Per the Anthropic article he cites, Claude tends to mark features complete without proper testing, but "did much better at verifying features end to end once explicitly prompted to use browser automation tools and do all testing as a human user would" — so wire up the Playwright MCP server. It is context-expensive, which is yet another reason tasks must be small enough to leave budget for verification.
3. **Review in the loop.** A reviewer agent on every multi-commit branch (with your coding standards in the prompt), plus human review after the run. The implementer will make mistakes; the question is only whether something catches them.
4. **Sandbox, never YOLO.** Docker container, working dir mounted in, commits patched out. Bypassed permissions with no walls is how home directories get deleted and code gets exfiltrated.
5. **Small, uniform tickets.** One context window each, with explicit verification steps — small enough not to bloat context, big enough to justify the startup cost of spinning up an agent (Pocock merges trivial issues into neighbors). A Ralph loop that commits bad code loses its memory of *why*; small tasks plus green CI on every commit keep any single bad iteration cheap and findable.
6. **A bounded loop with a completion signal.** Max iterations as the backstop, a sentinel string for early exit, and a notification (his `notify` WhatsApp CLI) so completion doesn't go unnoticed.
7. **Explicit pickup rules.** Label-gated backlogs (`ready for agent`, human-in-the-loop labels, the `sandcastle` label) so agents never touch tickets that aren't theirs.
8. **Push protection.** Branch protection on main, named-branch pushes from worktrees, and a hook that blocks agent-initiated pushes for manual confirmation.

## Checklist

- [ ] Build a Ralph loop: bounded for-loop, fresh agent context per iteration, one small ticket per iteration, git commit per iteration.
- [ ] Give the loop a backlog it can mark done (prd.json with `passes` flags, or labeled GitHub issues) and an append-only `progress.txt` memory file; delete the memory file after the sprint.
- [ ] Encode the earned prompt rules: highest priority (agent's judgment), single feature only, append not update, commit each feature, output a sentinel (`PROMISE_COMPLETE`) when the backlog is done.
- [ ] Require a max-iterations argument and a completion notification.
- [ ] Enforce tests + typecheck on every commit; CI stays green; explicitly prompt browser-automation verification "as a human user would."
- [ ] Run AFK agents sandboxed (Docker; working dir mounted, commits patched out) — never YOLO mode; using a Claude subscription (rather than an API key) for this kind of automation is discouraged by Anthropic — check the Sandcastle repo's GitHub issue for current guidance before choosing.
- [ ] If parallelizing implementers, add the two safety pieces: a planner that dispatches only unblocked tickets, and a powerful merger agent for conflicts. Otherwise run sequentially.
- [ ] Gate the backlog: `ready for agent` only after a written brief; human-in-the-loop labels the loop must skip.
- [ ] Use a worktree per agent session (`claude --worktree`); push to an explicitly named branch, protect main, push before removing the worktree.
- [ ] Learn the loop with `ralph-once.sh` before trusting it overnight; keep steering-heavy features interactive.
- [ ] Run the day shift / night shift split: grill and QA while the loop implements your previous session; file QA findings as issues and re-run the loop in parallel.
- [ ] When waiting on one agent, delegate more non-interfering macro tasks to others (high effort setting, ~20-minute granularity); treat idle token capacity as the bottleneck being you.
- [ ] Only fully automate what you can evaluate: objective + metric + boundaries (+ a program.md for research-style loops); watch for Goodharting; keep humans on QA, review, and taste.
- [ ] Connect the loops: wire an outer-loop watcher (Slack MCP, Grokbot-style) and give agents a subscribe-and-triage instruction so they gather their own context — you stop being the proxy.
- [ ] Group bursts of related issues into one project — never one agent per bug report; parallelism needs a coordinator that sees the forest.
- [ ] Climb the trust ladder deliberately: verification skill → deterministic CLIs → constrained environment → connected loops → self-merging PRs with post-land review; expect it to take time, not a tool install.
- [ ] "Dark" means you sleep while agents work — the code and the environment stay essential (garbage in, garbage out); never Karpathy-dark where the code barely exists.
- [ ] For provisioning and secret-handling steps, use a deterministic wizard script (not computer use) so secrets stay local and the human keeps control.

## Sources

- Ship working code while you sleep with the Ralph Wiggum technique
- I Open-Sourced My Own AFK Software Factory
- New Skills! v1.2 brings /wait-what, /writing-for-agents, and fixes /grill-me
- Building a REAL feature with Claude Code: every step explained
- Andrej Karpathy on No Priors: Agentic Coding, Claws, Auto-Research & the Post-December Workflow Shift
- I'm using claude --worktree for everything now
- The 7 phases of AI-driven development
- Burn through the backlog from hell with /triage
- LIVE: Poteto (creator of pstack) on shipping 1,000's of PR's a month at SpaceX

See also: [Chapter 3](03-preparing-your-codebase.md) for building the feedback loops AFK depends on, [Chapter 4](04-the-workflow.md) for where AFK execution sits in the 7 phases, [Chapter 6](06-tickets-and-planning.md) for ticket slicing and the triage state machine that feeds these loops, [Chapter 7](07-execution.md) for interactive execution sessions, and [Chapter 8](08-review-and-qa.md) for the review and QA gates that close the loop.
