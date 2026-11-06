#!/usr/bin/env bash
# focus.sh — toggle distracting sites via /etc/hosts (macOS).
# usage: focus.sh on|off|status
# Edit SITES to taste. Hosts-file writes and DNS flushing use sudo.
# If blocked sites still load, turn off DNS-over-HTTPS ("Secure DNS") in the
# browser — DoH resolves names itself and bypasses the hosts file.
set -euo pipefail

HOSTS=${HOSTS:-/etc/hosts}   # overridable for dry runs/tests
BEGIN='# BEGIN FOCUS (managed)'
END='# END FOCUS (managed)'
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/focus"
ACTIVE="$STATE_DIR/active"
HISTORY="$STATE_DIR/sessions.csv"

SITES=(
  reddit.com
  twitter.com
  x.com
  facebook.com
  instagram.com
  tiktok.com
  youtube.com
  twitch.tv
  netflix.com
  chess.com
  amazon.com
  linkedin.com
  beeg.com
)

die() { echo "focus: $*" >&2; exit 1; }
blocked() { grep -qF "$BEGIN" "$HOSTS"; }
as_root() {
  if [[ $EUID -eq 0 || -n ${FOCUS_NO_SUDO:-} ]]; then
    "$@"
  else
    sudo -- "$@"
  fi
}
read_start() {
  IFS=, read -r started started_at < "$ACTIVE"
  [[ $started =~ ^[0-9]+$ ]] || die "invalid session start in $ACTIVE"
}
flush_dns() {
  as_root dscacheutil -flushcache 2>/dev/null || true
  as_root killall -HUP mDNSResponder 2>/dev/null || true
}

[[ $# -eq 1 && $1 =~ ^(on|off|status)$ ]] || {
  echo "usage: ${0##*/} on|off|status" >&2
  exit 2
}

if [[ $1 == status ]]; then
  if blocked; then
    printf 'blocked: %s\n' "${SITES[*]}"
    if [[ -s $ACTIVE ]]; then
      read_start
      printf 'focus elapsed: %s seconds\n' "$(( $(date +%s) - started ))"
    fi
  else
    echo 'not blocked'
  fi
  exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Keep everything outside our marker block, drop any stale block.
awk -v b="$BEGIN" -v e="$END" '$0==b{f=1;next} $0==e{f=0;next} !f' "$HOSTS" > "$tmp"

if [[ $1 == on ]]; then
  blocked && die "already blocked (use: ${0##*/} off)"
  {
    echo "$BEGIN"
    for d in "${SITES[@]}"; do
      for h in "$d" "www.$d" "old.$d" "m.$d"; do
        printf '0.0.0.0 %s\n::1 %s\n' "$h" "$h"
      done
    done
    echo "$END"
  } >> "$tmp"
else
  blocked || die "not blocked"
fi

# Check history is writable before changing focus mode.
mkdir -p "$STATE_DIR"
[[ -s $HISTORY ]] || printf 'started_at,ended_at,duration_seconds\n' > "$HISTORY"
: >> "$HISTORY"
if [[ $1 == on ]]; then
  : > "$ACTIVE"
elif [[ -s $ACTIVE ]]; then
  read_start
fi

# tee, rather than mv, preserves /etc/hosts inode and permissions.
as_root tee "$HOSTS" < "$tmp" >/dev/null
if [[ $1 == on ]]; then
  date -u '+%s,%Y-%m-%dT%H:%M:%SZ' > "$ACTIVE"
elif [[ -s $ACTIVE ]]; then
  stamp=$(date -u '+%s,%Y-%m-%dT%H:%M:%SZ')
  IFS=, read -r ended ended_at <<< "$stamp"
  duration=$((ended - started))
  printf '%s,%s,%s\n' "$started_at" "$ended_at" "$duration" >> "$HISTORY"
  rm "$ACTIVE"
  printf 'focus session: %s seconds (saved to %s)\n' "$duration" "$HISTORY"
else
  echo 'focus: no recorded start; no session saved' >&2
fi
flush_dns

[[ $1 == on ]] && echo "distractions blocked: ${SITES[*]}" || echo "distractions unblocked"
