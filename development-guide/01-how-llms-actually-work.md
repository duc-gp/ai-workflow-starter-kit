# 1. How LLMs Actually Work: Tokens, Context Windows, Agents

Every rule in this guide — clear between tickets, size a ticket to one session, review with subagents, keep CLAUDE.md short — is a consequence of a small set of mechanical facts about how LLMs process text. This chapter explains those facts: what a token is, why a model's working memory degrades as it fills, what an agent actually is under the hood, and how to curate what the model sees. Get this mental model right and the rest of the guide stops being a list of rituals and becomes obvious engineering.

## Tokens: The Currency of LLMs

At an AI workshop Matt Pocock ran in Poland, only about a third of professional developers knew what a token was. He considers that a fundamental gap, and it is worth closing first because everything else builds on it.

**Tokens** are the units an LLM actually computes on. "Tokens are the currency of LLMs": you are billed by the token, and all of the model's processing happens on numeric token IDs, not on text. The full pipeline:

1. Your text is split into the largest chunks that exist in the model's **vocabulary** (a mapping from text chunks to numbers).
2. Each chunk is looked up as a number — this is **encoding**.
3. The LLM does its thinking on those numbers and produces output tokens.
4. The output numbers are looked up in the vocabulary and joined back into text — **decoding**.

> "While you think that the LLM is dealing with text, it's actually dealing with these numeric representations of chunks of text." — Matt Pocock

Three practical consequences follow.

**Token counts differ across providers.** Every model has its own vocabulary, so identical text encodes to different token counts. Pocock demonstrated this with the Vercel AI SDK: the prompt "Hello world" cost 11 input tokens on Anthropic's Claude 3.5 Haiku but only 4 on Google's Gemini 2.0 Flash Lite. Cost comparisons between providers must account for this, and input and output tokens are billed at different per-1K rates, so an API call's cost is `(input tokens × input rate) + (output tokens × output rate)`.

**Frequency drives efficiency.** Tokenizers are trained on (usually) the same corpus as the model. Common sequences become single tokens; rare ones fragment. With OpenAI's `o200k_base` encoding (GPT-4o's tokenizer, usable from TypeScript via `js-tiktoken`), ~2,300 characters of ordinary prose becomes fewer than 500 tokens — but the rare made-up word "frabjous" splits into 4 tokens on its own. Vocabulary size is a trade-off: at a ~1K-token vocabulary, "understanding" might be 5 tokens (und/er/st/and/ing); at ~50K, 3 tokens; at ~200K, 2. Fewer tokens means less work per request, but vocabularies cannot scale to infinity — a bigger vocabulary means a bigger model and more memory.

**Language choice has token costs.** Under-represented spoken languages tokenize inefficiently, and the same is true of code: "It's fewer tokens to send 20 lines of JavaScript than it is to send 20 lines of Haskell" — in Pocock's words, "yet another advantage that more commonly used coding languages have in the AI era." Your stack choice affects how much of the model's working memory your code consumes. That feeds directly into [Chapter 3](03-preparing-your-codebase.md)'s theme that the environment determines quality.

The load-bearing takeaway: "The more tokens we have in the input, the more work it's going to be for our LLM to process them." Tokens are a budget. Everything below is about spending it well.

## The Context Window: Finite, and Worse Than Finite

The **context window** is all input and output tokens the LLM sees at any one time: the system prompt, every user message, every assistant message, and every tool result. Everything counts. Long conversations grow the window until you hit the provider's hard-coded limit — Claude Sonnet 4.5's is 200k tokens — and you can hit it multiple ways: accumulated messages, one enormous message (an uploaded document, a transcribed video), or even mid-generation, where the model overruns its window while producing output and simply stops.

Pocock is blunt about why this matters:

> "If there is a skill issue that I see most often with devs, it is not thinking enough about the context window. The context window is the main constraint that most AI coding agents face these days."

Limits exist for two reasons. First, architecture: LLM processing is expensive, and more context means more memory per process. Second — and this is the part most developers miss — **performance degrades before you hit the limit**. "The more information that you give a model, the worse it's going to perform," true from tiny models up to very large ones.

The degradation has a shape. The attention mechanism prioritizes the start and the end of the context; information in the middle gets deprioritized. This is the **lost-in-the-middle** problem (also tested as "needle in a haystack": can the model retrieve one fact from a bloated context?). It is an emergent property of attention, not intended behavior — the machine equivalent of primacy and recency bias in humans, who also remember the start and end of a talk better than "the guff in the middle."

> **Rule:** Judge a model by how well it retrieves from its context window, not by how big the window is. "Bigger is not always better."

The cautionary tale: Meta's Llama 4 Scout advertised a 10-million-token context window, but real users found such severe lost-in-the-middle problems that you could feed it that information "but it wouldn't really do anything with it." Use models.dev to look up context limits, then check retrieval behavior reported by real users before caring about the number.

The operating principle that falls out of all this: **"Models just do better with less, more focused information, just like humans do."**

## The Smart Zone and the Dumb Zone: Budget the Usable Window

Pocock refines the degradation curve into a working model:

> "Practically, you can think of the agent as having a smart zone and a dumb zone."

The **smart zone** is the usable portion of the context window before attention degradation — roughly 140k tokens on the 200k-token Claude models he works in ("I think of my context window as kind of like ending or getting significantly dumber at around the 140k mark"). Past it lies the **dumb zone**: not a cliff but a slow decline — "it slowly sinks down" — where the model "ends up getting stupider, does weird hallucinations," retrieves worse, and writes worse code. So the real budget for a session is not the advertised limit; it is the smart zone, minus whatever is already spent.

The mechanism underneath is quadratic attention: every added token must be tracked in relation to every other token — 5 tokens is ~10 attention relationships; 10,000 tokens is ~1,000,000. That scaling is why "many models now ship with 1 million tokens of context window, but it's pretty shocking how little of that is usable for actual work" — advertised windows and usable windows are different things.

A working rule of thumb for where the dumb zone begins: **~150,000 tokens** — but treat it as per-model, per-task, and moving. Pocock's own recommendation moved from ~100k six months earlier to ~150k now, "and it will continue to creep up" as models improve. Re-derive the threshold periodically rather than treating it as fixed.

The dumb zone has a detector: **faithfulness hallucinations**. "If you're seeing hallucinations, especially faithfulness hallucinations, then you're probably in the dumb zone." Treat that as the signal to clear, compact, hand off — or redesign the task so it doesn't need that much context at all. Some tasks genuinely don't need much of the smart zone and can be run in the dumb zone; but to get the most out of the tokens you spend, spend them in the smart zone.

This one model generates most of the guide's session mechanics:

- **One ticket = one smart zone.** When a spec is sliced into tickets ([Chapter 6](06-tickets-and-planning.md)), each ticket is sized so its implementation fits inside a single context window's smart zone. "Each one of these tickets is supposed to just be the size of a single context window or a single smart zone."
- **Clear between tickets.** Don't say "do every single ticket." Implement one, check where you are; maybe squeeze in one more if there is room, but usually clear between every ticket ([Chapter 7](07-execution.md)). Stacking tickets pushes the session past the smart zone and quality drops.
- **The implement-now vs. spec fork.** After a planning conversation, estimate the remaining budget. Pocock's example: "we've got 100k of budget here to remove 10 commands — super easy" → implement in the same session. If the work needs multiple sessions, externalize state into a spec and tickets first, because the smart zone is finite and the next session starts from zero.
- **Plan across sessions when the planning itself blows the zone — Wayfinder.** The smart zone caps *planning*, not just implementation. As Pocock frames the dedicated Wayfinder explainer: "Some work is bigger than what you can fit into the context window — and especially the smart zone of the context window of the agent. And you know that going in." Attempting to single-session-path genuinely foggy big work means spending the whole session managing the smart zone and grilling, only to "get lost in fog mid-grilling." When planning an idea would itself overrun the zone, split the planning across sessions and externalize the open decisions into a shared map ([Chapter 5](05-idea-to-spec.md)); each deciding ticket is sized to one session and its resolution accrues back into the map, so nothing is lost.

Budgeting requires visibility. In Claude Code:

- **`/context`** shows tokens used vs. the limit, broken down by category. In Pocock's demo: 95k used of 200k, with ~8% of the limit consumed by the system prompt alone and ~40% (77k tokens) by conversation messages. His thresholds: at ~105k free he continues comfortably; once only ~50k remains he "would definitely start getting scared" and clears. "You really do need full transparency, full understanding of what's happening in your context window at any time."
- **`/clear`** wipes the conversation and starts from a blank slate. This is the default reset: "regularly clearing your coding agent chats will refresh the agent's memory and clear its context window making for much better performance."
- **`/compact`** replaces the history with an LLM-generated summary — "like a sort of mini rules file just for this conversation." In his demo it took about a minute, cost tokens (an LLM writes the summary), dropped the files that had been pulled in, but preserved intent: messages went from ~70k tokens to ~4k, leaving 90% free. "Compacting is useful when you want to preserve the vibes of a conversation. But clear should be your default."

Two standing sources of context bloat deserve permanent suspicion:

> **Warning:** MCP servers load their tool definitions into every conversation's context and "can bloat your context incredibly rapidly" — Pocock has seen sessions where the system prompt plus MCP tools from a couple of servers dwarfed the actual messages. Be extremely cautious about adding them. The same logic applies to large always-loaded rules files (CLAUDE.md, Cursor rules): keep them small, or every session starts pre-bloated. Pocock credits this "paranoia" for the performance he gets out of coding agents.

Contrast that with well-designed skills: his entire 38-skill repo consumes only ~660 tokens of context, because the skills are user-invoked with short, precise descriptions rather than auto-loading long ones that "leech their way" into context. That design principle returns in [Chapter 10](10-building-skills.md).

## What an Agent Actually Is

Strip away the marketing and an agent is a small, unremarkable loop. Pocock argues for the definition from Anthropic's December 2024 article "Building Effective Agents":

> "An agent is a loop where the LLM decides when to stop."

Concretely, for a request like "write a new file called .gitignore":

1. The user's request goes to the LLM.
2. The LLM responds not with prose but with a **tool call**: "call the `write_file` tool with this content and this path."
3. The **harness** (Claude Code, Cursor, Codex CLI — the product wrapping the model) executes the tool on the real machine.
4. The tool's result is sent back to the LLM as a new message.
5. The LLM either issues another tool call (loop continues) or emits a special stop token, which the harness catches to cease calling the model.

That loop "is what drives things like Claude Code, coding agents, all the stuff that you're kind of used to using." There is nothing else in the box. Two details matter:

**The loop only works because tool results inject new information.** Calling an LLM repeatedly with the same input "is not going to do anything useful." Each iteration, the model learns something it didn't know — a file's contents, a test failure, a grep result — and adjusts. This is also why the feedback loops of [Chapter 3](03-preparing-your-codebase.md) are so decisive: the quality of what flows back through the loop is the quality of the agent's learning.

**A workflow is the opposite design.** A **workflow** is a set of predetermined code paths with LLM calls chained deterministically — the steps are known ahead of time and written in code, possibly with branching. (A single LLM call is neither: "it's just a freaking API call.") The key differentiator is who decides when to stop: agent → the LLM; workflow → the code. Pocock's analogy: "Agent is like jazz — it's all improvisation, all feel. And workflows are like classical music, where you can spend ages optimizing the upfront setup." Use an agent when the path to the solution is unclear or the system must generalize (a coding agent never knows what codebase or bug it will face); use a workflow when the path is known or the task repeats a thousand times, because known paths can be optimized — for example, splitting a text in two, summarizing both halves in parallel, then summarizing the summaries.

In practice it is a spectrum, not a binary. A pure agent where only the LLM decides when to stop "is going to eventually run forever," so every deployed agent carries a deterministic safety stop — a max-steps counter, common enough that frameworks expose it as a parameter. Agents contain workflows (optimized tools inside a generalizing loop) and workflows contain loops (the test: can the LLM break the loop early? Then it's an agent). This spectrum is exactly where the Ralph loop of [Chapter 9](09-afk-and-parallel-agents.md) lives: an agent loop over a backlog, bounded by a deterministic max-iterations cap (100 in Pocock's setup).

The definitions get muddied in the market precisely because vendors sell workflow builders as agent builders. Pocock's example: OpenAI's Agent Kit demo chains a jailbreak guardrail into a router that sends the input to one of three separate "agents" — a set of deterministic, directional steps decided by code, not by the LLM. By his own definition that is a workflow builder wearing agent branding, not an agent builder. He also notes the irony that Anthropic's own "Building Effective Agents" article, despite its title, mostly walks through variations of workflows. The label on the tin matters less than the question you actually need answered before building anything: who decides when this loop stops — the model, or your code?

## Subagents: Isolation as a Token Strategy

A **subagent** is an agent loop spawned by another agent, with its own fresh context window. It explores, works, and then hands back only a short digest to the coordinator. This single mechanism buys you two different things.

**Token efficiency.** Pocock's explore pattern in Claude Code sends a subagent to read "tons and tons of files" in its own context and return only a summary. The parent's context stays lean — after a long grilling session that involved heavy codebase exploration, his main context sat at only ~40k tokens. The expensive reading happened in a disposable window; only the signal came home. (His one complaint: "I do wish that explore was faster. You need it in every single session, sometimes multiple times a session.")

**Fresh eyes.** An agent reviewing code it just wrote has the entire writing session in context, including its own reasoning for why the code is fine:

> "Agents are often really bad at editing code or improving code they've just written because they wrote it. So they just think, 'Okay, that's fantastic. That's fine.'" — Matt Pocock

Spawning a review subagent gives the reviewer a clean context window containing the code and the standards — not the author's self-justifications. This is the mechanical reason the two-axis review in [Chapter 8](08-review-and-qa.md) runs in subagents, always.

A related micro-optimization from the same physics: not calling a tool is always cheaper than calling one, because every tool call gets wrapped in JSON. Pocock's grilling skill deliberately avoids Claude's built-in ask-user-question tool partly for this reason. Small tax, paid on every turn — it compounds.

## Context Engineering: Curate, Don't Dump

Most people try to fix bad AI answers by writing bigger prompts. That is the wrong move. **Context engineering** is "the craft of deciding exactly what the model should see and what it shouldn't, at each step" — the industry-wide shift from crafting perfect prompts to curating "the smallest set of high-signal tokens." Prompt engineering (how you word the ask) still matters; context engineering subsumes it at runtime, and it is dynamic: context is assembled before every model call. The governing image: the model is a brain with a limited short-term memory, and your job is to pack it with exactly what it needs for the next step. Context is scarce working memory, not a dumping ground.

### The 7-piece context stack

What a model sees at runtime decomposes into seven pieces. Know them so you can curate each one:

1. **Instructions** — system prompt and guardrails; "clear and plain language wins here."
2. **User input** — the current ask.
3. **Retrieved facts** — "the few snippets that matter the most," not everything.
4. **Tools** — the functions the model can call; their descriptions are context too (which is exactly why MCP servers bloat sessions). Harness-shipped tools count as well: Pocock cut his Claude Code starting system prompt from ~25k tokens to ~8k by disabling unused built-in tools and features in `settings.json` (see [Chapter 3](03-preparing-your-codebase.md)).
5. **Short-term notes** — summaries of recent steps, so the model remembers what just changed.
6. **Long-term memory** — stable facts about the user or project, "selected on demand."
7. **Output format** — schemas or examples that "lock the shape of the answer."

A worked contrast from the source video: an agent ("LogLook") that triages Azure security alerts. The chatbot way — "analyze today's logs and tell me what's wrong" dumped on the model — tends to produce random guesses. The context-engineered way gives it a clean plate: a system instruction ("Summarize incidents into one paragraph plus a severity score between 0 and 4. Only use provided context, and if missing data exists, ask for a specific file path"), only the tools it needs (read file, grep, a false-positives lookup), only today's ERROR/CRITICAL log lines from the last hour, a short-term note ("We've already checked this file. Next scan this log instead"), and JSON locked as the output format. "Same model, but with way better context."

### The four failure modes

When an agent goes wrong, the cause is usually one of four named context failures — and these show up most in agents, where conversation plus tool output snowballs:

| Failure mode | What happens |
|---|---|
| **Poisoning** | A hallucinated fact gets into context and is reused over and over |
| **Distraction** | The model fixates on a huge history instead of making a fresh plan |
| **Confusion** | Extra unrelated details nudge it into the wrong answer |
| **Clash** | Two sources in context disagree and the model picks the wrong one |

Knowing the names helps you fix what is wrong — a session that keeps repeating a false claim about your codebase is poisoned, and per the isolate step below, is best contained by giving the coordinator a fresh, sandboxed context rather than arguing it out of a poisoned one.

### The four-step framework: Write, Select, Compress, Isolate

The fix side is a four-step framework that "shows up across the best agent systems":

1. **Write** — save notes *outside* the context window. Give the agent an external scratchpad for plans, intermediate results, and open questions; pull from it only when relevant. This is the mechanism behind specs, tickets, and handoff documents ([Chapter 7](07-execution.md)): durable state that survives a `/clear`.
2. **Select** — pull only what matters *right now*. Retrieval should fetch the specific slices needed for this turn (hybrid keyword + semantic retrieval "often beats embedding-only search on messy logs"). "The point is selection and not hoarding."
3. **Compress** — keep the signal, drop the rest. Periodically summarize long histories into short, loss-aware notes and continue with a fresh window — keep the last few items raw for safety (the example: last 5 findings raw, everything older rolled into a 3-line recap). This is `/compact`, and it "beats dragging a huge chat history everywhere." Without compress, huge history causes distraction.
4. **Isolate** — sandbox sources to avoid crosstalk. Split big jobs into subagents or phases, each exploring its own context and returning a short digest to a coordinator (reader extracts facts → scorer applies policy → writer composes from their digests). Without isolate, one noisy source poisons the rest.

> **Why it works:** Every step exists because attention degrades and context is finite. Write moves state out of the scarce window; Select keeps low-signal tokens from ever entering it; Compress reclaims the window mid-flight; Isolate keeps noise from contaminating the coordinator. Pocock's entire main flow — grill, then compress a 46.1k-token discussion into a spec via `/to-spec`, slice into smart-zone tickets via `/to-tickets`, clear, implement fresh — is Write + Compress + Isolate applied to feature development.

"If you remember one thing from all of this, it's really important to curate, instead of dumping a large chunk of prompts."

## Attention Hotspots: Why Q&A Colocation Works

One more attention-mechanism property earns its own section because a whole phase of the workflow rests on it. Pocock on why he structures idea-hardening as an interview (**grilling** — the agent asks you questions) rather than as a monologue:

> "I freaking love question and answer because it collocates the question with the answer... it shows up as a hot spot for the LLM in terms of its attention mechanism."

A question sitting directly next to its answer forms a dense, high-signal pair — for the model's attention and, incidentally, for humans reading the transcript. That is why a grilling transcript is "incredibly good fodder" for a spec: when the agent later compresses the conversation into a PRD, the material is already organized as decision points with resolutions, not as a wall of undifferentiated prose. It is also why generated specs and tickets don't need line-by-line human review — "LLMs are really, really good at summarizing things," and you effectively pre-reviewed the content by having the conversation. The full grilling practice lives in [Chapter 5](05-idea-to-spec.md).

## Jaggedness: Code-Smart Does Not Generalize

The last piece of the mental model is about capability shape, from Andrej Karpathy. Interacting with a frontier model, he says:

> "I simultaneously feel like I'm talking to an extremely brilliant PhD student who's been a systems programmer for their entire life — and a 10-year-old."

This is **jaggedness**: humans are tightly coupled across abilities (someone brilliant at systems programming is rarely a 10-year-old at everything else), but models are not. And the jaggedness has a cause you can reason from: the **RL training boundary**. Models improve through reinforcement learning only in **verifiable domains** — where success can be checked objectively, like "does the program pass the unit tests?" Inside that RL-optimized territory you travel "at the speed of light"; outside it — nuance, intent, knowing when to ask a clarifying question, humor — "everything meanders." Karpathy's evidence for the outside: ChatGPT still tells the same "scientists don't trust atoms" joke it told four years ago, because jokes were never optimized. Code-smartness has not satisfyingly generalized to everything else, and you should not expect it to.

Practical implications:

- **Play to the on-rails region.** Agents are strongest exactly where verification is cheap: code that compiles, tests that pass, metrics that move. This is why making your repo verifiable — tests, typechecks, build feedback — is the highest-return preparation work ([Chapter 3](03-preparing-your-codebase.md)), and why Pocock's Ralph loop runs tests and types on every single commit ([Chapter 9](09-afk-and-parallel-agents.md)).
- **The verifiability gate governs autonomy.** Karpathy's rule for autonomous improvement loops: "If you can't evaluate it, you can't auto-research it." The sweet spot is expensive-to-find, cheap-to-verify work (kernel optimization, training-loss reduction). Give an autonomous loop an objective, a metric, and boundaries — and beware Goodharting: a loop over metrics will overfit them, so expand metric coverage over time.
- **You cover the off-rails region.** The model's weak spots — intent, nuance, judging what actually matters — are precisely the human's job in this workflow: the grilling answers, the why behind a feature, the QA judgment call. "The things that agents can't do is your job now. The things that agents can do, they can probably do better than you, or very soon. Be strategic about what you're actually spending time on."
- **Failures are usually instructions, not capability.** Karpathy's post-December claim: capability now exceeds most people's ability to harness it, so "everything is skill issue" — his archetype being "I just didn't give good enough instructions in the agents.md file." When an agent fails, audit your context and instructions before blaming the model. That attitude is developed into a full operating principle in [Chapter 2](02-principles.md).

- **Don't run ahead of capability.** The stack is "still bursting at the seams"; fully autonomous everything is "net not useful" today. Calibrate autonomy to what verifiably works.

## The Physics Cheat Sheet

Every later rule in this guide traces back to a mechanism in this chapter. Keep the mapping handy:

| Later rule | Mechanism here |
|---|---|
| Size tickets to one session ([Ch. 6](06-tickets-and-planning.md)) | Smart zone ends ~140k tokens; degradation past it |
| Clear between tickets ([Ch. 7](07-execution.md)) | Lost-in-the-middle; "models do better with less, more focused information" |
| Specs and tickets as durable artifacts ([Ch. 5](05-idea-to-spec.md), [Ch. 6](06-tickets-and-planning.md)) | Write + Compress: state must survive outside the scarce window |
| Handoff before switching work ([Ch. 7](07-execution.md)) | Compress: loss-aware summary beats dragging history |
| Review in subagents ([Ch. 8](08-review-and-qa.md)) | Isolate: fresh context has no author bias; digests keep the coordinator lean |
| Keep CLAUDE.md short, be stingy with MCP ([Ch. 3](03-preparing-your-codebase.md)) | Tool definitions and rules files are always-loaded context tax |
| Tests + types on every commit in AFK loops ([Ch. 9](09-afk-and-parallel-agents.md)) | RL boundary: agents excel where verification is cheap and objective |
| Grill before building ([Ch. 5](05-idea-to-spec.md)) | Q&A colocation creates attention hotspots; new information drives the loop |
| Split planning across sessions (/wayfinder, [Ch. 5](05-idea-to-spec.md), [Ch. 6](06-tickets-and-planning.md)) | The smart zone caps the *planning* phase too, not only execution — "you can't make your way cleanly to the destination" when fog sits between you and it |
| Max iterations on every loop ([Ch. 9](09-afk-and-parallel-agents.md)) | A pure agent "will eventually run forever" |

## Checklist

- [ ] You can explain what a token is and why the same prompt costs 11 tokens on one provider and 4 on another.
- [ ] You know your model's context limit *and* its smart zone (~140–150k on 200k-token Claude models) — and you budget against the smart zone, not the limit.
- [ ] You treat faithfulness hallucinations as the dumb-zone detector: when they appear, you clear, compact, hand off, or redesign the task instead of pushing on.
- [ ] You run `/context` habitually and know what fraction of your window is system prompt, tools, and messages.
- [ ] You clear by default and compact only when you need to preserve the session's intent; you have a personal "get scared" threshold (Pocock's: ~50k tokens remaining).
- [ ] You audit MCP servers and rules files for context tax before adding them.
- [ ] You can define an agent in one sentence — an LLM calling tools in a loop, where the LLM decides when to stop — and say whether a given system is an agent, a workflow, or a hybrid.
- [ ] You never deploy an agent loop without a deterministic stop (max-steps).
- [ ] You use subagents for exploration and review: heavy reading in a disposable window, digest back to the coordinator, fresh eyes on written code.
- [ ] You can name the four context failure modes (poisoning, distraction, confusion, clash) and apply Write / Select / Compress / Isolate as the fix kit.
- [ ] You direct agents at verifiable work (tests, types, metrics) and keep the unverifiable judgment — intent, nuance, priorities — for yourself.

## Sources

- Most devs don't understand how LLM tokens work
- Most devs don't understand how context windows work
- What is the dumb zone?
- Most devs don't understand what agents are
- Context Engineering Explained: Stop Padding Prompts, Curate What the Model Sees
- mattpocock/skills: A complete AI Coding workflow, end-to-end
- Building a REAL feature with Claude Code: every step explained
- Andrej Karpathy on No Priors: Agentic Coding, Claws, Auto-Research & the Post-December Workflow Shift
- /wayfinder: Nothing is too big to plan anymore

See also: [Chapter 2 — Operating Principles](02-principles.md) · [Chapter 3 — Preparing Your Codebase](03-preparing-your-codebase.md) · [Chapter 6 — Tickets and Planning](06-tickets-and-planning.md) · [Chapter 7 — Execution](07-execution.md) · [Chapter 8 — Review, QA, and De-Slopping](08-review-and-qa.md) · [Chapter 9 — AFK and Parallel Agents](09-afk-and-parallel-agents.md)
