#!/usr/bin/env bash
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
unset BASH_ENV DOTFILES_SECRET_CHECK DOTFILES_SECRET_LOADS
ln -s "$repo" "$home/dotfiles"
# No interactive-only return: the secrets loader must guard itself.
printf 'export DOTFILES_STARTUP_CHECK=preserved\n' > "$home/.bashrc"
cat > "$home/.secrets" <<'EOF'
DOTFILES_SECRET_LOADS=$((${DOTFILES_SECRET_LOADS:-0} + 1))
export DOTFILES_SECRET_CHECK=fixture-only
EOF
chmod 600 "$home/.secrets"

# Rerunning setup must preserve existing files and load secrets only once.
for run in 1 2; do
  HOME="$home" SHELL=/bin/bash bash "$repo/setup.sh" </dev/null > "$home/setup.log"
  HOME="$home" bash --noprofile --rcfile "$home/.bashrc" -ic '
    set -eu
    [[ $DOTFILES_STARTUP_CHECK == preserved ]]
    [[ $DOTFILES_SECRET_CHECK == fixture-only ]]
    [[ $DOTFILES_SECRET_LOADS == 1 ]]
    bash --noprofile --norc -c '\''[[ $DOTFILES_SECRET_CHECK == fixture-only ]]'\''
  '
done

# Non-interactive Bash started from an interactive shell loads secrets itself
# through the BASH_ENV that .bashrc exports, not only by inheritance.
env -u BASH_ENV HOME="$home" bash --noprofile --rcfile "$home/.bashrc" -ic '
  set -eu
  [[ $BASH_ENV == "$HOME/.env.sh" ]]
  env -u DOTFILES_SECRET_CHECK -u DOTFILES_SECRET_LOADS bash -c '\''
    [[ $DOTFILES_SECRET_CHECK == fixture-only ]]
  '\''
'

# The desktop session hook gives non-interactive Bash the same secrets.
env -u BASH_ENV HOME="$home" bash --noprofile --norc -c '
  set -eu
  [[ ! -v DOTFILES_SECRET_CHECK ]]
  . "$HOME/.config/uwsm/env.d/98-dotfiles-bash-env"
  [[ $BASH_ENV == "$HOME/.env.sh" ]]
  bash -c '\''[[ $DOTFILES_SECRET_CHECK == fixture-only ]]'\''
'

# Explicitly using .bashrc as BASH_ENV must not source credentials.
HOME="$home" BASH_ENV="$home/.bashrc" bash -c '
  set -eu
  [[ $DOTFILES_STARTUP_CHECK == preserved ]]
  [[ ! -v DOTFILES_SECRET_CHECK && ! -v DOTFILES_SECRET_LOADS ]]
'

# Missing credentials must not prevent an interactive shell from starting.
rm "$home/.secrets"
HOME="$home" bash --noprofile --rcfile "$home/.bashrc" -ic '
  set -eu
  [[ $DOTFILES_STARTUP_CHECK == preserved ]]
  [[ ! -v DOTFILES_SECRET_CHECK && ! -v DOTFILES_SECRET_LOADS ]]
'
HOME="$home" BASH_ENV="$home/.env.sh" bash -c '
  set -eu
  [[ ! -v DOTFILES_SECRET_CHECK && ! -v DOTFILES_SECRET_LOADS ]]
'
printf 'Bash secrets checks passed\n'
