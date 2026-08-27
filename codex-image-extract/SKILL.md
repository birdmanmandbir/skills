---
name: codex-image-extract
description: "Extract generated images from Codex session rollout JSONL files. Use when a user asks to save, open, recover, export, or locate images produced by the built-in image generation tool, especially when the image appears only in the chat UI or in a Codex session log as base64."
---

# Codex Image Extract

Use this skill to recover images generated during a Codex thread from rollout JSONL logs.

## Quick Start

Prefer the bundled script:

```bash
python ~/.agents/skills/codex-image-extract/scripts/extract_codex_images.py \
  --rollout ~/.codex/sessions/YYYY/MM/DD/rollout-....jsonl \
  --out-dir .
```

If the current thread is known in `~/.codex/state_5.sqlite`, find its rollout path:

```bash
sqlite3 ~/.codex/state_5.sqlite \
  "select rollout_path from threads order by updated_at desc limit 1;"
```

Then run the script against that path.

## Workflow

1. Identify the relevant rollout JSONL file. In current Codex installs this is usually under `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`.
2. Extract `event_msg` records with `payload.type == "image_generation_end"`.
3. Decode `payload.result` from base64 into PNG files.
4. For long image-iteration sessions, extract into a temporary directory first, then copy only the selected final candidate into the workspace. This avoids restoring old discarded variants into the current repo.
5. Name outputs clearly. Use the prompt-derived filename when helpful, or the default numbered filename from the script.
6. If the user asks to preview the result, open the saved PNG with `open <file>` on macOS.
7. If the user asks to add the image to Photos, import it with AppleScript:

```bash
osascript -e 'set imageFile to POSIX file "/absolute/path/image.png"' \
  -e 'tell application "Photos"' \
  -e 'activate' \
  -e 'import {imageFile} skip check duplicates yes' \
  -e 'end tell'
```

Then verify by filename:

```bash
osascript -e 'tell application "Photos"' \
  -e 'set matches to every media item whose filename is "image.png"' \
  -e 'return count of matches' \
  -e 'end tell'
```

## Notes

- Rollout JSONL can be large because image base64 is stored inline. Avoid dumping the whole file to the chat.
- Use `jq` or the bundled Python script instead of ad hoc grep when extracting image data.
- A generated image may not be in sqlite; sqlite often points to the rollout file that contains the actual base64.
