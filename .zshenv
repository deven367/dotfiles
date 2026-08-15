# ~/.zshenv — environment for every zsh (login, interactive, scripts).
#
# Only environment lives here; interactive configuration belongs in .zshrc.
# Shared env (PATH, keys, tool flags) lives in ~/.config/zsh/env.zsh so
# scripts get PATH/keys without paying the oh-my-zsh startup cost.

[ -f "$HOME/.config/zsh/env.zsh" ] && . "$HOME/.config/zsh/env.zsh"

# Non-interactive bash reads only $BASH_ENV; point it at the shared env file.
export BASH_ENV="${BASH_ENV:-$HOME/.env.sh}"
