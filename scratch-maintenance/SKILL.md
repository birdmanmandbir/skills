---
name: scratch-maintenance
description: Maintain project-local `.scratch` work by separating active, merged, and intentionally deferred specs; use when archiving completed specs, cleaning scratch directories, reconciling stale statuses, or checking what work remains active.
---

# Scratch Maintenance

Keep `.scratch` as a trustworthy work index:

- `.scratch/<slug>/` — active work, including implemented work whose PR is still unmerged.
- `.scratch/archived/<slug>/` — implementation verified as merged into the repository default branch.
- `.scratch/deferred/` — intentionally postponed work, not completed work.

Location records delivery state; a Markdown `Status:` records document state. Neither substitutes for merge evidence.

## Process

### 1. Inventory

List top-level `.scratch` entries, specs, tickets, and their `Status:` lines. Exclude `archived` and `deferred` while identifying active work. Preserve research tasks and miscellaneous notes that do not claim to be implementation specs.

Detect duplicate slugs across active, archived, and deferred locations before moving anything.

**Done when:** every movable spec directory has one current location and its document statuses are known.

### 2. Resolve the default branch

Use the current branch remote and its remote `HEAD`; fall back to local `main` or `master` only when no remote default is available. Record the resolved ref once.

Do not update the checkout or rewrite branches as part of maintenance. If current merge evidence is unavailable locally, use the approved repository/PR inspection tool when available. Otherwise leave the work active and report that merge status is unverified.

**Done when:** one fixed default-branch ref is available, or the lack of one is explicit.

### 3. Prove completion

Archive a spec only when its implementation is proved merged by at least one authoritative fact:

- the implementation commit is an ancestor of the resolved default branch; or
- the repository forge reports the implementation PR as merged into that default branch.

Use commit messages, branch/PR metadata, spec slug, and conversation context to identify the implementation commit or PR. Confirm the match rather than relying on similar names.

A coder report, green CI, deployed branch, open PR, `Status: implemented`, or locally finished code is not merge evidence. Keep such work active. A deployed-but-unmerged change is especially active because the repository still lacks it.

If evidence conflicts, keep the directory active and report the conflict instead of guessing.

**Done when:** every proposed archive move names its merged commit or merged PR.

### 4. Classify deferred work

Move work into `.scratch/deferred/` only when the user or its document explicitly postpones it. Preserve the reason, reconsideration trigger, and guardrails when present.

Deferred means “not planned now,” not “merged,” “blocked,” or “awaiting review.” An open implementation PR remains active unless the user explicitly abandons it and wants its plan retained as deferred.

**Done when:** every deferred item has an intentional postponement signal.

### 5. Reconcile and move

Move each entire spec directory so its spec and tickets remain together:

- merged implementation → `.scratch/archived/<slug>/`
- unmerged, open, in progress, blocked, or merge-unverified → `.scratch/<slug>/`
- intentionally postponed → `.scratch/deferred/<slug>/` or one clearly named deferred note

For a verified merged directory:

- set the spec to `Status: implemented`;
- set completed tickets still marked `ready-for-agent` to `Status: done`;
- preserve meaningful terminal states such as `superseded`, `cancelled`, or `wont-do`.

Do not change an active spec from `implemented` back to `ready-for-agent` merely because its PR is unmerged. Its active location already records that delivery is incomplete.

Do not create compatibility copies or leave the same work in two locations.

**Done when:** each item exists in exactly one intended location and archived status lines no longer advertise unfinished work.

### 6. Verify

Mechanically confirm:

- no duplicate slugs exist across the three locations;
- every archived spec has merge evidence and `Status: implemented`;
- no open or unverified PR was archived;
- every deferred item has a postponement reason or explicit user decision;
- active specs remain discoverable at `.scratch/<slug>/`;
- moves did not alter source code or generated artifacts.

Report:

1. **Archived** — slug plus merged commit/PR evidence.
2. **Restored/active** — especially anything previously archived without proof.
3. **Deferred** — slug plus reason.
4. **Unverified** — what stayed active and what evidence is missing.
5. **Status corrections** — documents changed from stale states.

If no changes are needed, say so. Do not create tickets, rewrite specs, implement code, merge PRs, or deploy as part of this skill.
