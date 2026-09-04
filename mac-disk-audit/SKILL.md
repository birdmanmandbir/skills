---
name: mac-disk-audit
description: Use when a macOS disk is low, APFS free-space numbers seem inconsistent, or a user wants to find, rank, archive, or safely remove large files, caches, applications, developer artifacts, snapshots, or old Git repositories.
---

# Mac Disk Audit

## Overview

Find reclaimable space without confusing the sealed system volume with the writable Data volume. Measure first and require approval before deletion.

## Audit

Run the bundled non-destructive report first:

```bash
~/.agents/skills/mac-disk-audit/scripts/mac-space-audit
```

Use `--fresh` to ignore results, `--no-cache` to disable cache writes, and `--stale-days N` to change the repository threshold. The script never deletes. For strict zero-write requests, use `df`, `diskutil`, and `du`; skip Git and Homebrew.

If fixed-path reporting is not enough, scan the home directory without crossing filesystems:

```bash
gdu -x -k -d 2 "$HOME" > /tmp/mac-home-depth2.tsv
sort -rn /tmp/mac-home-depth2.tsv | head -100
```

Poll long scans instead of restarting. Report permission failures as unknown; do not use `sudo`.

## Classify Findings

Apply these classes before recommending anything:

| Class | Examples | Action |
|---|---|---|
| Protected mobile | Xcode, Simulator, Android SDK/NDK, AVD, Gradle, mobile projects | Keep unless specifically named |
| Rebuildable cache | Bun, uv, npm, Go modules, Qlty, Yarn, Playwright, Puppeteer | Prefer the tool's cleanup command |
| App-managed data | Telegram, browsers, OrbStack, Steam | Use app storage or uninstall UI |
| Personal data | Mail, Messages, notes, downloads | Never infer disposability from size |
| Git archive candidate | Old repository | Check dirty files, untracked files, remotes, unpushed branches, and tags |
| System-managed | APFS snapshots, Preboot, VM/swap, `/private/var` | Explain; do not force-delete |

Treat `/` and `/System/Volumes/Data` as volumes sharing one APFS container. Do not add nested repositories, mounted simulators, OrbStack mounts, snapshots, or hard-linked caches as independent sizes.

## Clean Safely

Before any write:

1. State path, size, purpose, recovery cost, and command.
2. Obtain explicit approval for that category.
3. Run help before a new cleanup subcommand.
4. Prefer `bun pm cache rm`, `uv cache clean`, `npm cache clean --force`, or `go clean -modcache`.
5. Quit an application before removing its cache or logs.
6. After deletion, verify the path, confirm affected tools still run, and recheck `df -h /`.

Treat deleting a cache or build directory and deleting its parent project as separate categories. If scope expands to the whole project, run the repository gate and obtain approval that explicitly names the whole directory.

Report measured bytes separately from the asynchronous APFS `df` change.

## Git Archive Gate

Never recommend deleting a repository until all checks pass:

```bash
git -C "$repo" status --short --branch
git -C "$repo" remote -v
git -C "$repo" log --branches --tags --not --remotes --oneline
git -C "$repo" branch -avv
git -C "$repo" show-ref --tags
```

A clean, fully pushed public clone can be recloned. Verify local tags against a reachable remote; remote-tracking branches do not prove tags were pushed. Missing or unreachable remotes, local changes, unpushed commits, or local-only tags require backup.

The bundled report identifies old repositories that need this manual gate; it never labels one an archive candidate on its own.

## Common Mistakes

- Reading `df -h /` as system files; the Data volume holds most bytes.
- Calling every `~/Library` byte a cache; many entries are databases or user content.
- Deleting package installations instead of download caches.
- Clearing developer caches despite mobile protection.
- Promising a 50 GiB plan without measuring and de-duplicating its components.
