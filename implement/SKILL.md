---
name: implement
description: "Implement a piece of work based on a project-local spec or its tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

## Local work layout

Project-local work lives under:

```text
.scratch/
  <feature-slug>/
    spec.md
    issues/
      01-<ticket-slug>.md
      02-<ticket-slug>.md
      ...
```

Start from the feature directory named by the user or implied by the current branch/work. Read `spec.md` first when it exists, then read every issue relevant to the requested work. Use ticket numbers, `Blocked by`, and status fields to find the current dependency frontier. If the user asks for the whole spec, work through that frontier in dependency order.

One spec corresponds to one PR. Multiple issue files are execution units on the same feature branch, not separate PR boundaries.

## Execution

Use `/tdd` where it fits, at the seams selected in the spec. Make routine implementation, error classification, locking, platform, and testing details yourself unless they expose an unresolved user-visible tradeoff.

Run typechecking and targeted tests regularly, then the full relevant suite once at the end. Verify the observable acceptance criteria, not just the build.

Once done, use `/code-review`; it will compare against the default branch unless the user specified another fixed point. Resolve merge-blocking findings, then commit the work to the current feature branch.
