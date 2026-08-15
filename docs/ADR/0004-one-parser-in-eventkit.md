# ADR 0004 — One Drupal parser, in the library

**Status:** accepted

## Context

There were three near-identical parsers across two repositories, ~85% duplicated,
and they disagreed. Only one handled `webform_select_other`. Only one handled
`destination_url` and truthy coercion. Only one lowercased the email — in a
separate validator.

## Decision

`eventkit.drupal.parse_submission()` is the only parser, used by both the webhook
and the bulk importer, with a parity test asserting the two paths agree on the
same fixture.

## Why

Three parsers meant three behaviours for the same submission depending on which
door it came through. A registrant imported from a backup could get a different
name split than the same registrant arriving live.

Coercion primitives are total functions with no logging and no config, so they
are table-testable: composite emails, composite and bare names, select-other,
the truthy set, multi-value checkboxes.

## The embedded-default trap, removed

The old schema loader looked for a file in the repository root, then the working
directory, and shipped an embedded default. Since no file was ever shipped, the
embedded default — one specific event's field map — silently won for every
adopter.

There is now **no embedded default**. Resolution is explicit and logged once at
startup, and if nothing resolves the application **refuses to boot**, naming the
missing fields and printing a YAML stub. A wrong field map silently drops
registrations, which is worse than not booting.
