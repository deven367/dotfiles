# Shared environment for optional zsh and non-interactive bash on Omarchy.
# Interactive Bash loads credentials directly, without the rest of this file.
# POSIX-compatible and safe to source repeatedly.

# API keys (chmod 600, never commit).
[ -f "$HOME/.secrets" ] && . "$HOME/.secrets"

# Preserve a Rust installation's own environment setup when present.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
export MODULAR_HOME="$HOME/.modular"
export CMAKE_C_COMPILER=/usr/bin/gcc
export CMAKE_CXX_COMPILER=/usr/bin/g++

# Normalize after any toolchain environment changes.
. "$HOME/.config/shell/path.sh"
