# Decisions

Why the stack is shaped the way it is — one paragraph each, so they are not
re-litigated. Change any of them deliberately, not by accident.

**Each application keeps its own database.** Different audiences need different
access (finance staff get reimbursement links without seeing revenue), different
lifetimes (the gallery outlives the reconciler by years), and one application
must not be able to take another down during registration week. The cost is
paid every time: a deletion request is a pass over five databases, and a
write-in added in one application does not appear in another.

**SQLite on Azure Files by default, Postgres opt-in.** These are departmental
tools — a handful of staff, single-digit writes per minute. Concurrent-write
safety in `lodging-planner` is solved by `row_version`, not by the engine. It
forces `journal_mode=TRUNCATE` (WAL needs shared-memory mmap, which SMB lacks),
one instance, and mandatory nightly backups, because `/home` has none of its
own. Switch to Postgres above ~5 simultaneous planners or when you need PITR.

**Polling, not WebSockets.** `GET /api/changes?since=` every three seconds while
the tab is focused. Correct on any number of instances with no sticky sessions,
and it survives the captive portals and proxies that conference wifi is made of.
A dropped connection cannot strand the front desk mid-registration.

**One Drupal parser, in the library.** `parse_submission()` serves both the
webhook and the bulk importer, with a parity test. There is no embedded default
field map — if none resolves, the application refuses to start, because a wrong
field map silently drops registrations.

**`link-forge` is separate and stateless.** Its audience is finance and event
staff, who should not thereby hold an authorization that exposes payment
amounts; and reimbursements arrive for weeks after the reconciler is gone. Not a
static page either: the tokenized links are bearer credentials that must not be
committed.

**One badge renderer.** ReportLab produces the PDF and the browser previews that
same PDF. Two definitions of the same geometry drift, and a long name printing
differently than previewed is what ruins a sheet of Avery stock.

**Alembic, not hand-rolled `ALTER TABLE`.** Migrations run at startup behind a
file lock with a pre-migration snapshot, and a failure stops the application
instead of leaving it running against a schema it does not have. Event planners
never run `alembic revision`; they run `deploy`.

**No JavaScript bundler.** Native ES modules, no `package.json` in any runtime
build; Node appears only in the Docker test stage. At this size the payload
difference is irrelevant, and being able to fix a typo in devtools during an
event is worth more. Third-party libraries are vendored with SRI rather than
loaded from a CDN.

**No third-party CI tooling.** Shell plus the platform vendors' own actions.
Secret scanning is `grep` over specific credential shapes, verified to fire on
planted secrets and stay quiet on `password = os.environ[...]`.
