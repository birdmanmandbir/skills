# Skill workspace

## Syncing skills

After changing a skill that must be mirrored to `nuc-kep`, run
`just sync-skill <skill-name>` from this directory. The recipe mirrors the
complete skill to `~/.agents/skills/<skill-name>/` on `nuc-kep` and verifies
that local and remote file hashes match.
