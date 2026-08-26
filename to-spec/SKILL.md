---
name: to-spec
description: Turn the current conversation into a project-local draft spec, then run the shared spec self-review to revise it and determine readiness.
disable-model-invocation: true
---

Turn the current conversation and codebase context into one implementation-ready spec. Do not restart discovery as an interview. Draft from the known context, then use the shared spec review workflow to revise it and determine readiness.

Use the project-local Markdown tracker exclusively. Choose a concise feature slug and write the spec to `.scratch/<feature-slug>/spec.md`, creating the directory when needed. One spec is the delivery boundary for exactly one PR. It may later produce multiple tickets, but those tickets are work units within that PR.

## Process

1. Explore the repository enough to understand current behaviour, existing test seams, domain vocabulary, and relevant ADRs.

2. Choose the highest existing seam that can verify the observable feature. Add a seam only when no existing one can test the promised behaviour. Make technical testing decisions yourself.

3. Draft the spec at `.scratch/<feature-slug>/spec.md` with `Status: draft`, using the template below.

4. After writing the draft, discover and read `spec-self-review` by its exact frontmatter name, then follow it against the new spec in the same turn. Do not mark the spec `ready-for-agent` independently; that skill owns revision, clarification, and the readiness decision.

<spec-template>

Status: draft

## Problem Statement

The problem from the user's perspective.

## Solution

The smallest complete solution from the user's perspective.

## User Stories

A numbered list covering the promised user-visible behaviour. Include only stories needed to define the feature and its important edge cases.

1. As an <actor>, I want <feature>, so that <benefit>.

## Delivery Boundary

This spec is implemented and reviewed as one PR. It may be decomposed into multiple tickets on the same branch when that makes execution easier.

## Implementation Decisions

Decisions that constrain the implementation, such as changed modules or interfaces, architectural choices, schema changes, API contracts, and specific interactions. Prefer the simplest design that meets the user stories.

Do not include file paths or code snippets that will quickly go stale. If a prototype produced a decision-rich state machine, reducer, schema, or type shape that is more precise than prose, include only that trimmed excerpt and identify it as prototype-derived.

## Testing Decisions

State the observable contracts to test, the highest existing seams used, and relevant prior art in the repository. Test behaviour rather than implementation details.

## Estimated Changed LOC

Estimate implementation size as ranges for product code, tests, and configuration/docs, followed by a total range. Count additions plus deletions against the PR's fixed point; exclude generated files and lockfiles. Note the main assumptions behind the estimate so implementation can report actuals and explain material variance.

## Out of Scope

Name nearby capabilities intentionally excluded from this PR.

## Further Notes

Only context needed to implement or review the spec.

</spec-template>
