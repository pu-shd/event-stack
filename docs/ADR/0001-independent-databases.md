# ADR 0001 — Each application keeps its own database

**Status:** accepted

## Context

Five applications need overlapping views of the same people. The predecessors
used two shared databases: `nametag-press` and `lodging-planner` read the same
`Registrant` table, and both were in one deployment with one failure domain.

## Decision

Every application owns its database. Nothing reads another's tables. The same
person is a row in up to four of them, joined on `person_key`.

## Why

- **Different audiences need different access.** Finance staff need
  reimbursement links; they must not thereby see gross revenue. A shared
  database makes that a query-level problem instead of a deployment-level one.
- **Different lifetimes.** `poster-gallery` outlives the event by years,
  `ticket-reconciler` by two weeks. A shared database cannot be torn down at
  two different times.
- **Different sensitivity.** Gender identity reaches exactly one application.
  In a shared schema it reaches everything.
- **One application cannot take another down.** During registration week that
  matters more than the duplication costs.

## Cost, paid every time

**A deletion request is a pass over five databases** — four applications plus
Drupal, and the backups. Roommate references live in *other people's* rows.
There is no cascade and there will not be one; a cascade across service
boundaries is the coupling this decision exists to avoid.

Mitigated by: `person_key` making each step a lookup rather than a search, an
`identity-drift` command per application, and this being written down here
rather than discovered by whoever fields the first request.

**Write-ins do not propagate.** Someone added at the lodging board on the day
does not appear in `nametag-press`. Print spares.
