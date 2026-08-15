# Contributing

This file is canonical here and **copied** into each repository in the stack —
GitHub renders only the local file, so a link would not be read. A CI check
catches drift between the copies.

## The hard rule

**No pull request may add a real attendee record, a webhook token, a speaker
prefill token, a discount code, or a real email address to a fixture, a test, a
document or an example.**

Use `example.edu`. Use `${WEBHOOK_TOKEN}`. Use `<your-app>.azurewebsites.net`.

`drupal-event-forms` enforces this with `tools/redact.py`; the other
repositories enforce the same shapes in their hygiene job. If a check blocks you
and you believe it is wrong, say so in the pull request rather than adding an
exclusion.

## No event-specific values in code

If it names a date, a role, a price, a size, a colour or an institution, it
belongs in the event profile, not in a module. This is the whole reason the
extraction happened; every regression is one hardcoded value someone was in a
hurry about.

## No third-party CI tooling

Shell commands, plus the platform vendors' own actions — `actions/*` from
GitHub, `azure/login` from Microsoft. No marketplace actions, no third-party
scanners. Each is another dependency to trust in the path that produces a
shipped artifact.

Secret scanning is `grep` over specific credential shapes. When you add a
pattern, prove it fires on a planted secret **and** stays quiet on
`password = os.environ[...]`.

## Tests

- `docker-compose run --rm test` must be green. It is the same command CI runs.
- **A new guard needs a test that watches it reject.** A validator nobody has
  seen fail is a validator nobody knows is wired up.
- A bug fix gets a regression test reproducing the original input — ideally the
  original data, as the `drupal-event-forms` fixtures do.

## Commits and pull requests

- Sign off (`git commit -s`).
- Explain *why* in the body. The what is in the diff.
- One logical change per pull request.

## Reporting a security problem

Do not open a public issue. See `SECURITY.md`.
