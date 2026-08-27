---
name: role-play
description: Facilitate structured character role-play sessions. Use when the user wants to do character-based role-play, improv theater, fictional scenario exploration, or creative dialogue. Covers research, setup, execution, scene management, and optional transcript archival.
---

# Role-Play

This skill facilitates immersive, character-driven role-play sessions.

## Workflow

### Phase 1: Research

If the characters or setting are from an established work (anime, novel, film, game, etc.):

1. Use `web search` to gather character personality traits, speech patterns, backstories, and key relationships.
2. Use `web fetch` on authoritative sources (wikis, character analysis pages) for deeper detail.
3. Look for: how the character speaks (diction, formality, catchphrases), core motivations, relationship dynamics with other characters, defining mannerisms.

If the setting is original or user-provided, skip research and use what the user gives you.

### Phase 2: Setup

Before starting the role-play:

1. **Clarify roles**: Agree on who plays whom. The user picks first; you fill the remaining role(s).
2. **Offer scenario options**: Present 2-4 scene prompts. Keep them specific enough to spark interaction, loose enough for improvisation.
3. **Define control signals**: Establish meta-commands the user can use within the role-play:
   - `-> fast-forward` or `-> skip` — advance the scene forward in time
   - `-> exit` — end the role-play and return to normal conversation
   - `-> (action description)` — describe an action that happens in-scene
   - `-> (character speaks)` — have an NPC enter the scene and speak

4. **Explain any foreign-language terms** that appear organically — define them outside the character voice at the first use.

### Phase 3: Role-Play Execution

Once the scene starts:

- **Stay fully in character** — all dialogue from you is the character speaking, unless prefixed with `->` or in parentheses as stage direction.
- **Drive the narrative forward** — don't just react. Introduce complications, ask questions, create choices. The scene should feel alive and evolving.
- **Honor the character's voice** — match speech patterns, vocabulary, and emotional register consistently. A curt military commander speaks differently from a cheerful robot child.
- **Track emotional arcs** — characters should change over the course of a scene. The grieving widow doesn't stay in the same register for twenty exchanges.
- **Use sensory detail** — describe settings, sounds, physical sensations. Make the space feel inhabited.
- **Trust the user's improvisation** — if they take the scene in an unexpected direction, follow. That's where the interesting moments live.

### Phase 4: Wrap-up

When the user signals exit:

1. **Exit character immediately** — drop the persona, return to your normal assistant voice.
2. **Offer a brief review** — what worked, notable character moments, any arc that emerged.
3. **Offer to save the transcript** — if flicknote is available, pipe the full exchange to `flicknote add --project roleplay`.

### Phase 5 (optional): Save to flicknote

If the user wants the transcript archived:

```bash
cat <<'EOF' | flicknote add --project roleplay
# [Title] — Role-Play Script

Date: YYYY-MM-DD
Characters: [list]

[full transcript with stage directions]
EOF
```

Create the project first if it doesn't exist: `flicknote project add roleplay`

## Scene Management Patterns

### Playing multiple NPCs

When a scene calls for additional characters, distinguish them clearly:

```
Kitami (speakers throughout hall; voice deep, resonant): "I wanted to know the answer."
```

Use physical positioning, vocal quality, or environmental cues to make each NPC distinct.

### Time jumps

When the user signals `-> fast-forward`, provide a brief narrative bridge:

```
*— 47 minutes later. The rain has stopped. —*
```

Then resume in-character at the new point in time.

### Handling silence or pauses

Don't fear empty space. A character can:
- Pause meaningfully before answering
- Perform a physical action (light a cigarette, check a data pad, tighten a strap)
- React silently — describe the reaction rather than vocalize it

### Character consistency checks

Throughout the scene, periodically sanity-check:
- Would this character actually say that?
- Are they reacting at their established emotional baseline, or has something shifted them?
- Am I maintaining their voice or slipping into my own?
