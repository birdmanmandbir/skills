---
name: research
description: Investigate a question against high-trust primary sources, using a background researcher for source-gathering and the main agent for synthesis and storage in FlickNote. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated.
---

The main agent owns the research outcome: it frames the question, dispatches source-gathering, judges whether the evidence is sufficient, synthesizes the result, and writes the final FlickNote note. Align the brief below before spawning anything. Once aligned, spin up the named custom agent `researcher` in the background, so you keep working while it reads. Invoke it by name without model or reasoning overrides; its TOML owns those settings. If `researcher` is unavailable, report a configuration blocker instead of substituting a generic agent.

## Align before research

Before dispatching the agent, identify the decision this research should
inform, its relevant value stance, scope and boundaries, and the expected
deliverable. Resolve discoverable facts yourself. Ask the user concise
questions, with recommended answers, only when unresolved ambiguity would
materially change the research; otherwise state the framing briefly and
proceed. Dispatch once every decision-relevant ambiguity is resolved or
explicitly accepted as uncertainty.

The researcher's job:

1. Search FlickNote's `research` project for existing work on the question. Use relevant keywords with `note_find`, then read promising notes with `note_get`. Build on useful prior findings, but reverify factual claims that may be stale.
2. Investigate the remaining question against **primary sources** — official docs, source code, specs, and first-party APIs. Follow every factual claim back to the source that owns it; distinguish verified facts, interpretation, speculation, and unknowns.
3. Return an evidence packet to the main agent containing the verified findings and their direct source URLs, relevant prior-note material, conflicts, unknowns, and concrete follow-up leads. The packet is research input, not the final synthesis.

After the researcher completes, the main agent must:

1. Compare the evidence packet with the aligned brief and produce a draft synthesis that accounts for every question by mapping it to cited evidence or an explicit unknown.
2. Decide whether any material gap could change the conclusion. If so, dispatch a focused follow-up to the same researcher and repeat this review after it completes. Stop when the decision-relevant claims are supported or the remaining uncertainty is genuinely unresolved.
3. Write one Markdown document with the question, findings, recommendation, trade-offs or value stance where relevant, open questions, and cited sources. Save it with `note_add` in FlickNote's `research` project, then return the note's title and ID.

Use FlickNote MCP `note_*` tools for lookup and final storage. Only the main agent writes the final note. If FlickNote MCP is unavailable, report the blocker instead of writing a repository file or using a note-management CLI.
