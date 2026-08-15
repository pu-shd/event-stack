# ADR 0007 — Alembic, not hand-rolled ALTER TABLE

**Status:** accepted

## Context

The predecessor had 341 lines of hand-written `ALTER TABLE` wrapped in
try/except, per repository.

## Decision

Alembic, with `render_as_batch=True` and an explicit naming convention, run from
`lifespan` behind a file lock with a pre-migration snapshot.

## Why

- **It failed silently.** Every ALTER ended at `logger.error(...)` and continued.
  A genuinely failed migration left the application running and believing the
  column existed; the first write then 500'd in the webhook path — a dropped
  registration. There was no version row, so "what schema is production on?" had
  no answer.
- **It could only add columns.** Two needed changes could not be expressed:
  rewriting check-in JSON keys from `"6/28"` to ISO dates, and adding
  `person_key` with a backfill.
- **It cost 341 lines per application and grew with every column.**

## The objection, and why it does not survive

"Alembic is too much for an event planner." Event planners never run
`alembic revision`; they run `deploy`. Migrations execute in-container at
startup. The only new artefact anyone sees is a `migrations/` directory they
never open.

## The escape hatch

`ensure_columns()` ships as a documented hotfix-only tool. It raises on failure
and logs loudly that it bypasses Alembic — so nobody re-invents the 240-line
version at 2am during a conference.
