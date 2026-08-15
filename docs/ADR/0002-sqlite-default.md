# ADR 0002 — SQLite on Azure Files by default, Postgres opt-in

**Status:** accepted

## Context

Each application needs a datastore. A Postgres Flexible Server per application
per event is roughly the cost of the compute again, times five.

## Decision

SQLite on the App Service `/home` mount by default. `--postgres` switches.

## Why

These are departmental applications: a handful of staff, single-digit writes per
minute, a few thousand rows. The reason to reach for Postgres is concurrent-write
safety, and in `lodging-planner` — the write-heaviest — that is solved by
optimistic concurrency with `row_version`, not by the engine.

## What it forces

- **`journal_mode=TRUNCATE`, not WAL.** WAL needs shared-memory mmap, which SMB
  does not provide. This is not tunable.
- **`synchronous=FULL`** — SMB reorders writes.
- **`busy_timeout=15000`** — SMB latency makes the 5s default fire constantly.
- **One instance, enforced.** `eventkit azure` pins the plan to one worker and
  refuses autoscale while the URL is SQLite. Two instances on one SQLite file
  over SMB is corruption, not slowness.
- **Backups become mandatory.** Postgres Flexible Server gives 7–35 days of
  automated backup free; `/home` gives nothing. "Free datastore" would otherwise
  quietly mean "no backups", which is exactly the failure mode being eliminated.
  The nightly job is not optional.

## Switch to Postgres when

More than about five simultaneous planners, point-in-time recovery is required,
or you need more than one instance for availability rather than throughput. CI
tests both.
