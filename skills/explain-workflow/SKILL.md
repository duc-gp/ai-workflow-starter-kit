---
name: explain-workflow
description: Explain, in plain language, why this AI-development workflow does what it does — or help a user who isn't sure what to do next understand their situation and options. Grounded in development-guide/, not silent routing.
---

# Explain Workflow

Two distinct triggers land here, both handled the same way:

1. The user asks **why** — why grill before writing code, why clear context between tickets, why two-axis review, why any rule the workflow follows.
2. The user seems **unsure what to do next** — doesn't know which skill applies, doesn't understand what just happened, or asks something like "what do I do now?" / "I don't get it."

This is different from ordinary routing (the behavior described in this repo's `CLAUDE.md`) and from `ask-matt`: those pick the right skill and either proceed or tell the user which command to run. This skill is for when the user wants — or needs — the reasoning made visible instead of hidden. Once they understand, continue with whatever actually fits; don't stop at the explanation if there's still work to do.

This skill is deliberately model-invocable, unlike most of the workflow skills — a user who is confused should not have to know a command name to get unstuck.

## Where the knowledge lives

Ground every answer in `development-guide/` at this repo's root — 13 chapters distilled from the source material this whole workflow is based on, plus a glossary and skill catalog. It was bundled in by the starter kit alongside this skill.

Use `development-guide/README.md`'s table of contents to find the right chapter fast instead of searching blind. Common lookups:
- Why the workflow is staged the way it is → Chapter 4 (`04-the-workflow.md`)
- Why grilling comes before writing code → Chapter 5 (`05-idea-to-spec.md`)
- Why tickets are sized the way they are, blocking edges → Chapter 6 (`06-tickets-and-planning.md`)
- Why `/implement` clears context between tickets → Chapter 7 (`07-execution.md`)
- Why review runs on two axes → Chapter 8 (`08-review-and-qa.md`)
- Any term that's unclear ("smart zone", "gray-box module", etc.) → Chapter 13, the glossary

If `development-guide/` was removed from this repo, answer from what you already know about the workflow rather than blocking — but say so, since the answer won't be traceable to a source.

## How to answer

- **Translate, don't paste.** Don't quote the chapter's prose wholesale — explain it in plain language, tied to what's actually happening in the user's project right now ("we're about to clear context because the ticket you just finished and the next one don't need to share a thinking process — starting fresh keeps the agent sharp").
- **Keep it short.** One or two paragraphs. The goal is confidence, not a lecture. If they want more, they'll ask a follow-up.
- **Cite where it lives**, so they can go deeper on their own later if they want (e.g. "more on this in `development-guide/07-execution.md`") — but never require them to open it themselves.
- **If they're stuck on what to do next**, narrate rather than just act: where they are, why the next step is what it is, what happens if they skip it. Then ask if they want you to proceed, or just proceed if the answer is obvious from context.

## Out of scope

- Questions about the user's own codebase or domain (business logic, architecture of their app) — that's `domain-modeling` or a plain answer, not this skill.
- "Just do the right thing" requests with no explicit why/confusion signal — stay silent and route normally; don't over-explain unprompted.
