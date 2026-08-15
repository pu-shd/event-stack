#!/bin/zsh
#
# verify-stack.sh — is this event's stack actually working?
#
# Four questions, asked of every application you name:
#
#   1. Does it answer /healthz?
#   2. Is an anonymous request to an admin route refused?
#   3. Does a webhook with a bad token get rejected?
#   4. Does any public JSON contain an email address?
#
# Read-only. It creates nothing, changes nothing, and needs no credentials —
# so it is safe to run against production, which is the only place worth
# running it.
#
#   ./verify-stack.sh --event caarms-2026
#   ./verify-stack.sh --url https://one-app.azurewebsites.net
#
# With --event it reads the application URLs out of the ledgers under the
# current directory, so it checks what was actually deployed rather than what
# somebody typed on the command line.

set -o pipefail

typeset -g EVENT="" URLS=() FAILED=0 CHECKS=0

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_OK=$'\e[32m'; C_BAD=$'\e[31m'; C_DIM=$'\e[90m'; C_B=$'\e[1m'; C_R=$'\e[0m'
else
  C_OK=""; C_BAD=""; C_DIM=""; C_B=""; C_R=""
fi

usage() {
  print -r -- "usage: verify-stack.sh [--event SLUG] [--url URL]... [--timeout SECONDS]"
  print -r -- ""
  print -r -- "  --event SLUG   read application URLs from .eventkit/state.json ledgers below \$PWD"
  print -r -- "  --url URL      check this URL; repeatable"
  print -r -- "  --timeout N    per-request timeout, default 15"
}

typeset -g TIMEOUT=15
while (( $# )); do
  case "$1" in
    --event)   shift; EVENT="$1" ;;
    --url)     shift; URLS+=("${1%/}") ;;
    --timeout) shift; TIMEOUT="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) print -r -- "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# --------------------------------------------------------------------------
# Discover URLs from the ledgers, so this checks reality rather than intent.
# --------------------------------------------------------------------------
if [[ -n "$EVENT" ]]; then
  local ledger
  for ledger in **/.eventkit/state.json(N); do
    local url
    url="$(python3 - "$ledger" "$EVENT" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as fh:
        doc = json.load(fh)
except Exception:
    raise SystemExit
if doc.get("event") != sys.argv[2]:
    raise SystemExit
name = (doc.get("names") or {}).get("webApp")
if name:
    print(f"https://{name}.azurewebsites.net")
PY
)"
    [[ -n "$url" ]] && URLS+=("$url")
  done
fi

if (( ${#URLS} == 0 )); then
  print -r -- "No applications to check." >&2
  print -r -- "Pass --url, or run --event from a directory containing the app repositories." >&2
  exit 2
fi

# --------------------------------------------------------------------------
say_ok()   { CHECKS=$(( CHECKS + 1 )); print -r -- "    ${C_OK}ok${C_R}    $1"; }
say_bad()  { CHECKS=$(( CHECKS + 1 )); FAILED=$(( FAILED + 1 )); print -r -- "    ${C_BAD}FAIL${C_R}  $1"; }
say_skip() { print -r -- "    ${C_DIM}skip  $1${C_R}"; }

# Status code only, no body.
#
# No `|| print "000"` fallback: on a connection failure curl *already* writes
# 000 and then exits non-zero, so a fallback appends a second 000 and the result
# is "000000" — which matches no case arm, so a dead host was reported as
# quietly passing every admin check. Substituting only when the output is empty
# is the correct shape.
code_for() {
  local out
  out="$(curl -s -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$@" 2>/dev/null)"
  print -r -- "${out:-000}"
}

check_health() {
  local base="$1" code
  code="$(code_for "${base}/healthz")"
  if [[ "$code" == "200" ]]; then
    say_ok "/healthz answers 200"
  else
    say_bad "/healthz answered ${code}"
  fi
}

check_admin_is_closed() {
  # `route`, not `path`: in zsh `path` is the array tied to $PATH, so declaring
  # it local blanks PATH inside the function and every command becomes "not
  # found" — which surfaces here as a uniform "did not answer" against an
  # application that is answering perfectly. Same family as `status`.
  local base="$1" route code
  # A 200 here means an admin surface is open to the internet. 401/403 is the
  # pass; a redirect to the identity provider is also a pass, and 404 means the
  # route does not exist in this application, which is fine.
  for route in /api/admin/db-backup /api/admin/presenters /api/rules /api/reports/registrations; do
    code="$(code_for "${base}${route}")"
    case "$code" in
      200)         say_bad "${route} served 200 to an anonymous request" ;;
      401|403)     say_ok  "${route} refuses anonymous (${code})" ;;
      301|302|307) say_ok  "${route} redirects anonymous to sign-in (${code})" ;;
      404)         : ;;
      000)         say_bad "${route} did not answer" ;;
      *)           say_ok  "${route} did not serve it (${code})" ;;
    esac
  done
}

check_webhook_rejects_a_bad_token() {
  local base="$1" code
  code="$(code_for -X POST "${base}/api/drupal-webhook" \
            -H 'Content-Type: application/json' \
            -H 'X-Drupal-Webhook-Token: definitely-not-the-token' \
            -d '{"data":{"email":"probe@example.invalid"}}')"
  case "$code" in
    401|403) say_ok  "webhook rejects a bad token (${code})" ;;
    404)     say_skip "no webhook on this application" ;;
    200|201) say_bad "webhook ACCEPTED a bad token — anyone can write to this database" ;;
    000)     say_bad "webhook did not answer" ;;
    *)       say_ok  "webhook did not accept it (${code})" ;;
  esac
}

check_public_json_has_no_addresses() {
  local base="$1" route body
  for route in /api/presenters /api/event-profile; do
    body="$(curl -s --max-time "$TIMEOUT" "${base}${route}" 2>/dev/null)" || continue
    [[ -z "$body" ]] && continue
    print -r -- "$body" | head -c 1 | grep -qE '[\[{]' || continue
    # contact_email is public by design and is the only allowed address.
    if print -r -- "$body" | sed 's/"contact_email"[^,}]*//g' | grep -q '@'; then
      say_bad "${route} exposes an address to anonymous callers"
    else
      say_ok "${route} carries no addresses"
    fi
  done
}

# --------------------------------------------------------------------------
print -r -- ""
print -r -- "${C_B}Verifying ${#URLS} application(s)${C_R}"
[[ -n "$EVENT" ]] && print -r -- "${C_DIM}event: ${EVENT}${C_R}"

local base
for base in "${URLS[@]}"; do
  print -r -- ""
  print -r -- "  ${C_B}${base}${C_R}"
  check_health "$base"
  check_admin_is_closed "$base"
  check_webhook_rejects_a_bad_token "$base"
  check_public_json_has_no_addresses "$base"
done

print -r -- ""
if (( FAILED )); then
  print -r -- "${C_BAD}${FAILED} of ${CHECKS} checks failed.${C_R}"
  exit 1
fi
print -r -- "${C_OK}All ${CHECKS} checks passed.${C_R}"
