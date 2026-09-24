# ~/.zprofile — login shells only.
#
# Homebrew must come first (it prepends /opt/homebrew/bin), then re-apply
# ~/.pybin so the system interpreter still shadows brew's python3/pip3.

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Re-apply after brew shellenv: ~/.pybin must precede /opt/homebrew/bin.
export PATH="$HOME/.pybin:$PATH"

# Added by Antigravity CLI installer
export PATH="/Users/deven367/.local/bin:$PATH"
