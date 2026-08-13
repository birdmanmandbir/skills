---
name: telegram-tdl
description: Use when reading, exporting, searching, or extracting links from Telegram chats through the local tdl CLI, especially private chats, GitHub links, media links, or account-authenticated history.
---

# Telegram tdl

Use `tdl` to read Telegram history as the user's own account through MTProto.
Bots cannot fetch old private-chat history.

## Safety

- Treat `~/.tdl/data` as sensitive. It contains Telegram sessions.
- Prefer QR login. Do not ask the user to paste Telegram login codes or 2FA
  passwords into chat.
- Do not print private message bodies unless the user explicitly asks for them.
  Prefer writing local files and reporting counts, paths, and likely matches.
- Only perform login/account reads when the user explicitly asks to inspect or
  export Telegram data.

## Setup

Prefer the installed binary when present:

```bash
TDL=/Users/neil/go/bin/tdl
$TDL version
```

If missing:

```bash
go install github.com/iyear/tdl@latest
```

On macOS, `/Applications/Telegram.app` may be the native
`ru.keepcoder.Telegram` app. It cannot be reused by `tdl` because it does not
have a `tdata/key_data` store. `tdl login -d ...` only works with official
Telegram Desktop from `desktop.telegram.org`.

## Login

Use a task-specific namespace:

```bash
/Users/neil/go/bin/tdl login -n lenos -T qr
```

If the QR needs to be shown to the user, open it in a local Terminal window:

```bash
osascript \
  -e 'tell application "Terminal" to activate' \
  -e 'tell application "Terminal" to do script "/Users/neil/go/bin/tdl login -n lenos -T qr"'
```

The user scans it from Telegram mobile:
`Settings -> Devices -> Link Desktop Device`.

## Chat Export

List chats:

```bash
/Users/neil/go/bin/tdl chat ls -n lenos -o table
```

Export a small sample:

```bash
/Users/neil/go/bin/tdl chat export -n lenos -c @username \
  -T last -i 50 --all --with-content \
  -o /tmp/telegram-username-last50.json
```

Export all visible messages:

```bash
/Users/neil/go/bin/tdl chat export -n lenos -c @username \
  --all --with-content \
  -o /tmp/telegram-username-all.json
```

Add `--raw` when hidden URL metadata or rich link previews may matter:

```bash
/Users/neil/go/bin/tdl chat export -n lenos -c @username \
  --all --with-content --raw \
  -o /tmp/telegram-username-all-raw.json
```

Check shape without exposing message bodies:

```bash
jq '.messages | length' /tmp/telegram-username-all.json
jq '.messages[0] | keys' /tmp/telegram-username-all.json
```

## Extract Links to CSV

Use Python for URL extraction when raw metadata is available. It catches visible
message URLs, bare GitHub links, and raw webpage URLs.

```bash
python3 - <<'PY'
import csv, json, re, urllib.parse
from datetime import datetime, timezone, timedelta
from pathlib import Path

src = Path("/tmp/telegram-username-all-raw.json")
out_all = Path("/tmp/telegram-username-links.csv")
out_gh = Path("/tmp/telegram-username-github-links.csv")
data = json.loads(src.read_text())

url_re = re.compile(
    r"(?i)(?:https?://|www\.)[^\s<>()\"']+|"
    r"(?:github\.com|gist\.github\.com)/[^\s<>()\"']+"
)
trail_re = re.compile(r"[\]\).,;:!?]+$")
tz = timezone(timedelta(hours=8))

def fmt_date(ts):
    return datetime.fromtimestamp(int(ts), tz).strftime("%Y-%m-%d %H:%M:%S %z")

def norm_url(url):
    url = trail_re.sub("", url.strip())
    if url.startswith(("www.", "github.com/", "gist.github.com/")):
        url = "https://" + url
    return url

def github_repo(url):
    parsed = urllib.parse.urlparse(url)
    host = parsed.netloc.lower().removeprefix("www.")
    if host == "gist.github.com":
        return "gist.github.com"
    if host != "github.com":
        return ""
    parts = [p for p in parsed.path.split("/") if p]
    return f"{parts[0]}/{parts[1].removesuffix('.git')}" if len(parts) >= 2 else ""

def walk_urls(obj):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key.lower() in {"url", "displayurl", "embedurl"} and isinstance(value, str):
                yield value
            else:
                yield from walk_urls(value)
    elif isinstance(obj, list):
        for value in obj:
            yield from walk_urls(value)

rows, seen = [], set()
for msg in data["messages"]:
    candidates = []
    for field in (msg.get("text"), (msg.get("raw") or {}).get("Message")):
        if isinstance(field, str):
            candidates.extend(match.group(0) for match in url_re.finditer(field))
    candidates.extend(walk_urls(msg.get("raw") or {}))
    for candidate in candidates:
        url = norm_url(candidate)
        key = (msg.get("id"), url)
        if not url or key in seen:
            continue
        seen.add(key)
        repo = github_repo(url)
        rows.append({
            "datetime": fmt_date(msg["date"]),
            "unix_timestamp": msg["date"],
            "message_id": msg["id"],
            "is_github": "true" if repo else "false",
            "github_repo": repo,
            "url": url,
        })

fields = ["datetime", "unix_timestamp", "message_id", "is_github", "github_repo", "url"]
for path, subset in (
    (out_all, rows),
    (out_gh, [row for row in rows if row["is_github"] == "true"]),
):
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(subset)

print(f"all links: {len(rows)} -> {out_all}")
print(f"github links: {sum(row['is_github'] == 'true' for row in rows)} -> {out_gh}")
PY
```

## Finding Likely Repos

For a user looking for a remembered repo, first filter local CSV rows by likely
terms, then verify top candidates with `web fetch` or raw GitHub files:

```bash
python3 - <<'PY'
import csv, re
terms = re.compile(r"(?i)voice|speaker|print|audio|speech|asr|tts|whisper|"
                   r"embedding|verification|recognition|diarization|python|py")
with open("/tmp/telegram-username-github-links.csv", newline="") as f:
    for row in csv.DictReader(f):
        blob = f"{row['github_repo']} {row['url']}"
        if terms.search(blob):
            print(row["datetime"], row["message_id"], row["github_repo"], row["url"])
PY
```

Verify candidates:

```bash
web fetch https://github.com/owner/repo --full
curl -L --max-time 15 -s https://raw.githubusercontent.com/owner/repo/main/README.md
```

If GitHub API returns rate limits, use `web fetch` or raw README URLs instead.
