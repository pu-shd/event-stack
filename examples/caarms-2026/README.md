# caarms-2026 — the reference event

The most complicated event this stack has run, sanitized. A worked example to
read, not a template to run: change every value in it.

- **Four days**, with a banquet as a separate check-in key.
- **Conditional ticketing across five tiers**, from $160 general admission down
  to $0 for partner-institution students, decided by a cascade the form
  evaluates as you fill it in.
- **Special lodging rules** — non-affiliate students only, with same-gender
  requirements, roommate requests, and an advisory rules engine.
- **T-shirt swag** with a seven-value vocabulary and inventory.
- **Posters**, published publicly with LaTeX abstracts.

## What was changed for publication

- Real addresses replaced with `example.edu`. `event.contact_email` is public by
  design and is the only address in the file.
- No tokens of any kind. Discount codes are referenced by environment variable
  *name*; the tiers hold `discount_code_env`, never a code.
- No live application hostnames.

## What was deliberately kept

The event name, dates, the tier structure, the swag vocabulary, the lodging
rules. Stripping those would leave an empty shape that teaches nothing about how
the pieces fit — and the discount codes visible in the Drupal form are
semi-public anyway, since the browser receives the computed value.

## Files

| | |
|---|---|
| `event-profile.yaml` | The profile every application reads |
| `webform-schema.yml` | The Drupal element schema the field map resolves against |

```sh
eventkit profile validate event-profile.yaml
eventkit profile public event-profile.yaml
eventkit fieldmap check event-profile.yaml
```
