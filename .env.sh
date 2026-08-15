# BASH_ENV for non-interactive bash (agents, scripts): shared environment.
# PATH, keys, and tool flags all come from the same file zsh uses, so bash
# and zsh stay in sync.

[ -f "$HOME/.config/zsh/env.zsh" ] && . "$HOME/.config/zsh/env.zsh"
