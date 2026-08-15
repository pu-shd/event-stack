# Compatibility

## Known-good sets

The table people actually need. Everything in a row was tested together.

| Set | eventkit | Applications | Form contract | Python | Drupal |
|---|---|---|---|---|---|
| **2026.1** | `v0.3.1` | `1.0.0` | `drupal-event-forms@2026.1` | 3.11–3.13 | 10.x + Webform 6.2 |

Pin the whole row. Mixing an application from one set with an eventkit from
another is not tested and the failure mode is a silent field mismatch, not an
import error.

## How applications pin eventkit

```
eventkit-core[app] @ https://github.com/pu-shd/eventkit/archive/refs/tags/v0.3.1.tar.gz
```

A codeload tarball, not `git+https`, because `python:3.11-slim` has no git and
every application Dockerfile would otherwise need `apt-get install git`.

**A tag is mutable**, and this code runs with Azure credentials in its
environment. Enable tag protection on eventkit, pin by commit SHA in CI, and use
`eventkit azure doctor --verify-self` to see what is actually running.

## Version skew

Bump every application's pin in one wave per eventkit release. The failure mode
of skew is nobody debugging a version mismatch at 8am on day one — which is
exactly when it would be discovered.

`eventkit` follows semantic versioning with one extra promise: **patch releases
may change `ui/static/**` and nothing else**, so a CSS fix does not force five
applications to re-test.

## The form contract

`drupal-event-forms` versions are `YYYY.N`. Each application's CI resolves the
contract at a pinned tag and asserts superset compatibility. A breaking rename
bumps the major and needs a pull request touching both repositories.

Support window: the last two contract versions.

## Upgrading

1. Read the eventkit CHANGELOG.
2. Bump one application's pin; run its suite; deploy it; watch it.
3. Bump the rest.
4. **Never during a registration window or in the week before the event.**

Migrations run at startup behind a file lock with a pre-migration snapshot. A
failed migration stops the application rather than leaving it running against a
schema it does not have.
