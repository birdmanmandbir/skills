---
name: to-spec
description: Turn the current conversation into a project-local Markdown spec — synthesize first, then discuss only a high-leverage simplification found during self-review.
disable-model-invocation: true
---

Turn the current conversation and codebase context into one implementation-ready spec. Do not restart discovery as an interview. Ask only when the self-review finds a user-facing tradeoff where dropping a low-priority requirement materially simplifies the implementation.

Use the project-local Markdown tracker exclusively. Choose a concise feature slug and write the spec to `.scratch/<feature-slug>/spec.md`, creating the directory when needed. One spec is the delivery boundary for exactly one PR. It may later produce multiple tickets, but those tickets are work units within that PR.

## Process

1. Explore the repository enough to understand current behaviour, existing test seams, domain vocabulary, and relevant ADRs.

2. Choose the highest existing seam that can verify the observable feature. Add a seam only when no existing one can test the promised behaviour. Make technical testing decisions yourself.

3. Draft the spec at `.scratch/<feature-slug>/spec.md` with `Status: draft`, using the template below.

4. Self-review the completed draft before marking it ready:
   - Can this coherently land in one PR?
   - Which elements are required for the user's core outcome, and which are merely nice to have?
   - Is there speculative abstraction, configuration, compatibility staging, prefactoring, or platform breadth unsupported by a current requirement?
   - Can one low-value requirement be dropped to remove disproportionate implementation complexity?
   - Does a simpler design satisfy both the user experience and implementation constraints?

   Delete complexity that has no user-facing cost. If dropping or narrowing a user-visible point creates a meaningful simplification, present the tradeoff, your recommendation, and the concrete complexity it removes; wait for the user's choice. Do not ask about routine implementation details.

5. Revise the spec from that decision and set `Status: ready-for-agent`. The ready spec must still describe one PR, even when `/to-tickets` later divides its work into several tickets.

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

## Out of Scope

Name nearby capabilities intentionally excluded from this PR.

## Further Notes

Only context needed to implement or review the spec.

</spec-template>
