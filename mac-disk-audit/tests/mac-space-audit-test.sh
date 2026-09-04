#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

HOME_DIR=$TEST_DIR/home
REMOTE_DIR=$TEST_DIR/archive.git
REPO_DIR=$HOME_DIR/Code/archive
mkdir -p "$HOME_DIR/Code"
git init --bare "$REMOTE_DIR" >/dev/null
git clone "$REMOTE_DIR" "$REPO_DIR" >/dev/null
git -C "$REPO_DIR" config user.email test@example.invalid
git -C "$REPO_DIR" config user.name test
printf 'archive fixture\n' >"$REPO_DIR/README.md"
GIT_AUTHOR_DATE='2020-01-01T00:00:00Z' GIT_COMMITTER_DATE='2020-01-01T00:00:00Z' \
  git -C "$REPO_DIR" add README.md
GIT_AUTHOR_DATE='2020-01-01T00:00:00Z' GIT_COMMITTER_DATE='2020-01-01T00:00:00Z' \
  git -C "$REPO_DIR" commit -m fixture >/dev/null
git -C "$REPO_DIR" push origin HEAD >/dev/null

OUTPUT=$(zsh "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/mac-space-audit" \
  --home "$HOME_DIR" --no-system --no-cache --stale-days 1)

grep -Fq '需完整门禁' <<<"$OUTPUT"
if grep -Fq '归档候选' <<<"$OUTPUT"; then
  printf 'mac-space-audit-test: report promoted a repository before the manual gate\n' >&2
  exit 1
fi

printf 'mac-space-audit tests passed\n'
