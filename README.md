# event-stack

A reusable stack for running an academic conference: registration through
Drupal, tickets reconciled against Eventbrite, rooms assigned, badges printed,
posters published, per-person links issued.

**You probably do not need all of it.** Start at
[CHOOSING-TOOLS](docs/CHOOSING-TOOLS.md).

## Thirty minutes to a working stack

```zsh
# 1. Write the event profile. Change every value in it.
cp examples/caarms-2026/event-profile.yaml event-profile.yaml
eventkit profile validate event-profile.yaml

# 2. Deploy what you need, one application at a time.
cd ticket-reconciler
eventkit azure deploy --event my-event-2027 --dry-run
eventkit azure deploy --event my-event-2027

# 3. Import the Drupal form; add one Remote Post handler per application.
#    https://github.com/pu-shd/drupal-event-forms

# 4. Check it.
./scripts/verify-stack.sh --event my-event-2027
```

Deployment is idempotent and resumable. It pauses at steps it cannot do for you —
the Entra identity provider, a DNS record, an Eventbrite token — and polls until
you have done them.

## The repositories

| | |
|---|---|
| [`eventkit`](https://github.com/pu-shd/eventkit) | Shared library and the `eventkit azure` deployment toolkit |
| [`drupal-event-forms`](https://github.com/pu-shd/drupal-event-forms) | Webform exports, handler recipes, field-map contracts |
| [`ticket-reconciler`](https://github.com/pu-shd/ticket-reconciler) | Eventbrite reconciliation, check-in, swag, waivers |
| [`lodging-planner`](https://github.com/pu-shd/lodging-planner) | Rooms, assignment board, rules engine |
| [`nametag-press`](https://github.com/pu-shd/nametag-press) | Avery badge PDFs |
| [`link-forge`](https://github.com/pu-shd/link-forge) | Prefilled per-person links. Stateless |
| [`poster-gallery`](https://github.com/pu-shd/poster-gallery) | Public poster directory and RSS |

## Documentation

| | |
|---|---|
| [CHOOSING-TOOLS](docs/CHOOSING-TOOLS.md) | Which applications you need |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | How it fits together |
| [RUNBOOK](docs/RUNBOOK.md) | Week by week, with a check per phase |
| [SECURITY-PRIVACY](docs/SECURITY-PRIVACY.md) | What is collected, who reaches it, how long it lives |
| [EVENT-PROFILE-SPEC](docs/EVENT-PROFILE-SPEC.md) | The one YAML every application reads |
| [COMPATIBILITY](docs/COMPATIBILITY.md) | Known-good version sets |
| [ALL-IN-ONE](docs/ALL-IN-ONE.md) | One container instead of five |
| [DECISIONS](docs/DECISIONS.md) | Why it is shaped this way |

## Scripts

```zsh
./scripts/verify-stack.sh --event my-event-2027
```

Asks four read-only questions of every application: does `/healthz` answer, is
an anonymous request to an admin route refused, does a webhook with a bad token
get rejected, does any public JSON contain an email address.

```zsh
./scripts/whois-person.sh --email someone@example.edu backups/*.json
```

Finds one person across every application's backups, separating their own
records from places where they are named in somebody else's — which is what
makes a deletion request executable.

## How it fits together

One Drupal webform is the only place a registrant types anything. Each
application subscribes to it independently with its own Remote Post handler and
its own token, and keeps its own database. None depends on another at runtime,
so one being down cannot stop a registration.

`eventkit` is a library, not a service: no shared runtime, nothing to deploy
centrally. It carries only what must agree — one parser, one identity function,
one auth dependency, one backup format.

**The cost:** the same person is a row in up to four databases, so a deletion
request is a pass over all of them plus Drupal plus the backups, and a write-in
added in one application does not appear in another. See
[DECISIONS](docs/DECISIONS.md).

## Prerequisites

- **Drupal 10** with the Webform suite, including `webform_computed_twig` —
  which ships with it, is **not enabled by default**, and whose absence makes
  conditional ticketing fail silently toward "everyone is exempt".
- **An Eventbrite team with API access**, only if you sell tickets.
- **Azure**, or [one container](docs/ALL-IN-ONE.md) on any host.

## The reference event

[`examples/caarms-2026/`](examples/caarms-2026/) is a real conference's profile,
sanitized: conditional ticketing across five tiers, lodging rules, swag. Read it
as a worked example; change every value.

## Licence

Documentation [CC BY 4.0](LICENSE); `scripts/` MIT.
Copyright (c) 2026 The Trustees of Princeton University.
