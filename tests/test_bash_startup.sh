#!/usr/bin/env bash
set -e

repo=$(cd "$(dirname "$0")/.." && pwd)
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
ln -s "$repo" "$home/dotfiles"
printf '[[ $- != *i* ]] && return\nexport DOTFILES_STARTUP_CHECK=preserved\n' > "$home/.bashrc"
mkdir -p "$home/.local/bin" "$home/.local/share"
printf 'export PATH="$HOME/.local/share/../bin:$PATH"\n' > "$home/.local/bin/env"
printf '. "$HOME/.bashrc"\n. "$HOME/.local/share/../bin/env"\n' > "$home/.bash_profile"
printf '. "$HOME/.local/bin/env"\n' > "$home/.profile"

# Setup must preserve existing configuration and work when run again.
for run in 1 2; do
  env -u BASH_ENV HOME="$home" SHELL=/bin/bash bash "$repo/setup.sh" </dev/null > "$home/setup.log"
  env -u BASH_ENV HOME="$home" bash --noprofile --rcfile "$home/.bashrc" -ic '
    set -e
    [[ $DOTFILES_STARTUP_CHECK == preserved ]]
    alias gs >/dev/null
    declare -F gadd >/dev/null
  '
  # Old installer hooks in login profiles must not undo the Bash PATH setup.
  for profile in .bash_profile .profile; do
    env -u BASH_ENV HOME="$home" PATH=/usr/bin bash --noprofile --norc -c '
      . "$HOME/$1"
      [[ ${PATH%%:*} == "$HOME/.local/bin" ]] || exit 1
      [[ ":$PATH:" != *":$HOME/.local/share/../bin:"* ]]
    ' bash "$profile"
  done
done

# PATH must work before the non-interactive guard, without loading aliases.
mkdir -p "$home/.local/bin"
printf '#!/bin/sh\nprintf "startup-path-ok\\n"\n' > "$home/.local/bin/startup-path-check"
chmod +x "$home/.local/bin/startup-path-check"
HOME="$home" PATH=/usr/bin BASH_ENV="$home/.bashrc" bash -c '
  [[ $(startup-path-check) == startup-path-ok ]] || exit 1
  ! declare -F gadd >/dev/null
'
printf 'Bash startup checks passed\n'
