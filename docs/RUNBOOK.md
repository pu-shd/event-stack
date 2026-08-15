# Runbook

Timings are relative to day one. Every phase has a way to tell whether it
worked; skip those and you find out at the desk.

## T-10 weeks — provision

```zsh
cp examples/caarms-2026/event-profile.yaml event-profile.yaml   # change every value
eventkit profile validate event-profile.yaml

cd ../ticket-reconciler
eventkit azure deploy --event my-event-2027 --dry-run
eventkit azure deploy --event my-event-2027
```

Repeat per application. It pauses at manual steps — the Entra identity provider,
a DNS record, an Eventbrite token — and polls until you have done them. `[q]` and
`eventkit azure resume` picks up where you left off.

**Check:** `./scripts/verify-stack.sh --event my-event-2027` passes.

## T-9 weeks — build the form

1. **Draw the ticketing table on paper, with the organizers.** Who pays what,
   who is exempt, who must never reach the vendor. Cheaper to argue about a
   table than about Twig.
2. Import: Webform UI → Build → **Source**, paste, save.
   `drush webform:import` does *not* do this.
3. `drush en webform_computed_twig` — not enabled by default, and without it the
   ticket slug is empty for everyone, which reads downstream as *exempt*.
4. Add one Remote Post handler per application. Mind the `headers:` nesting.

**Check:** submit one test registration. On each application,
`GET /api/webhook/status` shows `authenticated_total > 0`, `rejected_total` at
zero, `unmapped_keys` empty, and `uuid` present in the payload. Then walk every
row of your ticketing table — **including a Speaker, who must produce no slug**.

→ [drupal-event-forms](https://github.com/pu-shd/drupal-event-forms)

## T-8 weeks — registration opens

Watch the reconciliation report daily for the first 48 hours.

**Check:** registrations appear in every application within seconds, not just in
Drupal.

## Weekly — triage

In `ticket-reconciler`:

- **`Unmatched`** — a payment with no registration, usually a different email.
  Link by hand.
- **`Pending`** — registered, unpaid. Chase them; they are the people who turn
  up expecting to be on the list.
- **`Exempt`** — spot-check a few. An exemption granted by an empty computed
  field rather than by policy is the failure mode of conditional ticketing.

**Check:** `Pending` trends down. Flat for two weeks means the chase emails are
not landing.

## T-3 weeks — rooms

Bulk-create, then drag. The rules panel flags over-capacity, gender mismatches,
one-sided and unregistered roommate requests as you go. Where a warning is
intended, record a waiver with a justification rather than living with it.

**Check:** the panel is clean or every finding is waived. Two planners can work
at once — a stale drag gets a 409 and a reload prompt.

## T-5 days — freeze

Later changes are handled at the desk. Nothing after this reaches the printed
badges.

## T-1 day — print

1. **Print one blank sheet on plain paper** and hold it against a real Avery
   sheet, up to the light. One sheet; it saves a box.
2. Print by role so colours batch.
3. **Print spares.** A write-in added in `lodging-planner` today does not appear
   in `nametag-press`.

**Check:** the calibration sheet lines up.

## Day 0 — the desk

Check people in per day key; repeated clicks cycle unrecorded → checked in →
unsure → absent. Issue swag. Waivers signed on the spot with a justification.

**Check:** the count matches the queue. The desk polls every three seconds, so
two volunteers see each other's work — and it keeps working on conference wifi.

If the venue network fails, a phone hotspot on one laptop is a working desk.
There is no offline mode.

## Afterwards

1. Send reimbursement and media-release links from `link-forge`, one at a time.
2. Process refund overrides.
3. **Pull final backups and restore one into a scratch instance.** A backup
   nobody has restored is a hypothesis.
4. **T+30: delete gender identity, roommate preference and identified
   roommate**, including from the final backup.
5. Tear down — but not `poster-gallery` (the public record) or `link-forge`
   (reimbursements arrive for weeks).

```zsh
eventkit azure teardown --app ticket-reconciler
```

**Check:** the backup storage account still has the backups. It lives outside
the event's resource group precisely so teardown cannot take them.

## Things that go wrong

| Symptom | Cause |
|---|---|
| Everyone appears exempt | `webform_computed_twig` not enabled |
| Every webhook 403s, registrants see success | `headers:` not nested in the handler |
| A column is silently empty | An element was renamed; `unmapped_keys` names it |
| Admin sign-in returns 500, nothing changed | Easy Auth client secret expired |
