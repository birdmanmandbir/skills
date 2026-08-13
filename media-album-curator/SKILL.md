---
name: media-album-curator
description: Use when organizing a local batch of photos or videos into a small shareable album, especially mixed HEIC, MOV, JPG, JPEG, PNG, or MP4 files from phone transfers, LocalSend, Downloads, or repeated imports.
---

# Media Album Curator

## Overview

Curate a local media batch into upload-friendly albums without losing the originals. The core loop is: find the real candidate set, remove exact duplicates, make contact sheets, select with the user, then export clean JPG/MP4 copies.

## Workflow

1. Identify the batch.
   - Check both modification and creation/change times. Phone transfers and LocalSend often preserve original modification dates.
   - Include mixed extensions: `HEIC`, `MOV`, `JPG`, `JPEG`, `PNG`, `MP4`.
   - Exclude obvious non-album files such as screenshots, certificates, bank cards, app demos, or work recordings unless the user asks.

2. Deduplicate safely.
   - Use exact hashes first; do not delete visually similar media by guess.
   - Prefer keeping the cleaner original name over suffix copies like `-2`.
   - Run `scripts/dedupe-media.sh <dir>` first. Add `--delete` only after reviewing the list.

3. Build review contact sheets.
   - Use `scripts/media-contact-sheet.sh <source-dir> <work-dir>`.
   - Photos become thumbnail sheets.
   - Videos become 3-frame strips by default; extract more frames for long or action-heavy clips.

4. Curate with the user.
   - Keep an explicit upper bound, default 15 if unspecified.
   - Favor variety over near-duplicates: season, distant/close views, motion, people/activity, animals, city, lake/sea, day/night.
   - Treat user taste corrections as source of truth; replace weaker same-category picks rather than exceeding the cap.

5. Export shareable copies.
   - JPG: auto-orient, sRGB, strip metadata, long edge up to about 2560, quality 88-92.
   - MP4: H.264 + AAC, yuv420p, long edge up to 1920, `+faststart`.
   - Keep original source candidates in a separate folder if the user wants to inspect them.

## Commands

Generate contact sheets:

```bash
~/.agents/skills/media-album-curator/scripts/media-contact-sheet.sh ~/Downloads ./album-work
```

Find exact duplicates:

```bash
~/.agents/skills/media-album-curator/scripts/dedupe-media.sh ~/Downloads
```

Delete exact duplicates after review:

```bash
~/.agents/skills/media-album-curator/scripts/dedupe-media.sh ~/Downloads --delete
```

## Selection Notes

- Ask for clarification only when deleting or replacing could be risky. Otherwise make a reversible copy-based output.
- If the user says "today I added files", search creation/change time as well as modification time.
- If ImageMagick cannot decode HEIC, use macOS `sips` for HEIC to JPEG previews.
- Do not modify originals during export. Create album output folders such as `00_selected`, themed folders, and `source-jpg-mp4-candidates`.
