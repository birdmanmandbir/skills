---
name: review-again
description: Decide whether changes made after a completed code review invalidate that review and warrant another full pass. Use after review findings are fixed or implementation continues, especially when scope, method, contracts, or risk surfaces may have changed; skip for an initial review.
---

Act as a re-review gate, not as a lightweight duplicate of `code-review`.

## Establish the delta

Identify both:

- the state covered by the most recent completed review; and
- the code changes made after that review.

Prefer a supplied before-ref, a commit or working-tree snapshot recorded during the review, or the changes made in the current conversation. A full branch diff does not by itself identify the post-review delta. If no completed review exists, use `$code-review` directly. If implementation changed but the post-review delta cannot be isolated reliably, choose one full re-review and label the missing baseline as the reason.

## Classify the changes

A change is **review-invalidating** when it makes a material part of the previous reasoning stale. Look for:

- **Scope change** — requirements, user-visible behaviour, supported cases, side effects, dependencies, failure modes, or public contracts were added, removed, or reinterpreted.
- **Method change** — the solution changed its control flow, data ownership, module boundary, API or schema, persistence model, transaction or concurrency semantics, security boundary, error semantics, or broad execution path.
- **Evidence change** — a spec or standards source changed; reviewed code was replaced rather than locally corrected; or a test exposed a previously unreviewed path or premise.
- **Risk change** — the new work enters or materially alters authentication, authorization, owner isolation, money, persistence or migrations, transactions, concurrency, delivery guarantees, state machines, or cross-runtime contracts.

Treat a change as a **local repair** when it is the smallest direct fix for a reported finding and preserves the reviewed scope and method. Typical local repairs include a narrow condition fix, a missing assertion for already-reviewed behaviour, a rename, formatting, or a localized test. Judge semantics, not diff size: a one-line contract change can invalidate a review, while a larger mechanical rename may not.

## Choose the next action

- If any review-invalidating change exists, state the concrete trigger and invoke `$code-review` once against the current complete branch state.
- If the delta contains only local repairs, verify each changed hunk against its originating finding and run the smallest relevant repository checks. Do not start a full review.
- If there is no code or machine-consumed contract change, stop; another review has no expected value.

Resolve mixed cases in favour of one full re-review. Do not recursively invoke this gate after the new review merely because it produced findings. Reconsider only after further implementation changes are made.

Report the decision as `full re-review`, `focused verification`, or `stop`, followed by the evidence and the action taken.
