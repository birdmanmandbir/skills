set positional-arguments := true

# Mirror one local skill to nuc-kep and verify every file.
sync-skill skill:
    #!/usr/bin/env bash
    set -euo pipefail

    skill_name=$1
    case "$skill_name" in
      ''|*[!a-z0-9-]*)
        printf 'invalid skill name: %s\n' "$skill_name" >&2
        exit 2
        ;;
    esac

    skill_dir="{{ justfile_directory() }}/$skill_name"
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || {
      printf 'skill not found: %s\n' "$skill_dir" >&2
      exit 1
    }

    remote_dir=".agents/skills/$skill_name"
    rsync -av --delete --checksum "$skill_dir/" "nuc-kep:$remote_dir/"

    diff -u \
      <(cd "$skill_dir" && find . -type f -exec shasum -a 256 {} \; | LC_ALL=C sort -k2) \
      <(ssh nuc-kep "cd ~/$remote_dir && find . -type f -exec sha256sum {} \\; | LC_ALL=C sort -k2")
    printf 'synced %s to nuc-kep:%s/\n' "$skill_name" "$remote_dir"
