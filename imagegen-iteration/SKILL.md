---
name: imagegen-iteration
description: "Use when a user is iterating on AI-generated images, art direction, character cosplay, props, reference matching, social-post-safe variants, or repeated image edits where visual intent, references, pose, object silhouette, or hand interaction must be clarified before generating again."
---

# Imagegen Iteration

Use this skill to guide image-generation sessions that need visual direction, not just a single prompt.

## Core Rule

Stop generating when the failure is conceptual. Close the visual question first, then generate once with the new decision.

Conceptual failures include:
- The named IP, character, prop, or style was guessed without reference.
- The prop silhouette is not recognizable.
- The pose does not match how the prop is held or used.
- The image is technically good but misses the user's intended mood.
- The user says to discuss, brainstorm, or close open questions.

## Reference First

When the user names a specific anime, game, character, artist, product, or prop:

1. Search the web before prompting.
2. Prefer official pages, official social posts, trailers, character pages, goods pages, and production notes.
3. Download useful references when possible and inspect them locally.
4. Separate reference roles:
   - Identity: face, hair, outfit, colors, signature shapes.
   - Mood: cute, dangerous, mysterious, realistic, convention-shot.
   - Prop: silhouette, scale, angle, grip, material, glow.
5. If references conflict, say what is known and choose the clearest official cue.

## Iterate By Diagnosis

Before each regeneration, name the specific defect and the planned fix:

- Identity: "blue jacket and orange braids are right; prop is wrong."
- Pose: "the hand still reads as a pistol grip."
- Silhouette: "the ring must read as hollow with a top module and two fins."
- Contact: "the object floats unintentionally; add finger occlusion or deliberate levitation."
- Moderation: "avoid realistic guns, blood, attack poses, or weapon pointed at the camera."

Do not stack many unrelated changes. Preserve what worked.

## Visual Hierarchy And Prompt Budget

Prompt length does not imply control. Repeated constraints and long avoid lists
make every detail compete for attention and invite literal rendering.

Before generating a conceptual image, state:

1. First read: the one subject or action visible immediately.
2. Delayed read: the one reveal discovered after looking longer.
3. Relationship: how those two reads change the meaning of each other.

Use one primary focal point and at most one delayed reveal. If two similar symbols
appear, define their relationship explicitly; otherwise they become competing
subjects. Remove details that do not support either read. When copy sits outside
the image, let it carry the explanation instead of adding code, labels, or other
literal cues inside the image.

Keep the prompt hierarchical: core scene, delayed reveal, mood, then only the most
important exclusions. Shorten repeated negatives rather than trying to forbid every
possible failure.

## Calibrate Hidden Reveals

Do not treat a hidden detail as simply present or absent. Decide when it should be
noticed: at thumbnail size, after two or three seconds, or only at full resolution.
Inspect the result at both thumbnail and full size.

For a delayed reveal, prefer incomplete silhouettes, negative space, repeated
architectural lines, and restrained contrast. If it is invisible, strengthen one
recognition cue. If it is too obvious, break the complete outline or remove a
competing highlight instead of only making the whole image darker.

Change one visibility variable per iteration. Do not add a second hidden anomaly
to compensate for a reveal that is poorly calibrated.

## Long Iteration Recovery

When a session has many variants, do not assume the newest image is the best base.
If the user points back to an earlier version, inspect that exact image and make it
the edit target unless there is a clear reason not to.

Keep a small candidate ledger in the conversation or notes:
- Path or image label.
- What works.
- What fails.
- Whether it was exported, opened, imported, or safe to delete.

For each new attempt, state the base image or whether it is a fresh generation.

## Near-Local Image Edits

When the user wants to fix one defect in an otherwise good image, treat it as a
near-local repair, not a new generation.

Required flow:
1. Identify the exact base image, usually the earlier variant the user praised.
2. Load or inspect that image so it is the edit target in context.
3. Write the prompt as a repair instruction, not a full scene description.
4. Start with "Edit the displayed image with a very small local repair only."
5. Add a "Preserve exactly" sentence listing every area that must not change.
6. Describe only the defective region and the replacement.
7. Put all global scene/style changes in "Do not change..." or omit them.

Avoid restating the whole original generation prompt. Broad style, mood,
composition, and character descriptions invite a redraw. If the available image
tool has no explicit mask controls, say that limitation plainly, then use a
preserve-heavy local repair prompt.

Example:

```text
Edit the displayed image with a very small local repair only. Do not redraw or
reinterpret the whole illustration.

Preserve exactly: the same canvas, camera angle, background, lighting, palette,
line style, main character, stage, and the subject's body, pose, hands, and props.

Local change only: remove the pinecone-like hat from the squirrel's head. Replace
only that headwear area with a normal rounded squirrel head top: smooth brown fur
and two small rounded ears, matching the existing outline thickness.

Do not change the stage, background, main character, props, lighting, composition,
or add new objects.
```

## Cosplay Conversion

For "make it realistic cosplay" requests, translate anime design into real materials:

- Hair -> wig fibers, visible styling, hair clips or ribbons.
- Eyes -> colored contacts and catchlights.
- Outfit -> fabric, vinyl, leather, seams, zippers, snaps, chains, rings.
- Props -> convention-safe handmade material, resin, foam, acrylic, LEDs.
- Background -> convention hall, booth lights, blurred attendees, banners without readable text.
- Mood -> expression, posture, lighting, and prop handling; not explanatory text.

Use cosplay-safe language for risky objects: fictional prop, convention-safe, no blood, no attack pose, not pointed at viewer.

## Visual Language Precision

Use exact physical words for props and effects. "Line", "wire", "filament",
"thread", "ribbon", "strap", "beam", and "trail" produce different images.
If an effect is being misread, stop and rename the visual material before prompting.

Prefer material language over abstract effect language:
- Metal filament: physical, thin, reflective, slight weight.
- Metal ribbon: wider, edge visible, bends and twists.
- Energy beam: straight, luminous, nonphysical.
- Tentacle: biological, flexible, often unwanted.

If a prop repeatedly steals attention or reads incorrectly, make one no-prop
variant to test whether the character and mood work without it.

## Props And Hands

Props fail when shape and hand logic disagree. Decide these before generating:

1. What is the object's canonical silhouette?
2. Is it held, balanced, worn, holstered, or levitating?
3. What angle lets the viewer read the silhouette?
4. Which fingers touch or occlude it?
5. What light, shadow, or reflection proves contact or levitation?

For levitating props, make the hand palm-up, place the prop 5-8 cm above the palm, add glow on the palm, and tilt the prop enough to reveal its structure.

For held props, include finger occlusion, contact shadows, a clear grip point, and slight wrist weight.

## Gaze And Body Logic

Eye direction needs a body reason. "Looking into the distance" often becomes blank
unless the pose explains what the character is doing.

Before asking for sharper or deeper eyes, decide:
- What did the character notice?
- Where is the gaze locked?
- What is the body doing in response?
- Is the expression alert, angry, sad, seductive, or withholding?

Use posture to carry intent: leaning on a railing, stopping mid-step, turning one
shoulder toward a sound, or resting a hand near a pocket can make a quiet gaze read
as observation instead of posing.

## Prompt Shape

Write prompts in this order:

1. Preserve: list the elements that already work.
2. Change: describe the single main fix.
3. Reference cues: name the official visual cues without claiming exact copying.
4. Pose/prop mechanics: hand, angle, silhouette, contact/levitation.
5. Mood: emotional read from the viewer's perspective.
6. Avoid: failed prior artifacts, moderation risks, and wrong object types.

Example:

```text
Preserve the same realistic convention cosplayer, orange braided wig, red contacts,
blue cropped jacket, black collar, hard carrying case, and direct mysterious gaze.
Replace only the hand prop with an official-style hollow ring boomerang: black ring,
teal trim, top mechanical module, two short horn-like fins. It hovers 5-8 cm above
her palm, tilted 35 degrees toward the camera so the hollow center and fins are clear.
Add teal glow on her palm. Avoid guns, knives, attack pose, text, logos, and distorted hands.
```

## Output Handling

When the user asks to save or open generated images from Codex:

- Use `codex-image-extract` if the image only exists in the Codex rollout JSONL.
- Save final candidates with descriptive filenames.
- Use `open <file>` on macOS for preview.
- Use AppleScript Photos import or `adb push` only when the user asks for Photos or phone gallery.
- For successful reusable prompts, store compact examples in `references/successful-prompts.md`.
