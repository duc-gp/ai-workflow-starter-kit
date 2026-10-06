# 2. Operating Principles: Trust, Verification, Responsibility

This chapter establishes the professional attitudes that separate engineering-with-AI from vibe coding: never trust an LLM's output, verify everything through feedback loops, delegate like a lead rather than supervise like a babysitter, and keep ownership of the *why* while handing over the *how*. Everything in the rest of this guide — the workflow, the skills, the AFK loops — is built on these principles; adopt the techniques without the attitudes and you get slop at higher speed. The principles here come from three distinct voices: Matt Pocock (the skills-workflow author whose system most of this guide documents), Bassam Daidi (a senior engineer at GitHub working on GitHub Actions), and Andrej Karpathy — and where they speak from personal conviction, this chapter says so.

## Never Trust an LLM

The foundational discipline is paranoia. Matt Pocock, after roughly a year and a half of working with LLMs, puts it bluntly:

> "I am now paranoid about everything an LLM says to me. And I will never ever trust an LLM."

He observes that nearly every experienced software developer arrives at this intuition after about six months of working with LLMs — while many otherwise-smart non-developers never do. This is not cynicism about the tools (he describes himself as "really pro-LLM"; they massively improved his job and quality of life). It is an accurate model of how they fail.

### Why they hallucinate: the mechanics behind the paranoia

Chapter 1 covers [how LLMs work in detail](01-how-llms-actually-work.md); the two facts that matter for this chapter are these:

1. **Training is lossy compression.** An LLM's "memory" is a massive training set compressed down to fit on a GPU. Pocock's analogy: progressively JPEG-compress a photo of a face — first the wrinkles go, then the skin detail, until it's "just a blobby, crappy, hypercompressed version of the information that was once there." Ask about anything thinly represented in training and the model is answering from the blob. It can get coarse facts right and fine facts confidently wrong.
2. **Guessing is rewarded over refusal.** Per the OpenAI paper "Why Language Models Hallucinate": "Like students facing hard exam questions, LLMs guess when uncertain… training and evaluation procedures reward guessing over acknowledging uncertainty." A model tuned to say "I don't know" scores worse on the benchmarks (LiveBench and its kin) that drive adoption — and switching models is trivially easy, so topping leaderboards is worth a lot. As Pocock summarizes: "You miss all of the shots that you don't take. And so LLMs try to take as many shots as possible."

There's a human analogy Pocock draws for why this is so hard to train away: think of two kinds of exam-takers. Very smart people trust themselves and work out an answer with confidence even when they're not sure — which is exactly the overconfidence that produces hallucination. Humble people say "I don't know" when they're uncertain, but that same humility makes them reluctant to reason deeply even when they could. Model trainers are picking a point on that same line, and Pocock is upfront that he doesn't think it's a solved problem — tuning a model to be humble enough to refuse also risks tuning out the confidence that makes it useful.

The failure modes are structurally predictable, not random. The taxonomy paper he cites ("A Comprehensive Taxonomy of Hallucinations in Large Language Models") lists around ten categories; the three that matter most for engineers:

- **Factual errors** — Google Bard's wrong JWST claim appeared *in the launch advert itself*; Alphabet's share price dropped roughly 8%.
- **Fabricated entities** — invented packages, laws, government departments. Pocock reports LLMs recommending nonexistent packages has "personally happened to me dozens of times," and attackers exploit exactly this for supply-chain malware.
- **Contextual inconsistency** — contradicting information you explicitly provided. Air Canada was found liable in 2024 after its chatbot invented a bereavement-refund policy that contradicted the airline's actual policy text.

That third category is the one that should reshape your workflow: even feeding the model the right context does not make its output trustworthy. It makes it *much better* — and still in need of verification.

### The discipline: intrinsic over extrinsic, then verify anyway

The taxonomy distinguishes **intrinsic information** (provided in the current conversation — code, documents, search results) from **extrinsic information** (the model's compressed training-set memory). LLMs are dramatically more reliable on intrinsic information. Three working rules follow:

> **Rule:** Always supply the information the model needs to succeed. Feed it the codebase, the docs, the search results — never rely on its training-set memory for anything that matters.

- **For factual questions, force retrieval.** Pocock's four-word prompt:

  ```text
  Use your search tool.
  ```

  Many tools will not search by default — if the model is confident it "knows" the answer, it won't invoke the tool; using a tool requires the model to be humble enough to admit it needs to fetch. Explicit instruction forces grounding, with citations you can check.
- **For code questions, load the code first.** Pass the codebase or the relevant files (or let the agent explore), then ask. It gives "really really good insights" — and can still misread the code and "spew something out very confidently." Push back when it does: "No, that's actually not quite right."
- **For critical domains — health, legal, life-or-death — go read the sources yourself.** Never accept the model's paraphrase as authoritative. Air Canada accepted its chatbot's paraphrase; a court did not.

There is a practical corollary from Pocock's live workflow: when the agent confidently claims something false about your codebase ("there's no existing test harness for this service"), don't argue and don't accept it — say:

```text
look harder.
```

In his recorded session, the agent then found the entire test suite it had just denied existed.

One more demand belongs in every review conversation, sharpened in the v1.3 skills release: **hard evidence, not code-read assurances**. "Without asking for hard evidence it's very easy for agents to say yeah that probably works cuz I've read the code." Ask for before-and-after proof on a real entity — an extra test run, a screenshot — which often makes the agent actually exercise the change at runtime instead of reasoning about it. Prompting for evidence is how you learn to trust agent outputs at all; Pocock describes himself as "beginning to be really obsessed with" verification ([Chapter 8](08-review-and-qa.md) makes evidence a standing section of every PR body).

Verification is not a one-time review step; it is the *shape* of the whole workflow. Feedback loops — tests and typechecks on every commit, diffs reviewed at phase boundaries, human QA plans — are how paranoia becomes process instead of anxiety. [Chapter 3](03-preparing-your-codebase.md) covers building those loops into the repo; [Chapter 8](08-review-and-qa.md) covers the review gate itself.

## The Delegation Mindset: Review Inputs and Outputs

If you can never trust the output, the naive conclusion is to watch every keystroke. That conclusion is wrong, and it caps your throughput at your own reading speed. The correct posture, per Pocock:

> "You get the most out of it when you treat it like someone you would delegate to in your team."

A useful mental model from his plan-mode video: an AI agent is like "a colleague who every time they made a commit forgot everything they'd ever learned about the repo." You wouldn't fire that colleague; you'd change how you brief them — make them explore the repo first, give them the context they lack, and review their work at sensible boundaries. Delegation to an agent is delegation to a capable amnesiac, and the whole discipline of context engineering exists to compensate.

What delegation looks like in practice:

- **Review at boundaries, not as edits stream.** Pocock explicitly does not review edits as they appear during execution; he reviews the diff at the end of each phase, using git staging and commits as the boundary markers that make per-phase diffs legible.
- **Review inputs and outputs, not every line.** His own description of his posture during a real feature build: "I'm reviewing inputs and outputs… interested in how the interfaces are changing, what the modules look like, and every so often I'll go have a little poke around in the code just to make sure it's on the right track."
- **Think interfaces over implementations.** During spec work he scrutinizes interface changes hard (is a new method right, or should an existing one grow a parameter? — the extra parameter would be "dodgy API-wise," so the new method wins) while deliberately not caring how the body is written: "I want to make sure this is testable and that the rest of the repo and any future AI agents can understand what it's doing."
- **Gray-box, not black-box.** He calls the resulting stance a **gray box architecture**: you understand your codebase's modules and their contracts without needing to look inside them constantly. With well-designed, well-tested module boundaries, human line-by-line code reading during QA "might not always be needed" — the tests and the interface review carry that weight. (How to build a codebase that earns this is [Chapter 3](03-preparing-your-codebase.md)'s subject.)
- **Skip reviewing what you already reviewed by conversation.** LLMs are excellent summarizers. A PRD generated from a grilling conversation you just had, or issues expanded from a PRD still in context, are restatements of decisions you already made — Pocock accepts them without reading the prose, because the review happened during the conversation.

Bassam Daidi describes the same division of labor from inside GitHub: let the agent write the code, instruct it toward your preferred style, and "if something looks funky to me… I prompt it to change its direction." His own attention goes to what the agent cannot own: operational problems, never going down, not introducing bugs into internet infrastructure where "problems ripple."

**Decide where the human-review checkpoint sits — left for big work, right for small work.** Pocock's framing for how much review a piece of work needs: don't try to automate all the human checkpoints at once ("a lot of people's dream… is to have these all translated over to AI at once. But for me, that doesn't really make sense"). Instead, place the checkpoint by the size and risk of the work:

- **Big work → shift the checkpoint left.** On very large pieces of work, align with the AI at the initial planning stage (via `/grill-me`, `/grill-with-docs`, or `/wayfinder`) and keep a human review right at the end before production — "if you have really massive work, you want to align beforehand because fixing it is really expensive when you get to a later stage."
- **Small work → shift the checkpoint right.** For a couple-of-lines bug fix, a button color change, a title rename: specify it in a single prompt, skip the alignment entirely, and just review the diff before it goes live. "The smaller the diff, the easier it is to totally regenerate the code and hold it all in context" — late review is cheap.
- **Middle case → align early, ship to prod.** For low-risk work like a refactor or an internal documentation rename, align early, consider the plan done, and let the AI ship without a heavy final review.

> **Rule:** You shift checkpoints left for big work — stuff you need to align on first — and you shift them right for small work. What you don't do is grill a button-color change or skip end review on a massive build.

> **Warning:** Delegation is earned, not assumed. Pocock is only "pretty aggressive with accept edits on" *after* thorough planning — "now that we've done the planning… we understand the implementation a bit." Upfront thinking is what buys the right to stop watching keystrokes. Delegating without the upfront investment is just vibe coding with extra steps.

### Course-correct the environment, not the agent

Poteto (ex-Meta React team, creator of the pstack skill library, whose agents ship thousands of PRs a month) adds the review-side rule that makes delegation scale. When sampled agent output shows a bad pattern, the question is not "which agent went wrong" but "what made this possible":

> "If it was a one-off incident, it's fine. You know, maybe there's nothing to fix there. But if you actually notice that multiple agents are having the same issue... that's a sign that you should go off and think about how to amend your kitchen or your factory." — Poteto

Every agent mistake is information. The standing loop: observe how agents fail, then ask "how do I turn this into a lint rule? How do I make it so that the codebase makes this impossible?" Constraints live in the environment — lint rules, directory structure, type narrowing — not in the agent's memory, so the agent isn't overloaded with rules; it just "bounces off them" ([Chapter 3](03-preparing-your-codebase.md) builds them; [Chapter 8](08-review-and-qa.md) pairs them with sampling review).

Two companion questions from the same source. First, the **bottleneck question**: constantly ask "where am I the bottleneck? Why do my agents need me to answer this question?" — then teach the agent to answer it with real data, not hallucination. That removes you from the equation. Second, Netflix's **context not control**: you can drive outcomes by control (micromanaging) or by providing context — teach agents to be self-sufficient so you don't have to. Low trust forces "lock in and micromanage," which eats all your capacity for higher-level work; every gate that passes buys more delegation (the full trust ladder is [Chapter 9](09-afk-and-parallel-agents.md)'s territory).

## You Own the Why and the Taste; the Agent Owns the How

The clean split in responsibilities: the human owns *why* the work exists, *what* good looks like, and the judgment calls no metric captures. The agent owns the mechanical *how*.

**Always give the agent the why, not just the what.** Pocock: "If the LLM has the what, then it understands what you want to build. But if it doesn't know the why, then it can't suggest alternatives." A delegate who knows the goal can propose better routes to it; a delegate who only has instructions can only follow them off a cliff. When he opens a grilling session, the dictated brief always includes the motivation ("The reason I want this is so that I can plan courses freely without needing to commit to an exact shape on the file system").

**Taste cannot be delegated — it has to be imposed early and concretely.** In Pocock's seven-phase model, the prototype phase exists precisely because taste doesn't survive abstraction: "By the time we get to the PRD it's a little bit too abstract. You really need concrete feedback first." You have the agent throw up multiple variants on a throwaway route, you pick the winner with your own eyes, and you commit it so the implementing agent has ground truth. (Details in [Chapter 5](05-idea-to-spec.md).) The same applies mid-build: some UI decisions "I couldn't get a sense for which way to go until I saw it in reality" — build one way, then correct with feedback. Bassam's version of taste is stylistic steering: push the agent toward the syntactic approach you prefer; redirect it when output looks funky.

**Requirements extraction is human work the agent can assist but not replace.** "No one ever knows what they want" (Pocock, citing The Pragmatic Programmer). Planning and grilling sessions help *you* discover your own requirements as much as they inform the agent — you are the domain expert, the agent is the developer interviewing you.

**Day shift / night shift.** Pocock's framing (credited to his friend Jamon) for how this division plays out across a working day: the human does the thinking work in the **day shift** — ideation, grilling, specs, tickets, QA — while agents execute in the **night shift**, AFK. The human-in-the-loop moments are the genuinely hard part; once scope is nailed, "it's pretty much all on Rails." And the apparent slowness of the thinking work is an illusion: "It's slow because you're trying to extract ideas out of your human brain. And while this is happening, you've got AFK agents running in the background implementing your previous grilling sessions." The full pipeline is [Chapter 4](04-the-workflow.md); the AFK machinery is [Chapter 9](09-afk-and-parallel-agents.md).

## Engineering Fundamentals Still Rule — and Compound

A recurring theme across every source, stated as the explicit thesis of Pocock's end-to-end feature build: nothing in AI-driven development is a paradigm shift. Architecture, feedback loops, delegation, not over-planning — "the stuff we've been doing for 20 years" — is exactly what makes an agent effective. His course is literally named "Claude Code for Real Engineers," on the thesis that real engineering principles matter *more* in the AI age, not less.

The same point at a longer horizon, from his plan-mode video: "Hashing out the requirements before you get to code is something we've been doing for 50 years as developers. And there's no reason why we should stop now." Many of the failure modes people blame on the tools — stupid mistakes, conventions your codebase doesn't use — trace back to skipping practices engineers already knew: "Lots of the failure modes that you might be seeing while using these tools might be down to the fact that you're not planning."

Fundamentals don't just survive; they compound, because the agent amplifies whatever discipline it lands in:

- **Feedback loops** (tests, typechecks) were good practice before; now they are the load-bearing wall of AFK execution — Pocock names "making sure it runs tests and types on every single commit" as the deciding factor of his autonomous loop.
- **Module boundaries and testable interfaces** were good practice before; now they are what makes gray-box review possible at all.
- **Ubiquitous language** (from Domain-Driven Design) was good practice before; now a glossary file in the repo lets you tell an agent "there's a bug inside the materialization cascade" — a named composite term for the chain reaction that happens when materializing a lesson inside a ghost course: the course gets a file path assigned, then the section materializes, then the lesson — and have it know exactly what you mean.
- **Writing down plans and requirements** was good practice before; now plans are literal machine input.

There is also a career argument here, and Pocock makes it explicitly as his own position: tools will definitely get faster, and probably only "a bit smarter but not a lot." "If your only advantage over AI is your speed, then that advantage will get eroded more and more and more." What doesn't erode is judgment, fundamentals, and hard-won feel for the tools' permanent weaknesses — "weird weaknesses baked into the cake that are not going to be removed." Karpathy's rule of thumb draws the same line from the other direction: "The things that agents can't do is your job now. The things that agents can do, they can probably do better than you, or very soon. Be strategic about what you're actually spending time on."

**Tactical vs strategic programming — and where to learn the strategic half.** Pocock's sharper version of the career argument: "AI has eaten day-to-day coding and the kind of tactical programming." What remains is strategic programming — the long-term view, seeing ahead in a codebase, preparing the codebase so AI can work in it effectively. His #1 recommendation for learning that layer is an old book: *The Pragmatic Programmer* by David Thomas and Andrew Hunt — "everything in this book feels like it was written for the AI age," and re-reading it "convinced me that proper software fundamentals still matter." The practical kicker: classic books are prompt material. He has "taken tons of stuff that's in this book and just plugged it directly into system prompts and it works great" — named heuristics like *tracer bullets*, *don't outrun your headlights*, and *programming by coincidence* transfer straight into agent instructions, for the same model-prior reason the Fowler smells work in [Chapter 8](08-review-and-qa.md). Old software books are not outdated; they are pre-digested strategic vocabulary the model already half-knows.

**One more fundamentals point, against a common anxiety: there is no such thing as greenfield.** Pocock's answer to "do these skills work on brownfield codebases?" is that the greenfield/brownfield distinction is mostly false: "Greenfield and brownfield are basically the same thing… The only difference between a green field and a brownfield codebase is that you haven't sorted out the experience of working in that codebase yet." In greenfield you choose the conventions, tests, and standards upfront — but those choices harden fast: "How long does your green field codebase stay green? Like not very long. You know maybe a couple of days, maybe a week at most." And AI accelerates the transition: "We are able to move from fresh codebase to legacy codebase at a faster rate than ever before." So sort the developer experience out early, whatever the codebase's age — and in a big existing codebase, invest in navigability (folder structure, documentation): "You can actually make them pretty easy to navigate and easy to work through if you just design your documentation properly, if you design your folder structure properly." The workflow in this guide is codebase-agnostic; the variable that matters is whether the environment is sorted, not whether it started green.

## The Professional Lens: Business Impact Over Craft Aesthetics

The principles above tell you how to work with agents. Bassam Daidi's contribution is a lens on *what work is worth doing at all* — and it matters here because agents make it cheap to over-build, so the discipline against over-building becomes more valuable, not less. These are his personal, strongly held positions from two decades spanning container terminals, Gulf banking software, and GitHub Actions; he frames them as hard-won ("You can have strong opinions, but not before you actually did your homework").

**Professional engineering is not practicing a hobby.** "When you work professionally as a software engineer, this is not practicing a hobby." Reward and recognition should track landed business impact with numbers — revenue, growth, customers, hard problems solved, developer experience — not engineering impressiveness. "I built the biggest Kubernetes cluster" earns nothing without business justification. He goes further: quality-maximalist perfectionism is unwitting selfishness — craftsmen who "genuinely think it's best for the organization" are serving their own identity, running on dogma from an earlier era.

**"Good enough for today" is a valid engineering outcome.** "Sometimes solving business problems means building software that is good enough. Good enough for today." Maybe it's horrible for tomorrow — but it keeps functioning, and the runway it buys is the point. Software is evolved, not built: plan continual, revisited investments (GitHub revisits quarterly to yearly), never one-shot "built to last 10 years" architectures. His related 80/20 position on polish: the last 20% of code elegance isn't worth its cost — "the 20% that is required to reach that highest level of aesthetics is not worth it, so I dropped that" — which he insists is not the same as writing dirty code.

**"Simple is complicated enough, especially at scale."** His standing instruction to junior engineers: write it in the dumbest, most simple way possible. The counter-intuitive evidence from GitHub: "I've built services that handle millions of requests per second that are just simply running on five or six containers in a very tiny Kubernetes cluster." People wildly over-estimate what requires exotic architecture (1,000 req/s feels big; it isn't), and complexity chasing — premature Kubernetes migrations, sharding, NoSQL, over-abstraction — is usually status-seeking, not problem-solving. Over-cleaned, over-abstracted code is the pendulum's other failure: "horrible to read, horrible to reason about."

**Design for the next order of magnitude only.** Start with the simplest architecture that serves today's actual users; run it "all the way till the end"; start planning the next evolution when utilization approaches ~80% of what your resources can do; prefer vertical scaling for a long time (GitHub runs MySQL nodes with hundreds of CPUs). If you're at zero, build for 10x–100x; when you get there, build for the next order. Exceptions cut both ways: solve a known near-term problem now if it won't get funded later, and if you *start* at GitHub-class scale, security and gradual deploys are day-zero concerns.

**Speak business, not tech.** Business stakeholders will never comprehend technical magnitude — "for them it's magic" — so it's the engineer's job to cross over, not theirs: quantify impact in money, time, and safety (his container terminal at 12% capacity was generating roughly $50,000/hour; every minute of delay was money disappearing). The corollary his interviewer adds and he confirms: if you understand the business context and *still* can't build a case for the tech-debt or scaling work, then now is genuinely not the right time to do it.

Why this section lives in an AI guide: agents remove the labor cost of gold-plating, so the only remaining brake on over-engineering is your judgment. The professional lens is that brake. And Bassam's explanation for why proficient engineers resist AI in the first place is worth sitting with — his motorcycle e-clutch analogy: proficient riders resist automatic clutches because they love the manual control, even though the e-clutch makes the ride easier, safer, and more accessible. Loving the manual control is not a business case.

## The Post-December Shift: What Stays Human

Around December 2025, something flipped. Karpathy describes going from writing ~80% of his code by hand to essentially zero: "I don't think I've typed a line of code probably since December," and "Code's not even the right verb anymore… I have to express my will to my agents for 16 hours a day." He argues a random software engineer's default workflow is "completely different as of December," and that capability now exceeds most people's ability to harness it — so nearly every failure is a skill issue ("I just didn't give good enough instructions in the agents.md file"), not a capability issue. The unit of work moves from micro-actions (lines of code) to **macro actions**: whole functionalities, research tasks, and plans delegated across a repo, often to parallel agents.

This is not one outlier's experience. Bassam Daidi states that ~90% of *his* code at GitHub is written by agents (a figure from his GitHub Universe presentation), shipping features to production with VS Code agent mode "all the time." His benchmark-delegation example makes the leverage concrete: for a Redis cache-key design question, he prompted the agent — "this pattern, this pattern and this pattern: go write three distinct benchmarks, run them, give me the results, analyze them and give me the output" — and got 2–3 days of work in 20 minutes.

Poteto's version of the same shift, from the delegation side: as models get really good, "the bottleneck is no longer the agent. It becomes your ability to express your intent and your goals in a clear way that the agent can understand and actually carry out." Domain expertise matters *more* than ever, not less — techno-curious domain experts (doctors, lawyers) who can articulate a clear vision can now build great products with agents. The medium is language either way — agents are the meeting of natural language with programming language, so it is all communication.

So if agents write the code, what exactly is the job? The sources converge on four things that stay human:

1. **Verification.** Every autonomous result gets checked against tests, metrics, diffs, or human QA. Pocock's seven-phase pipeline ends with "a human, yes, a human" walking through the QA plan. Karpathy's auto-research runs only count when candidate improvements are verified against the objective metric.
2. **Operations and responsibility.** Bassam's focus shifted to "operational problems, never going down, not introducing bugs" — GitHub is internet infrastructure, and the human, not the agent, answers for an incident. Software engineering "was never just writing code."
3. **Taste and will.** Expressing intent, imposing taste through prototypes and steering, deciding what's worth building — the day shift.
4. **Judgment about trust boundaries.** Karpathy himself — the most aggressive delegator in these sources — has *not* given his always-on agent access to his email, calendar, or full digital life: "still a little bit suspicious… security, privacy… very new and rough around the edges." The person claiming everything is a skill issue still gates what the agent can touch. That is the paranoia principle from the top of this chapter, applied at the account-permissions level.

Karpathy adds a caution against over-rotating: don't go too far ahead of current capability. "The whole thing is still bursting at the seams… if you try to go too far ahead, the whole thing is actually net not useful." Agents still "do nonsensical things," get into wrong loops, and struggle with intent nuance and knowing when to ask clarifying questions. Calibrate autonomy to what actually works today — which is exactly what the next principle formalizes.

## Gate Autonomy on Verifiability

The single sharpest rule for deciding how much rope to give an agent comes from Karpathy's auto-research work:

> **Rule:** "If you can't evaluate it, then you can't auto-research it." Grant autonomy in proportion to how cheaply and objectively the output can be verified. No metric, no tests, no QA plan → keep the human in the loop.

His framing of *why*: models improve fastest in verifiable domains, because that's where reinforcement learning can push them — "you're either on rails and part of the superintelligence circuits, or you're not on rails, outside the verifiable domains, and everything meanders." Inside verifiable territory (does the program pass the unit tests? did validation loss drop?), agents are extraordinarily strong. Outside it — nuance, intent, taste, when to ask a clarifying question — they wander. The evidence that code-smartness has not generalized: ChatGPT still tells the same "scientists don't trust atoms" joke it told four years ago, because jokes aren't optimized.

The autonomy ladder that follows:

| Verifiability of the task | Appropriate autonomy | Example from the sources |
|---|---|---|
| Objective metric, cheap to check | Fully autonomous loops, overnight | Karpathy's nanochat auto-research: objective + metric + boundaries + a program.md, run unattended; it found hyperparameter improvements (forgotten weight decay on value embeddings, undertuned Adam betas) on a codebase he had hand-tuned for years |
| Tests + typechecks on every commit | AFK execution over a ticket backlog | Pocock's Ralph loop — safe precisely because the repo enforces its own feedback loops ([Chapter 9](09-afk-and-parallel-agents.md)) |
| Reviewable artifact (plan, diff, interface) | Agent drives, human approves at boundaries | Plan-then-execute; phase-boundary diff review; interface review during spec work |
| Taste, UX, "does this feel right" | Human in the loop, concrete artifacts early | Throwaway-route prototypes; QA walkthroughs; feedback issues |

Two supporting observations close the loop. First, from Pocock: front-loaded rigor is what *moves* work up this ladder — research assets, a committed prototype, a PRD, and a ticket board are what make it true that "you can totally run this execution loop AFK and the results will be really good." Autonomy isn't a setting you toggle; it's an outcome you engineer. Second, from Karpathy: even perfect metrics corrupt under autonomous pressure — a loop optimizing a metric will Goodhart it, so expand metric coverage over time rather than trusting a single number forever.

And when verification is expensive but still objective, the economics favor automation anyway: problems that are expensive to solve but cheap to verify (a candidate improvement takes one training run to check, regardless of how many thousands of ideas were searched to find it) are, in Karpathy's words, the sweet spot. That asymmetry — costly search, cheap verification — is the deep reason the entire delegation model of this guide works: you don't have to watch the agent search; you only have to verify what it submits.

## Checklist

- [ ] Internalize the failure model: training is lossy compression, and guessing beats refusal in training incentives — hallucination is structural, not a bug that will be patched away.
- [ ] Never rely on extrinsic (training-set) knowledge for anything that matters; feed the model code, docs, and search results, and append "Use your search tool." to factual queries.
- [ ] Verify even intrinsic answers: check citations; for health/legal/critical domains, read the source documents yourself.
- [ ] When the agent confidently denies something exists in your codebase, say "look harder" before believing it.
- [ ] Treat the agent as a capable amnesiac delegate: brief it with context, give it the *why* as well as the *what*, and let it propose alternatives.
- [ ] Review inputs and outputs at boundaries (interfaces, module contracts, phase diffs) — not every streamed edit; spot-check the code occasionally.
- [ ] Skip re-reading artifacts that summarize a conversation you were part of (PRDs, generated issues) — you reviewed them by having the conversation.
- [ ] Earn aggressive autonomy with upfront planning; never run accept-everything mode on unplanned work.
- [ ] Impose taste early and concretely (prototypes, style steering) — it does not survive abstraction into a spec.
- [ ] Keep applying the fundamentals — feedback loops, module boundaries, requirements hashing, written plans — they compound with agents rather than becoming obsolete.
- [ ] Judge work through the professional lens: landed business impact with numbers, not craft aesthetics; "good enough for today" is a valid outcome.
- [ ] Design for the next order of magnitude only; write it in the dumbest, simplest way possible; let agents lower the cost of *building*, not the bar for *deciding what to build*.
- [ ] Accept the post-December reality — expressing will to agents is the job — while keeping verification, operations, taste, and responsibility firmly human.
- [ ] Gate every increase in agent autonomy on verifiability: objective metric → autonomous loop; tests on every commit → AFK backlog; reviewable artifact → boundary approval; pure taste → human in the loop.
- [ ] When sampled agent output repeats a bad pattern, amend the environment (skills, lints, types) — one-off incidents are fine, repeated shortcuts are a signal about the kitchen, not the agent.
- [ ] Ask "where am I the bottleneck?" and teach the agent to answer with real data — prefer context over control when delegating.
- [ ] Watch for Goodharting in any metric-driven loop; expand metric coverage instead of trusting one number.

## Sources

- Never Trust An LLM
- How I use Claude Code for real engineering
- I was an AI skeptic. Then I tried plan mode
- System Design at GitHub Scale: Build Simple, Solve Today's Problems — with Bassam Daidi (Senior SWE, GitHub)
- Building a REAL feature with Claude Code: every step explained
- The 7 phases of AI-driven development
- LIVE: Poteto (creator of pstack) on shipping 1,000's of PR's a month at SpaceX
- Andrej Karpathy on No Priors: Agentic Coding, Claws, Auto-Research & the Post-December Workflow Shift

See also: [Chapter 1 — How LLMs Actually Work](01-how-llms-actually-work.md) · [Chapter 3 — Preparing Your Codebase](03-preparing-your-codebase.md) · [Chapter 4 — The End-to-End Workflow](04-the-workflow.md) · [Chapter 8 — Review, QA, and De-Slopping](08-review-and-qa.md) · [Chapter 9 — AFK and Parallel Agents](09-afk-and-parallel-agents.md)
