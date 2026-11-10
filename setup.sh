#!/bin/bash
# Bootstrap for deven367/dotfiles on Omarchy. Interactive and safe to re-run.
# Keep packaged Omarchy defaults; install only user-level configuration.

say()  { printf '\n== %s ==\n' "$*"; }
ask()  { local a; printf '%s [y/N]: ' "$1"; read -r a; [[ $a == [yY]* ]]; }
link() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; echo "  linked $2 -> $1"; }

say "Linking shell configs"
link "$HOME/dotfiles/.bash_aliases" "$HOME/.bash_aliases"
link "$HOME/dotfiles/bin" "$HOME/bin"
link "$HOME/dotfiles/.zshenv" "$HOME/.zshenv"
link "$HOME/dotfiles/.zprofile" "$HOME/.zprofile"
link "$HOME/dotfiles/.env.sh" "$HOME/.env.sh"
link "$HOME/dotfiles/config/zsh/env.zsh" "$HOME/.config/zsh/env.zsh"
link "$HOME/dotfiles/config/shell/path.sh" "$HOME/.config/shell/path.sh"
link "$HOME/dotfiles/config/uwsm/env.d/99-dotfiles-path" "$HOME/.config/uwsm/env.d/99-dotfiles-path"

# Replace uv's generated PATH hooks, not its binaries or installer files.
uv_env='. "$HOME/.local/bin/env"'
uv_env_legacy='. "$HOME/.local/share/../bin/env"'
for startup in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if grep -Fqx -e "$uv_env" -e "$uv_env_legacy" "$startup" 2>/dev/null; then
        startup_tmp=$(mktemp)
        grep -Fvx -e "$uv_env" -e "$uv_env_legacy" "$startup" > "$startup_tmp" || :
        cat "$startup_tmp" > "$startup"
        rm -f "$startup_tmp"
    fi
done

# Run before an existing interactive-only return, then again after mise's
# interactive activation so local launchers retain precedence.
bash_path='[[ -r "$HOME/.config/shell/path.sh" ]] && source "$HOME/.config/shell/path.sh"'
bash_path_early="$bash_path # dotfiles: before interactive guard"
if ! grep -Fqx "$bash_path_early" "$HOME/.bashrc" 2>/dev/null; then
    bashrc_tmp=$(mktemp)
    printf '%s\n' "$bash_path_early" > "$bashrc_tmp"
    [[ ! -f "$HOME/.bashrc" ]] || cat "$HOME/.bashrc" >> "$bashrc_tmp"
    cat "$bashrc_tmp" > "$HOME/.bashrc"
    rm -f "$bashrc_tmp"
fi

bash_secrets='if [[ $- == *i* && -r "$HOME/.secrets" ]]; then source "$HOME/.secrets"; fi'
grep -Fqx "$bash_secrets" "$HOME/.bashrc" 2>/dev/null ||
    printf '\n%s\n' "$bash_secrets" >> "$HOME/.bashrc"

bash_aliases='[[ $- == *i* && -f ~/.bash_aliases ]] && source ~/.bash_aliases'
grep -Fqx "$bash_aliases" "$HOME/.bashrc" 2>/dev/null ||
    printf '\n%s\n' "$bash_aliases" >> "$HOME/.bashrc"

bash_path_late="$bash_path # dotfiles: after tool initialization"
grep -Fqx "$bash_path_late" "$HOME/.bashrc" 2>/dev/null ||
    printf '\n%s\n' "$bash_path_late" >> "$HOME/.bashrc"

# Do not create .bash_profile: that would hide an existing .profile.
profile_path='[ ! -r "$HOME/.config/shell/path.sh" ] || . "$HOME/.config/shell/path.sh"'
for startup in "$HOME/.profile" "$HOME/.bash_profile"; do
    [[ "$startup" == "$HOME/.profile" || -f "$startup" ]] || continue
    grep -Fqx "$profile_path" "$startup" 2>/dev/null ||
        printf '\n%s\n' "$profile_path" >> "$startup"
done

say "Secrets"
if [ -f "$HOME/.secrets" ]; then
    echo "  ~/.secrets exists (leave as is)"
else
    cp "$HOME/dotfiles/.secrets.example" "$HOME/.secrets" && chmod 600 "$HOME/.secrets"
    echo "  created ~/.secrets from template — FILL IN THE KEYS, then chmod 600"
fi


if ask "setup miniforge (conda)?"; then
    say "Miniforge"
    curl -fL -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    bash "Miniforge3-$(uname)-$(uname -m).sh"
    rm -f "Miniforge3-$(uname)-$(uname -m).sh"
fi

if ask "create conda 'torch' env (python 3.10)?"; then
    say "conda torch env"
    conda create -yn torch python=3.10
fi

if ask "install/configure vim (amix/vimrc)?"; then
    say "vim"
    if [ ! -d "$HOME/.vim_runtime" ]; then
        git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
    fi
    sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
fi

if ask "install/configure tmux (gpakosz/.tmux)?"; then
    say "tmux"
    if [ ! -d "$HOME/.tmux" ]; then
        git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    fi
    ln -sfn "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

if ask "download yt-dlp to ~/bin?"; then
    say "yt-dlp"
    curl -fL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$HOME/bin/yt-dlp"
    chmod a+rx "$HOME/bin/yt-dlp"
fi

if [ "$SHELL" = "/bin/zsh" ] && ask "install/configure oh-my-zsh?"; then
    say "oh-my-zsh"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

say "Done. Open a new shell."
