---
name: steam-deck-recording-export
description: Export Steam Game Recording clips from a Steam Deck over SSH. Use when asked to retrieve a Steam or non-Steam shortcut recording, discover Steam userdata account IDs, select the newest clip, or turn Steam gamerecordings DASH fragments into a playable local MP4.
compatibility: SSH access to the Steam Deck plus ffmpeg and ffprobe on the Deck and local machine.
---

# Steam Deck Recording Export

Export one selected Steam Game Recording as a local H.264/AAC MP4. Steam stores recordings as fragmented DASH media; use the clip-local manifest and remux on the Deck, then copy the finished MP4 locally.

## Inputs and safeguards

- Use the SSH host the user gives. `steamdeck` is only a default when the user names that configured host.
- Use the current directory as the output location unless the user specifies another one.
- Treat `userdata/<account-id>` as a Steam **AccountID**, not a 17-digit SteamID64. Use the directory name verbatim.
- Preserve the remote recording tree. A short-lived file in `/var/tmp` is the only remote write.
- Never overwrite an existing destination. Select a new output name instead.

## 1. Find the Steam root and account ID

Run remote commands through `bash -s`, rather than relying on the interactive remote shell. Resolve the Steam root once:

```bash
host=steamdeck
ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s <<'REMOTE'
set -euo pipefail
for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/steam"; do
  root=$(readlink -f "$candidate" 2>/dev/null || true)
  if [ -n "$root" ] && [ -d "$root/userdata" ]; then
    printf '%s\n' "$root"
    exit 0
  fi
done
printf 'Steam userdata not found\n' >&2
exit 1
REMOTE
```

List local Steam AccountIDs and whether they contain recordings:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s <<'REMOTE'
set -euo pipefail
root=''
for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/steam"; do
  candidate=$(readlink -f "$candidate" 2>/dev/null || true)
  if [ -n "$candidate" ] && [ -d "$candidate/userdata" ]; then root=$candidate; break; fi
done
[ -n "$root" ] || { printf 'Steam userdata not found\n' >&2; exit 1; }
shopt -s nullglob
for user_dir in "$root"/userdata/[0-9]*; do
  account_id=${user_dir##*/}
  clips="$user_dir/gamerecordings/clips"
  count=0
  [ -d "$clips" ] && count=$(find "$clips" -mindepth 1 -maxdepth 1 -type d -name 'clip_*' | wc -l)
  printf '%s\t%s clips\n' "$account_id" "$count"
done
REMOTE
```

For a non-Steam shortcut, set `title` to its game title or executable name and identify the owning account by searching its binary `shortcuts.vdf`:

```bash
title='your-game-title-or-executable'
ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s -- "$title" <<'REMOTE'
set -euo pipefail
title=$1
root=''
for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/steam"; do
  candidate=$(readlink -f "$candidate" 2>/dev/null || true)
  if [ -n "$candidate" ] && [ -d "$candidate/userdata" ]; then root=$candidate; break; fi
done
[ -n "$root" ] || { printf 'Steam userdata not found\n' >&2; exit 1; }
shopt -s nullglob
for user_dir in "$root"/userdata/[0-9]*; do
  shortcuts="$user_dir/config/shortcuts.vdf"
  if [ -r "$shortcuts" ] && strings "$shortcuts" | grep -Fqi -- "$title"; then
    printf '%s\n' "${user_dir##*/}"
  fi
done
REMOTE
```

If several accounts match, use the one with the matching shortcut and recent recording candidates. `config/loginusers.vdf` can supply persona context, but its keys are SteamID64 values; the corresponding `userdata` folder is the lower 32-bit AccountID.

## 2. Select the exact clip

The recording root is:

```text
<steam-root>/userdata/<account-id>/gamerecordings
```

List clips by the timestamp embedded in their names. Prefer this over fragment modification time, which synchronization can change:

```bash
account_id='<account-id-from-step-1>'
ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s -- "$account_id" <<'REMOTE'
set -euo pipefail
account_id=$1
root=''
for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/steam"; do
  candidate=$(readlink -f "$candidate" 2>/dev/null || true)
  if [ -n "$candidate" ] && [ -d "$candidate/userdata" ]; then root=$candidate; break; fi
done
[ -n "$root" ] || { printf 'Steam userdata not found\n' >&2; exit 1; }
clips="$root/userdata/$account_id/gamerecordings/clips"
shopt -s nullglob
for clip in "$clips"/clip_*; do
  name=${clip##*/}
  stem=${name#clip_}
  time=${stem##*_}
  before_time=${stem%_*}
  date=${before_time##*_}
  game_id=${stem%%_*}
  printf '%s_%s\t%s\t%s\n' "$date" "$time" "$game_id" "$clip"
done | sort -r
REMOTE
```

- For a request for the **latest** recording, choose the first clip after confirming its timestamp with the user’s wording.
- For a standard Steam app, the `game_id` is normally its Steam AppID. Confirm the title with `steamapps/appmanifest_<game-id>.acf`.
- For a non-Steam shortcut, `game_id` can be a 64-bit Steam GameID. Its upper 32 bits can narrow the matching shortcut/`compatdata` directory, but verify against `shortcuts.vdf`, the executable, timestamp, and thumbnail before exporting. Do not infer a title from the number alone.
- When title matching remains ambiguous, show the candidate timestamps and thumbnails or ask the user to choose; do not export a guess.

Use the manifest **inside the selected clip**, not the similarly named foreground-session manifest under the recording root:

```bash
# On the Deck, after setting clip to the selected clip directory:
find "$clip" -path '*/video/fg_*/session.mpd' -type f -print -quit
```

Probe that remote manifest before exporting. A typical Steam Deck recording is H.264 video plus AAC audio:

```bash
ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name,width,height \
  -of json "$remote_mpd"
```

## 3. Remux on the Deck and copy locally

Run this locally after setting `host`, the selected `remote_mpd`, and a non-existing `out`. The remote temporary file makes `+faststart` possible; streaming directly to stdout does not.

```bash
host=steamdeck
remote_mpd='/home/deck/.local/share/Steam/userdata/<account-id>/gamerecordings/clips/<selected-clip>/video/<foreground-session>/session.mpd'
out="$PWD/recording.mp4"

[ ! -e "$out" ] || { printf 'Refusing to overwrite %s\n' "$out" >&2; exit 1; }
work=$(mktemp -d "${TMPDIR:-/tmp}/steam-recording.XXXXXX")
remote_tmp=''
cleanup() {
  if [ -n "$remote_tmp" ]; then
    ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s -- "$remote_tmp" >/dev/null 2>&1 <<'REMOTE_CLEANUP' || true
rm -f -- "$1"
REMOTE_CLEANUP
  fi
  rm -rf "$work"
}
trap cleanup EXIT

remote_tmp=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" bash -s -- "$remote_mpd" <<'REMOTE_EXPORT'
set -euo pipefail
remote_mpd=$1
tmp=$(mktemp /var/tmp/steam-recording-export.XXXXXX.mp4)
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT
ffmpeg -nostdin -y -v error -i "$remote_mpd" \
  -map 0:v:0 -map '0:a:0?' -c copy -movflags +faststart "$tmp"
trap - EXIT
printf '%s\n' "$tmp"
REMOTE_EXPORT
)

case "$remote_tmp" in
  /var/tmp/steam-recording-export.*.mp4) ;;
  *) printf 'Unexpected remote output path: %s\n' "$remote_tmp" >&2; exit 1 ;;
esac

scp -q "$host:$remote_tmp" "$work/export.mp4"
ffprobe -v error \
  -show_entries format=format_name,duration,size:stream=codec_type,codec_name,width,height \
  -of json "$work/export.mp4"
ffmpeg -nostdin -v error -i "$work/export.mp4" -map 0:v:0 -f rawvideo -y /dev/null
ffmpeg -nostdin -v error -i "$work/export.mp4" -map 0:a:0 -f s16le -y /dev/null
mv "$work/export.mp4" "$out"
printf 'Exported %s\n' "$out"
```

The `ffprobe` result and both full-stream decodes are the completion gate. For the usual H.264/AAC source, `-c copy` keeps the original quality while producing a broadly playable MP4. If the source codec is incompatible or remuxing fails, transcode to H.264/AAC only after preserving the original recording and report that fallback.

## Completion

Report the selected AccountID, source clip timestamp, local output path, duration, stream codecs, and that both streams decoded. Confirm the remote temporary file was removed.
