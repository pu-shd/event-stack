#!/bin/zsh
#
# whois-person.sh — find one person across every application's data.
#
# The independent-database design means the same person is a row in up to four
# databases, joined on person_key. SECURITY-PRIVACY.md says a deletion request is
# a pass over all of them; this is the tool that makes that pass executable
# instead of aspirational.
#
# It reads **backup exports**, not live databases. That is deliberate:
#
#   * it needs no credentials and no network, so it is safe to run on a laptop;
#   * every application produces the same format from /api/admin/db-backup, so
#     one tool covers all of them and keeps working after an application is torn
#     down and only its final backup survives;
#   * and it cannot accidentally modify anything, which matters for a tool whose
#     output is used to decide what to delete.
#
#   ./whois-person.sh --email ada@example.edu backups/*.json
#   ./whois-person.sh --name "Lovelace" --json backups/*.json
#
# Exit 0 if the person was found somewhere, 1 if not found, 2 on usage error.

set -o pipefail

typeset -g QUERY="" MODE="" AS_JSON=0
typeset -ga FILES=()

usage() {
  print -r -- "usage: whois-person.sh (--email ADDR | --name TEXT | --key PERSON_KEY) [--json] FILE..."
  print -r -- ""
  print -r -- "  --email ADDR   exact match, case-insensitive"
  print -r -- "  --name  TEXT   substring of first or last name, case-insensitive"
  print -r -- "  --key   KEY    exact person_key"
  print -r -- "  --json         machine-readable output"
  print -r -- ""
  print -r -- "FILE... are backup exports (GET /api/admin/db-backup, or the"
  print -r -- "*-export.json files a teardown backup leaves behind)."
}

while (( $# )); do
  case "$1" in
    --email) shift; QUERY="$1"; MODE=email ;;
    --name)  shift; QUERY="$1"; MODE=name ;;
    --key)   shift; QUERY="$1"; MODE=key ;;
    --json)  AS_JSON=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) print -r -- "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) FILES+=("$1") ;;
  esac
  shift
done

[[ -n "$MODE" ]] || { print -r -- "One of --email, --name or --key is required." >&2; usage >&2; exit 2 }
(( ${#FILES} )) || { print -r -- "No backup files given." >&2; usage >&2; exit 2 }

python3 - "$MODE" "$QUERY" "$AS_JSON" "${FILES[@]}" <<'PY'
import json
import sys

mode, query, as_json = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
paths = sys.argv[4:]
needle = query.strip().lower()

# Fields that identify a person. Deliberately explicit rather than "any field
# containing an @": a roommate request holds somebody *else's* name, and finding
# those is the point — but they must be reported as a reference, not as the
# person's own record.
EMAIL_FIELDS = ("email_address", "email", "mail")
NAME_FIELDS = ("first_name", "last_name", "full_name", "name")
KEY_FIELDS = ("person_key", "drupal_uuid", "uuid")
# A hit in one of these means somebody else's row mentions this person.
REFERENCE_FIELDS = ("identified_roommate", "roommate", "faculty_adviser_name")


def values(row, fields):
    for f in fields:
        v = row.get(f)
        if v not in (None, ""):
            yield f, str(v)


def matches(row):
    if mode == "email":
        return any(v.lower() == needle for _, v in values(row, EMAIL_FIELDS))
    if mode == "key":
        return any(v == query for _, v in values(row, KEY_FIELDS))
    return any(needle in v.lower() for _, v in values(row, NAME_FIELDS))


def references(row):
    return [(f, v) for f, v in values(row, REFERENCE_FIELDS) if needle and needle in v.lower()]


findings = []
for path in paths:
    try:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
    except Exception as exc:                      # noqa: BLE001
        print(f"  skipped {path}: {exc}", file=sys.stderr)
        continue

    app = (doc.get("manifest") or {}).get("app") or path
    for table, rows in doc.items():
        if table == "manifest" or not isinstance(rows, list):
            continue
        for i, row in enumerate(rows):
            if not isinstance(row, dict):
                continue
            if matches(row):
                findings.append({
                    "app": app, "file": path, "table": table, "index": i,
                    "kind": "record",
                    "person_key": row.get("person_key"),
                    "email": next((v for _, v in values(row, EMAIL_FIELDS)), None),
                    "name": " ".join(v for _, v in values(row, ("first_name", "last_name"))) or None,
                })
            else:
                for field, value in references(row):
                    findings.append({
                        "app": app, "file": path, "table": table, "index": i,
                        "kind": "reference", "field": field, "value": value,
                        "in_record_of": next((v for _, v in values(row, EMAIL_FIELDS)), None),
                    })

if as_json:
    print(json.dumps({"query": {"mode": mode, "value": query}, "findings": findings}, indent=2))
    raise SystemExit(0 if findings else 1)

if not findings:
    print(f"\nNot found: {mode}={query!r} in {len(paths)} file(s).")
    raise SystemExit(1)

records = [f for f in findings if f["kind"] == "record"]
refs = [f for f in findings if f["kind"] == "reference"]

# No escape codes here: this block is piped and redirected far more often
# than it is read on a terminal, and a stray \033[1m in a saved report is
# worse than plain text on screen.
print(f"\n{query} — {len(records)} record(s), "
      f"{len(refs)} reference(s) in other rows\n")
for f in records:
    who = f["name"] or f["email"] or "?"
    key = f" person_key={f['person_key']}" if f.get("person_key") else ""
    print(f"  {f['app']:22} {f['table']:18} [{f['index']}]  {who}{key}")

if refs:
    print("\n  Named inside other people's records — these do not disappear when")
    print("  the person's own row is deleted:\n")
    for f in refs:
        owner = f["in_record_of"] or "?"
        print(f"  {f['app']:22} {f['table']:18} [{f['index']}]  {f['field']}={f['value']!r} in the record of {owner}")

print(f"""
{'-' * 68}
To honour a deletion request, remove the records above, then:
  * the Drupal submission (last — until then it is how you find person_key)
  * every backup that still contains them, including last night's

A deletion that leaves the person in a snapshot is not a deletion.""")
PY
