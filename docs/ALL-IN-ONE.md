# One container instead of five

Per-application *repositories* are right. Per-application *hosting* is not
mandatory, and for a one-week event it is usually the wrong trade.

Five Azure Web Apps means five things to patch, five deployments to watch, five
sets of application settings, and — even on a shared B1 plan — real money for
something that runs for three weeks a year.

## When to use this

- A single event, not a programme of them.
- Under a few hundred attendees.
- One person operating it.
- You are comfortable that everything shares a failure domain: if the container
  restarts, every tool blinks at once.

## When not to

- **The front desk is live.** During check-in, `ticket-reconciler` should not be
  able to be taken down by a badge render.
- **You want separate access lists per tool.** This is the big one. The reason
  `link-forge` is separate is that finance staff should not hold an
  authorization that also exposes gross revenue. One container behind one Easy
  Auth configuration gives everyone everything.
- **`poster-gallery` must outlive the event.** It can, but then it is not in
  this container.

If access separation matters to you, deploy `link-forge` and `poster-gallery`
separately and put the three staff-facing tools together. That is the middle
option and it is often the right one.

## The compose file

[`compose/docker-compose.all.yml`](../compose/docker-compose.all.yml) runs each
application as its own ASGI process in its own container, sharing one host, one
reverse proxy and one volume — **separate database files, one per application.**

Separate files, not a shared database: the applications genuinely do not know
about each other's tables, and merging them would fork the code. This is a
hosting change, not an architecture change.

```sh
cd compose
cp .env.example .env      # then edit it
docker compose -f docker-compose.all.yml up -d
```

Then put a reverse proxy in front, terminating TLS and providing
authentication — Caddy with your identity provider, or nginx behind your
institution's SSO. **There is no Easy Auth here**, so authentication is entirely
your proxy's job. Getting that wrong publishes the admin tools; check it with:

```sh
../scripts/verify-stack.sh --url https://your-host
```

## What you give up

| | Five Web Apps | One host |
|---|---|---|
| Per-tool access lists | yes | no — one proxy, one policy |
| Independent restart | yes | no |
| Independent teardown | yes | no |
| Managed TLS and identity | Azure does it | you do it |
| Automatic backups | the shipped workflow | your cron |
| Cost | a plan plus five apps | one VM |

The backup point matters most. The nightly workflow assumes Azure. On your own
host, write the cron job before you open registration, and restore from it once
to prove it works.

## Volumes

Databases live on a named volume, one file per application. Back up the volume
*and* pull each application's own `/api/admin/db-backup`, because the second is
portable between engines and the first is not.
