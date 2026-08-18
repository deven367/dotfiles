# ~/.config/zsh/env.zsh — shared environment for zsh and bash.
#
# Sourced from:
#   ~/.zshenv   — every zsh (login, interactive, scripts)
#   ~/.zprofile — login zsh
#   ~/.env.sh   — non-interactive bash (BASH_ENV)
#
# POSIX-compatible and idempotent: safe to source repeatedly.
# lair: Ubuntu + SLURM (partition `general`, account cogneuroai). No
# Homebrew — toolchains come from environment-modules. /scratch mounts
# only on compute nodes, so cache-dir exports are guarded by dir checks.
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
# --- python ---
# No Homebrew here, so no ~/.pybin shims are needed (setup.sh still
# creates them for mac parity; they are not prepended). Toolchain python
# comes from `module load python` (~/.modules) or /usr/bin/python3.
# --- environment modules (SLURM cluster toolchains) ---
# Sourced for every shell so `module` works in scripts too. Module loads
# prepend PATH, so e.g. `module load python` (from ~/.modules) shadows the
# ~/.pybin shims — same precedence as before.
if [ -f /etc/profile.d/modules.sh ]; then
    . /etc/profile.d/modules.sh
    [ -f "$HOME/.modules" ] && . "$HOME/.modules"
fi
# --- scratch cache (/scratch mounts on compute nodes only) ---
if [ -d /scratch/local/demistry ]; then
    export PIP_CACHE_DIR=/scratch/local/demistry/.cache/pip
    export UV_CACHE_DIR=/scratch/local/demistry/.cache/uv
    export HF_HOME=/scratch/local/demistry/.cache/huggingface
    export UV_LINK_MODE=copy
fi
# --- llama.cpp runtime libs (idempotent; nested shells re-source env.zsh) ---
if [ -d "$HOME/llama.cpp/build" ]; then
  case ":$LD_LIBRARY_PATH:" in
    *":$HOME/llama.cpp/build:"*) ;;
    *) export LD_LIBRARY_PATH="$HOME/llama.cpp/build${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
  esac
fi
# --- user/app bins (appended; lowest priority) ---
_path_append "$HOME/bin"
_path_append "$HOME/.local/bin"
