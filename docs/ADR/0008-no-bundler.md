# ADR 0008 — No JavaScript bundler

**Status:** accepted

## Context

Roughly 2–3k lines of shared browser JavaScript across five applications.

## Decision

Native ES modules, served directly. No bundler, no `package.json` in any runtime
build. Node appears only as a test dependency (vitest + jsdom) confined to the
Docker `test` stage.

## Why

A bundler means five repositories need `package.json` and `node_modules` in
their Docker build, for no measured benefit at this size over HTTP/2 to a few
dozen authenticated staff.

The zero-build reality has a real operational value: an IT specialist can open
devtools during an event, find the typo, and fix it in the served file. That is
worth more here than a smaller payload.

## What is not negotiable

**Vendor third-party libraries with subresource integrity.** SheetJS and MathJax
were unpinned CDN scripts: a CDN outage took out the export button and rendered
every abstract as raw LaTeX. The QR encoder is vendored too — the predecessor
sent attendee purchase URLs, *including the live discount code*, to a third-party
QR service on every render, and stopped working entirely on captive-portal wifi.
