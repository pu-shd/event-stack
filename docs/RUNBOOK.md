# Runbook

What staff actually did, in order, with the route used and a way to tell whether
it worked. Timings are relative to the first day of the event.

Every phase has a "how you know" check. Skip those and you find out at the desk.

---

## T-10 weeks — decide and provision

**Owner:** whoever runs the event's IT.

1. Pick your applications. [CHOOSING-TOOLS.md](CHOOSING-TOOLS.md). You probably
   do not need all five.
2. Write the event profile. Start from `examples/caarms-2026/event-profile.yaml`
   and change every value in it.
   ```sh
   eventkit profile validate event-profile.yaml
   ```
3. Deploy, one application at a time:
   ```zsh
   eventkit azure deploy --event my-event-2027 --dry-run
   eventkit azure deploy --event my-event-2027
   ```
   It stops at manual gates — the Entra ID identity provider, a DNS record, an
   Eventbrite token — and polls until you have done each. `[q]uit` and
   `eventkit azure resume` picks up where you left off.

**How you know:** `scripts/verify-stack.sh` passes. `/healthz` answers on each
application, an anonymous request to an admin route is refused, and no `@`
appears in any public JSON.

---

## T-9 weeks — build the form

**Owner:** the Drupal administrator, with the organizers in the room for step 1.

1. **Draw the ticketing table on paper first, with the organizers.** Who pays
   what, who is exempt, who must never be sent to the vendor. This is a policy
   decision and it is much cheaper to argue about a table than about Twig.
   See [conditional ticketing](https://github.com/pu-shd/drupal-event-forms/blob/main/docs/CONDITIONAL-TICKETING.md).
2. Import the form: Webform UI → Build → **Source**, paste, save.
   [IMPORT.md](https://github.com/pu-shd/drupal-event-forms/blob/main/docs/IMPORT.md).
   `drush webform:import` does **not** do this — it imports submissions.
3. `drush en webform_computed_twig`. It is not enabled by default, and without
   it the ticket slug is empty for everyone, which reads downstream as *exempt*.
4. Add one Remote Post handler per application. Mind the `headers:` nesting; a
   flat key is ignored and every call 403s while the registrant sees success.

**How you know:** submit one test registration, then on each application check
`GET /api/webhook/status` — `authenticated_total` above zero, `rejected_total`
at zero, `unmapped_keys` empty. Confirm `uuid` is in the payload; it is the join
key everything else rests on and the production export does not define it as an
element.

Then walk every row of your ticketing table with a real submission, **including
a Speaker**, who must produce no slug at all. An invited speaker being asked to
pay is the failure everybody remembers.

---

## T-8 weeks — registration opens

**Owner:** organizers, with IT on call for the first 48 hours.

The first two days produce most of the surprises. Watch the reconciler's report
daily.

**How you know:** registrations appear in every application within seconds of
submission, not just in Drupal.

---

## T-8 to T-3 weeks — triage weekly

**Owner:** whoever owns the budget.

Each week, in `ticket-reconciler`:

- **`Unmatched`** — a payment with no registration, or a registration whose
  payment did not match on email. Usually someone paid with a different address.
  Link them by hand; the report will not double-claim a manually linked payment.
- **`Pending`** — registered, no payment. Chase these. They are the people who
  turn up at the desk expecting to be on the list.
- **`Exempt`** — verify a few. An exemption granted by an empty computed field
  rather than by policy is the failure mode of conditional ticketing.

**How you know:** `Pending` trends down. If it is flat for two weeks the chase
emails are not landing.

---

## T-3 weeks — rooms

**Owner:** the lodging planner. Only if you are housing people.

1. Bulk-create rooms. Zero-padded names auto-increment correctly: `Room 007`
   becomes `Room 008`.
2. Assign by dragging. The rules panel flags conflicts as you go —
   over-capacity, a gender-constrained room violated, a one-sided roommate
   request, a roommate who never registered.
3. Findings are advisory. Where a warning is intended — a couple sharing a
   mixed-gender room — record a waiver with a justification rather than living
   with a permanent warning. An always-red panel is one nobody reads.

**How you know:** the rules panel is clean or every remaining finding has a
waiver. Two planners can work simultaneously: a stale drag gets a 409 and a
reload prompt rather than silently overwriting.

---

## T-5 days — freeze assignments

Late changes are handled at the desk, not on the board. Anything after this
point will not reach the printed badges.

---

## T-1 day — print badges

**Owner:** whoever is standing at the printer.

1. **Print one blank sheet on plain paper first** and hold it against a real
   Avery sheet, up to the light. Printer margins drift. This costs one sheet and
   saves a box.
2. Print by role so the colours batch.
3. **Print spares.** Walk-ins happen, and a write-in added in `lodging-planner`
   today does *not* appear in `nametag-press` — separate databases, on purpose.

**How you know:** the calibration sheet lines up. There is one renderer, so the
preview is the PDF is the print.

---

## Day 0 — the desk

**Owner:** front-desk volunteers, briefed for ten minutes beforehand.

- Check people in per day key. Repeated clicks cycle
  unrecorded → checked in → unsure → absent.
- Issue swag; sizes come from registration, replacements are recorded.
- Waivers signed on the spot, with a justification.

**How you know:** the check-in count matches the queue. The desk view polls
every three seconds, so two volunteers on two laptops see each other's work —
and it keeps working on conference wifi, which is why it polls rather than
holding a socket open.

**If the venue's network fails:** everything is server-side, so a phone hotspot
on one laptop is a working desk. There is no offline mode.

---

## T+1 day to T+2 weeks — afterwards

1. **Send the links.** Reimbursement and media release, from `link-forge`. One
   at a time; a rendered link carries the recipient's details.
2. **Refund overrides** for no-shows who are owed one.
3. **Pull final backups from every application** and verify one actually
   restores into a scratch instance. A backup nobody has restored is a hypothesis.
4. **Delete the sensitive lodging fields at T+30.** Gender identity, roommate
   preference, identified roommate. See
   [SECURITY-PRIVACY.md](SECURITY-PRIVACY.md).
5. **Tear down** — but not `poster-gallery`, which is the public record, and not
   `link-forge`, because reimbursements arrive for weeks.
   ```zsh
   eventkit azure teardown --app ticket-reconciler
   ```
   It requires the resource group name typed exactly, because the group holds
   every application for the event.

**How you know:** the storage account still has the backups — it lives outside
the event's resource group precisely so teardown cannot take them.

---

## Things that went wrong, so you can watch for them

| Symptom | Cause |
|---|---|
| Everyone appears exempt | `webform_computed_twig` not enabled |
| Every webhook 403s, registrants see success | `headers:` not nested in the handler's custom options |
| A column is silently empty | An element renamed in Drupal. `unmapped_keys` at `/api/webhook/status` names it |
| Admin sign-in returns 500, nothing changed | The Easy Auth client secret expired. `eventkit azure secrets rotate` |
| Two planners overwrite each other | Cannot happen — 409 and a reload prompt |
| A long name prints differently than previewed | Cannot happen — one renderer |
