#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/bin/focus.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state with spaces"
export HOSTS="$tmp/hosts" FOCUS_NO_SUDO=1
history="$XDG_STATE_HOME/focus/sessions.csv"
printf '127.0.0.1 localhost\n# keep this line\n' > "$HOSTS"
cp "$HOSTS" "$tmp/original"

# Keep DNS changes isolated and use a deterministic clock across midnight.
dscacheutil() { :; }
killall() { :; }
date() {
  case "$*" in
    '-u +%s,%Y-%m-%dT%H:%M:%SZ') printf '%s\n' "$FOCUS_TEST_STAMP" ;;
    '+%s') printf '%s\n' "${FOCUS_TEST_STAMP%%,*}" ;;
    *) command date "$@" ;;
  esac
}
export -f dscacheutil killall date
focus() { /bin/bash "$script" "$@"; }
reject() {
  if focus "$@" > /dev/null 2>&1; then
    printf 'FAIL: focus %s unexpectedly succeeded\n' "$*" >&2
    exit 1
  fi
}

focus status > /dev/null
[[ ! -e $XDG_STATE_HOME ]]
reject off
export FOCUS_TEST_STAMP='1704153000,2024-01-01T23:50:00Z'
focus on > /dev/null
grep -q '^0.0.0.0 reddit.com$' "$HOSTS"
export FOCUS_TEST_STAMP='1704153600,2024-01-02T00:00:00Z'
reject on
[[ $(focus status) == *'600 seconds'* ]]
export FOCUS_TEST_STAMP='1704154500,2024-01-02T00:15:00Z'
focus off > /dev/null
reject off
cmp "$tmp/original" "$HOSTS"

export FOCUS_TEST_STAMP='1704155400,2024-01-02T00:30:00Z'
focus on > /dev/null
export FOCUS_TEST_STAMP='1704156300,2024-01-02T00:45:00Z'
focus off > /dev/null
printf '%s\n' \
  'started_at,ended_at,duration_seconds' \
  '2024-01-01T23:50:00Z,2024-01-02T00:15:00Z,1500' \
  '2024-01-02T00:30:00Z,2024-01-02T00:45:00Z,900' > "$tmp/expected"
cmp "$tmp/expected" "$history"

# An existing block from before tracking was installed must still unblock.
focus on > /dev/null
rm "$XDG_STATE_HOME/focus/active"
focus off > /dev/null 2>&1
cmp "$tmp/original" "$HOSTS"
cmp "$tmp/expected" "$history"

# A failed history write must not unblock sites or discard the active start.
focus on > /dev/null
mv "$history" "$tmp/saved-history"
mkdir "$history"
reject off
[[ -s $XDG_STATE_HOME/focus/active ]]
grep -q '^0.0.0.0 reddit.com$' "$HOSTS"
rmdir "$history"
mv "$tmp/saved-history" "$history"
export FOCUS_TEST_STAMP='1704157200,2024-01-02T01:00:00Z'
focus off > /dev/null
cmp "$tmp/original" "$HOSTS"
printf 'focus session checks passed (midnight, repeated toggles, history failures)\n'
