# The event profile

One validated YAML per event. Every application reads it; none of them hardcodes
a date, a role, a size vocabulary or a colour. It is the de-eventing layer — the
thing that turns "the code that ran our conference" into "code that runs a
conference".

```sh
eventkit profile validate event-profile.yaml
eventkit profile public event-profile.yaml        # what the browser is served
eventkit profile checkin-keys event-profile.yaml
```

Start from [`../examples/caarms-2026/event-profile.yaml`](../examples/caarms-2026/event-profile.yaml)
and change every value in it.

## Where it comes from

Resolution order, decided once at startup and logged:

1. the path in `EVENT_PROFILE`
2. `./event-profile.yaml`
3. `/home/site/event-profile.yaml` — the Azure Files mount

If nothing resolves, the application **refuses to start**, naming what it needed.
That is deliberate: a missing profile means a wrong field map, and a wrong field
map silently drops registrations, which is worse than not booting.

`eventkit azure deploy` sets `EVENT_PROFILE=/home/site/event-profile.yaml`, so
the profile is uploaded once per event and shared by every application.

## Sections

| Section | Holds | Read by |
|---|---|---|
| `event` | name, short name, year, slug, URLs, contact | all |
| `schedule` | timezone, dates, **check-in day keys as ISO dates** | reconciler |
| `branding` | site name, theme, one brand hex, logos | all |
| `drupal` | `field_map` or `webform_schema`, and the join key | all |
| `roles` | the attendee-status vocabulary, labels, colours | reconciler, nametags |
| `affiliation` | placeholder values and `domain_map` | reconciler, nametags, gallery |
| `ticketing` | vendor, tiers, **discount code env var names**, status order | reconciler |
| `swag` | the size vocabulary | reconciler |
| `lodging` | vocabularies and per-rule severity | lodging |
| `nametags` | Avery template, what to show | nametags |
| `notify` | transport, recipients, which events | reconciler |
| `links` | per-person link templates | link-forge |

**Per-application validation.** Each application declares which sections it
needs and fails on *its* missing keys only, so adding a lodging vocabulary
cannot break `nametag-press` startup.

## Three rules worth stating

**Check-in day keys are ISO dates.** The predecessor used `"6/28"`, `"7/1"`,
`"banquet"` — year-less keys that collide between events and are ambiguous
across locales. `"7/1"` and `"07/01"` both appeared in the same database. Keys
are `2027-06-28`, and a named event is `2027-06-30-banquet`.

**Discount codes are referenced by environment variable name, never by value.**
A tier declares `discount_code_env: EVENTBRITE_DISCOUNT_GENERAL`. eventkit
rejects a value shaped like a pasted code — the validator specifically catches
`isupper() and isalnum()` strings, because that is exactly what a real code looks
like and this is the one field whose whole purpose is to not hold one.

**One brand colour.** `branding.brand_color` drives a derived ramp. An adopter
sets one hex and gets a coherent look. The predecessor had two oranges
disagreeing across roughly forty inline `style=` attributes.

## The public projection

`GET /api/event-profile` serves a filtered view: everything except notification
recipients, field-map internals, and the discount env var names. A trip-wire
test fails if the public projection ever gains a field outside an explicit
allow-list, because the original leak of that shape was one careless
`response_model` reuse.

## Changing it mid-event

Safe: labels, colours, notification recipients, adding a link kind.

**Not safe:** the field map, `drupal.join_key`, check-in day keys, or swag keys —
these are written into rows. Changing `join_key` orphans every record in every
database.
