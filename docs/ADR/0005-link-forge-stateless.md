# ADR 0005 — link-forge is its own stateless application

**Status:** accepted

## Context

Prefilled per-person links — reimbursement, media release, slide upload,
tokenized prefill — could have been a route inside `ticket-reconciler`, which
already holds the roster.

## Decision

Its own repository, its own deployment, no database.

## Why

- **Different audience.** Event and finance staff need these links. They must
  not thereby hold an authorization that also exposes payment amounts and gross
  revenue.
- **Different lifetime.** Reimbursements arrive for weeks after the reconciler
  has been torn down.
- **No schema.** Bolting a stateless tool onto a migration-bearing application
  taxes it forever.

## Why not a static page

The tokenized speaker links are bearer credentials. Baking them into a committed
HTML file is precisely the mistake that leaked nine live ones. The tokens live
in an environment variable or Key Vault, in memory, rendered one at a time behind
authentication, logged as a kind plus a hash prefix — never as a URL.

It also **refuses** to render a bearer link for someone with no token, rather
than emitting a broken one.
