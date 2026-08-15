# ADR 0003 — Polling, not WebSockets, for live updates

**Status:** accepted

## Context

The check-in desk needs two volunteers on two laptops to see each other's work.
The predecessor broadcast over WebSockets from a module-global list of sockets.

## Decision

`GET /api/changes?since=<cursor>` over a monotonic change log. Three seconds
while the tab is focused, thirty when blurred. WebSockets are opt-in and polling
remains the fallback.

## Why

The socket list was a module global. It broke the moment App Service ran two
instances or recycled the worker, and it swallowed every send error, so the
failure was silent — a desk that had quietly stopped updating.

Polling is correct on N instances with no sticky sessions, survives a dropped
connection without stranding anyone mid-registration, and survives the captive
portals and aggressive proxies that conference wifi is made of.

Three seconds is imperceptible for this. The desk is not a trading floor.

## Cost

A request every three seconds per open tab. For a dozen volunteers this is
nothing, and it is the cheapest possible thing to reason about at 8am on day
one when the network is misbehaving.
