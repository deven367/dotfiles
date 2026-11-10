#!/usr/bin/env bash
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.local/bin" "$home/bin" "$home/tool bin"
printf '#!/bin/sh\nprintf "local\\n"\n' > "$home/.local/bin/path-check"
printf '#!/bin/sh\nprintf "fallback\\n"\n' > "$home/tool bin/path-check"
chmod +x "$home/.local/bin/path-check" "$home/tool bin/path-check"

# Exercise the POSIX helper with duplicate, legacy, empty, and spaced entries.
HOME="$home" PATH="$home/tool bin:$home/.local/share/../bin:/usr/bin:$home/tool bin::$home/.local/bin:/usr/bin:" /bin/sh -c '
  set -eu
  repo=$1
  set -- first "second value"
  . "$repo/config/shell/path.sh"
  expected="$HOME/.local/bin:$HOME/tool bin:/usr/bin:$HOME/.local/share/mise/shims:$HOME/bin"
  [ "$PATH" = "$expected" ]
  [ "$(path-check)" = local ]
  . "$repo/config/shell/path.sh"
  [ "$PATH" = "$expected" ]
  [ "$#" = 2 ] && [ "$1" = first ] && [ "$2" = "second value" ]
' sh "$repo"

printf 'PATH behavior checks passed\n'
