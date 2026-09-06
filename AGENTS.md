# Skill workspace

## Syncing skills

After changing a skill that must be mirrored to `nuc-kep`, run
`just sync-skill <skill-name>` from this directory. The recipe mirrors the
complete skill to `~/.agents/skills/<skill-name>/` on `nuc-kep` and verifies
that local and remote file hashes match.

## Codex skill metadata

Keep `SKILL.md` frontmatter within the Codex-supported schema: `name`,
`description`, `license`, `metadata`, and `allowed-tools`. Put Codex-specific UI,
dependency, and invocation settings in `agents/openai.yaml`.

For a skill that must be invoked explicitly, use:

```yaml
policy:
  allow_implicit_invocation: false
```

Do not use Claude-specific frontmatter such as `disable-model-invocation`,
`argument-hint`, `category`, `claude-code`, `hidden`, or top-level `references`.
