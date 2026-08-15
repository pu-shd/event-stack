# Choosing tools

## You do not need all five

Most events need one or two. Each application you run is money, a thing to
patch, a database of personal data you did not have to collect, and a deletion
request to service later.

## Which do I need?

**Are you selling tickets, or is any part of attendance conditional on payment
or exemption?**
→ [`ticket-reconciler`](https://github.com/pu-shd/ticket-reconciler).
This is the one with the most in it: reconciliation against Eventbrite,
front-desk check-in, swag, waivers, refund overrides. If nobody pays, skip it.

**Are you housing attendees, deciding who shares a room?**
→ [`lodging-planner`](https://github.com/pu-shd/lodging-planner).
Only if you are making the assignments. If a hotel block handles it and
attendees book themselves, you do not need this — and you should not be
collecting roommate preferences or gender identity at all.

**Are you printing name badges?**
→ [`nametag-press`](https://github.com/pu-shd/nametag-press).
Worth it above roughly fifty people, or whenever you would otherwise be
hand-fixing a mail merge the evening before.

**Do people need per-person prefilled links — reimbursement forms, media
releases, upload links?**
→ [`link-forge`](https://github.com/pu-shd/link-forge).
The cheapest thing here: no database, nothing to back up, nothing to migrate.
Also the one that outlives the event, because reimbursements arrive for weeks.

**Do you want a public directory of posters or talks?**
→ [`poster-gallery`](https://github.com/pu-shd/poster-gallery).
The only public-facing application. It also stays up after the event as the
record of who presented what.

**None of the above?** Use the Drupal forms and a spreadsheet. That is a real
answer. The stack exists because a spreadsheet stopped working at a particular
scale, not because spreadsheets are wrong.

---

## Three bundles that come up

### Minimal — `link-forge` only

A workshop with no tickets, no housing, no badges. You want to send forty people
their reimbursement link without pasting forty URLs by hand.

One container, no database, no backups, no migrations. Deploy it in an
afternoon; leave it running for two months afterwards.

### Symposium — `ticket-reconciler` + `nametag-press`

A one-day event with paid registration and a check-in desk. You need to know who
paid, and you need badges.

Two applications, two databases, one shared App Service plan. Both torn down a
week after.

### Conference — all five

Multi-day, housed attendees, posters, conditional pricing across several
categories. This is what the reference event ran, and it is the configuration
the stack was extracted from.

Expect: five databases, one deletion request that is a five-database operation,
and a nightly backup job you must actually verify restores.

---

## What every option needs

Whatever you pick:

- **A Drupal 10 site with the Webform suite**, which is where registrations come
  from. See [`drupal-event-forms`](https://github.com/pu-shd/drupal-event-forms).
- **An event profile** — one validated YAML holding your dates, roles, tiers,
  vocabularies and branding. Every application reads it. See
  [`EVENT-PROFILE-SPEC.md`](EVENT-PROFILE-SPEC.md).
- **Somewhere to run a container.** Azure App Service is what `eventkit azure`
  automates, but see [the all-in-one option](ALL-IN-ONE.md) — five Azure Web Apps
  for a one-week event is real money and five things to patch.

Only `ticket-reconciler` needs Eventbrite. Only `lodging-planner` and
`ticket-reconciler` hold anything you would call sensitive.

---

## Adding one later

Applications do not depend on each other. Adding `nametag-press` three weeks in
is: deploy it, add a handler, and import what arrived before it existed —

```sh
python -m nametag_press.cli import <backup-from-another-app.json>
```

— because every application reads the same unified backup format.

The cost: a write-in added in one application does not appear in another.
