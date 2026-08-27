#!/usr/bin/env python3
"""Extract built-in image generation PNGs from a Codex rollout JSONL file."""

from __future__ import annotations

import argparse
import base64
import json
import re
from pathlib import Path


def slugify(value: str, fallback: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value[:80] or fallback


def iter_images(rollout: Path):
    with rollout.expanduser().open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue

            if record.get("type") != "event_msg":
                continue

            payload = record.get("payload") or {}
            if payload.get("type") != "image_generation_end":
                continue

            result = payload.get("result")
            if not isinstance(result, str) or not result:
                continue

            yield line_number, payload


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rollout", required=True, type=Path)
    parser.add_argument("--out-dir", default=Path.cwd(), type=Path)
    parser.add_argument("--prefix", default="")
    args = parser.parse_args()

    out_dir = args.out_dir.expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for count, (line_number, payload) in enumerate(iter_images(args.rollout), start=1):
        prompt = payload.get("revised_prompt") or payload.get("prompt") or ""
        fallback = f"codex-image-{count:02d}"
        stem = slugify(prompt, fallback)
        if args.prefix:
            stem = f"{slugify(args.prefix, args.prefix)}-{stem}"
        output = out_dir / f"{stem}.png"

        suffix = 2
        while output.exists():
            output = out_dir / f"{stem}-{suffix}.png"
            suffix += 1

        image_bytes = base64.b64decode(payload["result"])
        output.write_bytes(image_bytes)
        print(f"{output} line={line_number} bytes={len(image_bytes)}")

    if count == 0:
        print(f"No image_generation_end records found in {args.rollout}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
