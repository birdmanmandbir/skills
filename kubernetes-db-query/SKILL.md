---
name: kubernetes-db-query
description: Use when querying FlickNote prod or dev Postgres/Supabase databases through Kubernetes, especially with kubectl exec, psql, apps-prod, apps-dev, infra-prod, infra-dev, or supabase DB access.
---

# Kubernetes DB Query

Use this when the user asks to inspect FlickNote prod/dev database state.

## Rules

- Use existing Kubernetes database pods. Do not create temporary query pods.
- Do not read, print, decode, or copy database passwords or Kubernetes Secret values.
- Prefer `kubectl exec` into the Postgres pod and run `psql` there.
- Default to read-only SQL unless the user clearly asks for a write.
- For writes or deletes, show the exact target rows first when practical, then run the requested change.
- State which namespace, pod, database, and SQL shape you used. Do not include credentials.

## Environments

Known targets:

```bash
# prod
kubectl exec -n infra-prod flicknote-1 -c postgres -- psql -d supabase

# dev
kubectl exec -n infra-dev flicknote-1 -c postgres -- psql -d supabase
```

If the pod name may have changed, discover it first:

```bash
kubectl get pods -n infra-prod | rg '^flicknote-'
kubectl get pods -n infra-dev | rg '^flicknote-'
kubectl get pod -n infra-prod <pod> -o jsonpath='{.spec.containers[*].name}'
```

Use container `postgres` when present.

## Query Pattern

For one-off SQL:

```bash
kubectl exec -n infra-prod flicknote-1 -c postgres -- \
  psql -d supabase -v ON_ERROR_STOP=1 -P pager=off \
  -c "SELECT count(*) FROM public.notes;"
```

For multi-line SQL, pass heredoc content to `psql` without secrets:

```bash
kubectl exec -i -n infra-prod flicknote-1 -c postgres -- \
  psql -d supabase -v ON_ERROR_STOP=1 -P pager=off <<'SQL'
SELECT id, status
FROM public.notes
ORDER BY created_at DESC
LIMIT 10;
SQL
```

Switch `infra-prod` to `infra-dev` for dev.

## Safety Checks

Before writing:

```sql
SELECT ...
```

Then use a narrow `WHERE` clause, preferably by primary key:

```sql
BEGIN;
UPDATE public.some_table
SET ...
WHERE id = '...';
COMMIT;
```

If the result count is surprising, stop and report it instead of broadening the query.

## Common Mistakes

- Do not run `kubectl get secret ... -o yaml/json`.
- Do not create a `postgres` debug pod just to query DB.
- Do not use app pods for DB queries unless they already contain a suitable DB client and the database pod path is unavailable.
- Do not claim rows were changed or deleted without a fresh verification query.
