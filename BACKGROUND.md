# Background: How This Came to Be

You've cloned this into your repo and run `init.sh`, and now Claude Code behaves differently here — it interviews you before big features, sizes work into session-length chunks, reviews its own output with a fresh set of eyes, and reaches for a diagnosis loop when something's broken, all without you naming a single command. This document explains where that behavior actually comes from, so it isn't a black box.

## The two sources, kept deliberately separate

This kit is built from two independent things that happen to come from the same person:

1. **The skills themselves** — `grill-with-docs`, `implement`, `code-review`, `to-spec`, `to-tickets`, `wayfinder`, `tdd`, `triage`, and the rest — are installed directly from Matt Pocock's real, actively maintained open-source repository, [`github.com/mattpocock/skills`](https://github.com/mattpocock/skills) (41 skills there at last count; this kit installs a curated 21, skipping his personal course/writing/note-taking tooling that doesn't generalize). They are not reconstructed or reverse-engineered from anything — `init.sh` runs the same official installer anyone would use.

2. **The `CLAUDE.md` routing logic** — the part that decides *which* skill to reach for from a plain-language request, without you ever typing a slash command — was synthesized by an AI agent (Claude) from 33 of Matt Pocock's YouTube videos about this exact workflow, plus a handful of adjacent interviews (Andrej Karpathy on agentic coding, a GitHub senior engineer on system design and AI delegation, a context-engineering explainer). The videos describe the workflow in prose and demos; this kit's `CLAUDE.md.template` is that workflow turned into an operational decision tree.

In short: the tools are the real, official ones; the routing that picks the right tool at the right moment is a distillation of how their author actually talks about using them.

## The full pipeline

```
33 YouTube video transcripts
        │  (33 parallel extraction agents, one per video)
        ▼
structured per-video notes
        │  (synthesis: write → adversarial review against
        │   the notes → fix → cross-chapter coherence pass)
        ▼
a 13-chapter guide — "The AI-Driven Development Guide"
        │  (the guide's decision logic, condensed)
        ▼
CLAUDE.md.template  ◄──────────────  the real mattpocock/skills repo
   (this file)                          (the real skill definitions)
        │                                        │
        └──────────────────┬─────────────────────┘
                            ▼
              what init.sh installs in your repo
```

The guide itself — all 13 chapters, the raw transcripts, and the extraction notes in between — lives in the parent project this kit was built alongside, not in this standalone kit (it would be a lot of extra weight to carry into every repo you clone this into). If you have access to that project, it's the `development-guide/`, `transcripts/`, and `extraction-notes/` folders one level up from wherever `starter-kit/` sits in it. If you don't, everything you actually need to *use* the workflow is already in this kit — the guide is reference material for understanding *why*, not a dependency for running it.

## Why the guide and the routing logic exist at all

The premise, straight from the source material: individual-prompting skill varies wildly, and that variance is *the* reason AI-assisted development quality is inconsistent — one developer grills the agent thoroughly and sizes work correctly, another pastes a vague request into a stale codebase and gets back whatever comes out. The fix isn't finding better prompters; it's moving the judgment calls out of individual heads and into a process that runs the same way regardless of who's typing. That's what `CLAUDE.md.template` operationalizes, and it's why this kit exists as something you install once rather than a set of habits you're expected to remember.

## Honesty about what's grounded and what isn't

The guide this routing logic came from was built under a strict rule: every technique, number, and quote had to trace back to something actually said in the source videos — an adversarial review pass and a separate human-quality pass checked for exactly this before the guide was considered finished. Where the videos' author changed his approach over time (a skill renamed, a technique abandoned for a better one), the guide followed the newest position, and the routing logic here reflects that newest position too, not an average of everything ever said.

## Attribution

The workflow, the skills, and almost all of the source material this kit's `CLAUDE.md` logic was distilled from belong to Matt Pocock — [`github.com/mattpocock/skills`](https://github.com/mattpocock/skills) is his repository, and `init.sh` installs from it directly. This kit is an independent packaging effort, not an official release of his.
