---
name: axiom-sre
description: Query logs through an existing Axiom CLI profile when investigating an incident or verifying a log-based hypothesis.
---

# Read Axiom Logs

Use the already authenticated local `axiom` CLI to collect evidence from logs. This skill is read-only: it does not configure Axiom, create or modify Axiom resources, write local state, or operate production systems.

## Discover, then query

1. Check that `axiom` is available. If it is missing or its existing profile cannot authenticate, report that blocker. Do not inspect, copy, or configure credentials.
2. Run `axiom dataset list` and select a dataset from its output. Do not infer a dataset name.
3. Set a bounded investigation window. Pass it to every query with `--start-time <from>` and `--end-time <to>`.
4. Discover the dataset before filtering:

   ```bash
   axiom query "['<dataset>'] | getschema" --start-time "<from>" --end-time "<to>"
   axiom query "['<dataset>'] | take 5" --start-time "<from>" --end-time "<to>"
   ```

   For a field you intend to filter, first enumerate representative values with `distinct <field>` or `summarize count() by <field> | top 20 by count_`.
5. Query only fields and values that discovery confirmed. State the time window, dataset, query, and evidence separately from interpretation.

Use `--format json` when structured output makes aggregation or precise evidence easier; otherwise use the default table output.

## Boundaries

- Use the existing CLI profile without authentication flags or direct API calls.
- Keep queries observational: datasets, events, schema, and aggregations only.
- Never run ingestion, dataset administration, token management, alerting, or deployment commands.
- Treat log output as potentially sensitive. Prefer counts and redacted samples; never expose credentials or secret values.
