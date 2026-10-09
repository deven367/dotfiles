#!/usr/bin/env bash
set -e
if [ -n "${BASH_VERSION:-}" ]; then
  shopt -s expand_aliases
fi
. "$(dirname "$0")/../.bash_aliases"

# Invalid requests must fail before contacting Slurm.
allocated=0
salloc () { allocated=1; }
reject () {
  local result=0
  intq "$@" >/dev/null 2>&1 || result=$?
  if [ "$result" -ne 2 ] || [ "$allocated" -ne 0 ]; then
    printf 'FAIL: invalid request reached Slurm or returned %s: intq %s\n' "$result" "$*" >&2
    exit 1
  fi
}
reject
reject '' 3
reject general
reject general 3 2
reject general 0
reject general -1
reject general 1.5
reject general three
reject h100-single 1
reject h100-single 0 3
reject h100-debug 2 0
reject h100-debug 2 1 extra
printf 'intq invalid-input checks passed\n'
