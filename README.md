# event-stack

A reusable stack for running an academic conference: registration through
Drupal, tickets reconciled against Eventbrite, rooms assigned, badges printed,
posters published, per-person links issued.

It was extracted from two repositories that ran a real conference and were
edited live as its needs changed. This is that system, generalized, with the
bugs it shipped with written down rather than quietly fixed.

**You probably do not need all of it.** Start at
[CHOOSING-TOOLS.md](docs/CHOOSING-TOOLS.md).

---

## The repositories

| | |
|---|---|
| [`eventkit`](https://github.com/pu-shd/eventkit) | The shared library — Drupal parser, identity, auth, backup, migrations, UI kit — plus `eventkit azure`, the deployment toolkit |
| [`drupal-event-forms`](https://github.com/pu-shd/drupal-event-forms) | Webform exports, Remote Post recipes, the receipt email, field-map contracts |
| [`ticket-reconciler`](https://github.com/pu-shd/ticket-reconciler) | Drupal↔Eventbrite reconciliation, front-desk check-in, swag, waivers |
| [`lodging-planner`](https://github.com/pu-shd/lodging-planner) | Rooms, a drag-and-drop board, an advisory rules engine |
| [`nametag-press`](https://github.com/pu-shd/nametag-press) | Avery badge PDFs |
| [`link-forge`](https://github.com/pu-shd/link-forge) | Prefilled per-person links. Stateless |
| [`poster-gallery`](https://github.com/pu-shd/poster-gallery) | Public poster directory and RSS |

## Start here

| | |
|---|---|
| [CHOOSING-TOOLS.md](docs/CHOOSING-TOOLS.md) | Which of these you actually need. Read first |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | How it fits together, with diagrams |
| [RUNBOOK.md](docs/RUNBOOK.md) | What staff did, week by week, with a check per phase |
| [SECURITY-PRIVACY.md](docs/SECURITY-PRIVACY.md) | What is collected, who can reach it, how long it lives |
| [EVENT-PROFILE-SPEC.md](docs/EVENT-PROFILE-SPEC.md) | The one YAML every application reads |
| [COMPATIBILITY.md](docs/COMPATIBILITY.md) | Known-good version sets |
| [ALL-IN-ONE.md](docs/ALL-IN-ONE.md) | One container instead of five |
| [ADR/](docs/ADR/) | Eight decisions, so they are not re-litigated |

## Roughly thirty minutes to a working stack

```zsh
# 1. Write the event profile. Change every value.
cp examples/caarms-2026/event-profile.yaml event-profile.yaml
eventkit profile validate event-profile.yaml

# 2. Deploy each application you need. Idempotent and resumable; it pauses at
#    manual gates and polls until you have done them.
cd ticket-reconciler
eventkit azure deploy --event my-event-2027 --dry-run
eventkit azure deploy --event my-event-2027

# 3. Import the form, add one Remote Post handler per application.
#    https://github.com/pu-shd/drupal-event-forms/blob/main/docs/IMPORT.md

# 4. Check it.
./scripts/verify-stack.sh --event my-event-2027
```

`verify-stack.sh` asks four questions of every application: does `/healthz`
answer, is an anonymous request to an admin route refused, does a webhook with a
bad token get rejected, and does any public JSON contain an email address. It is
read-only, so it is safe against production — which is the only place worth
running it.

## What holds it together

`eventkit` is a **library, not a service**. No shared runtime, no shared
database, nothing to deploy centrally. It carries only what must agree across
applications: one Drupal parser, one identity function, one auth dependency, one
backup format.

Each application owns its database and registers its own Remote Post handler
with its own token. None depends on another at runtime — one being down cannot
stop a registration.

### The cost of independent databases

Stated here rather than discovered later: **the same person is a row in up to
four databases, and a deletion request is a pass over all of them** plus Drupal
plus the backups. Roommate references live in other people's rows. There is no
cascade and there will not be one, because a cascade across service boundaries
is the coupling the design exists to avoid.

The related cost: a write-in added at the lodging board on the day does not
appear in `nametag-press`. Print spares.

See [ADR 0001](docs/ADR/0001-independent-databases.md) for why this trade was
made anyway.

## Prerequisites

- **Drupal 10** with the Webform suite, including `webform_computed_twig` —
  which ships with it and is **not enabled by default**, and whose absence makes
  conditional ticketing fail silently in the direction of "everyone is exempt".
- **An Eventbrite team with API access**, only if you are selling tickets.
- **Azure**, if you want `eventkit azure` to do the deployment. Otherwise
  [one container](docs/ALL-IN-ONE.md) on any host.

Nothing else. No Kubernetes, no message broker, no bundler, no third-party CI
services.

## The reference event

[`examples/caarms-2026/`](examples/caarms-2026/) is a real conference's profile,
sanitized: the most complicated event this stack has run, with conditional
ticketing across five tiers, special lodging rules, and swag. It is a worked
example to read, not a template to run — change every value.

## Licence

Documentation [CC BY 4.0](LICENSE); `scripts/` MIT.
Copyright (c) 2026 The Trustees of Princeton University.
