# ~/.config/zsh/env.zsh — shared environment for zsh and bash.
#
# Sourced from:
#   ~/.zshenv   — every zsh (login, interactive, scripts)
#   ~/.zprofile — login zsh, AFTER brew shellenv (so ~/.pybin wins)
#   ~/.env.sh   — non-interactive bash (BASH_ENV)
#
# POSIX-compatible and idempotent: safe to source repeatedly.
# NOTE: platform-specific (macOS / Apple Silicon). Adapt for Linux.

_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1${PATH:+:$PATH}" ;;
  esac
}

_path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="${PATH:+$PATH:}$1" ;;
  esac
}

# --- API keys (chmod 600, never commit) ---
[ -f "$HOME/.secrets" ] && . "$HOME/.secrets"

# --- rust toolchain ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- brew convenience ---
export HOMEBREW_NO_AUTO_UPDATE="1"

# --- node version manager (nvm.sh itself loads in interactive rc files) ---
export NVM_DIR="$HOME/.nvm"

# --- python: system interpreter must shadow brew's python3/pip3 ---
_path_prepend "$HOME/.pybin"

# --- compiler / linker (llvm) ---
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export CMAKE_C_COMPILER=/usr/bin/gcc
export CMAKE_CXX_COMPILER=/usr/bin/g++
_path_prepend "/opt/homebrew/opt/llvm/bin"

# --- tool bins (prepended; later lines win) ---
_path_prepend "$HOME/nvim/bin"
export MODULAR_HOME="$HOME/.modular"
_path_prepend "$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"
_path_prepend "$HOME/.antigravity/antigravity/bin"
_path_prepend "$HOME/.antigravity-ide/antigravity-ide/bin"

# --- user/app bins (appended; lowest priority) ---
_path_append "$HOME/bin"
_path_append "$HOME/.local/bin"
_path_append "$HOME/gh/bin"
_path_append "/Applications/Racket v8.14/bin"
_path_append "/Library/PostgreSQL/17/bin"
_path_append "$HOME/Library/Python/3.9/bin"
_path_append "/Applications/MATLAB_R2024b.app/bin"
_path_append "/Applications/CMake.app/Contents/bin"
_path_append "/Applications/WezTerm.app/Contents/MacOS"
_path_append "/usr/local/go/bin"
_path_append "$HOME/go/bin"
_path_append "/Applications/quarto/bin"
