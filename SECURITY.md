# Reporting a security problem

**Do not open a public issue.**

Email the maintainers, or use GitHub's private vulnerability reporting on any
repository in the stack.

Please include: which repository, what an attacker can do, and how to reproduce
it. If it involves a live deployment, say so — a token may need rotating before
a fix ships, and [rotating a webhook token has a gap during which submissions
are lost](docs/SECURITY-PRIVACY.md#webhook-tokens), so the timing matters.

## The rule that keeps this repository publishable

No commit may add a real attendee record, a webhook token, a speaker prefill
token, a discount code, or a real email address — to code, a fixture, a
document or an example. Use `example.edu`, `${WEBHOOK_TOKEN}`, and
`<your-app>.azurewebsites.net`.

`drupal-event-forms` enforces this with `tools/redact.py`; the other
repositories check the same shapes in their hygiene job. If a check blocks you
and you think it is wrong, say so in the pull request rather than adding an
exclusion.

## What is in scope

Anything that lets someone read attendee data, write to an application without a
valid token, reach an admin route without being on the allow-list, or escalate
from a Drupal account to an application.

## What is known and documented

These are stated in [SECURITY-PRIVACY.md](docs/SECURITY-PRIVACY.md) rather than
being surprises:

- **Any Drupal administrator can read every webhook token.** They are handler
  configuration in plain text. This is the real trust boundary.
- **Discount codes are semi-public.** The browser receives the computed value.
- **A backup download is a full personal-data export.** By design; the route is
  behind authentication and restore is off by default.
- **Prefill tokens are bearer credentials in URLs**, and therefore in logs.

Reports on these are welcome as improvements, but they are not unknown.
