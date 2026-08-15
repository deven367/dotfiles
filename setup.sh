#!/bin/bash
# Bootstrap for deven367/dotfiles. Interactive; safe to re-run (idempotent).
# macOS-oriented: expects Homebrew, git, and a zsh or bash shell.

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

say "Secrets"
if [ -f "$HOME/.secrets" ]; then
    echo "  ~/.secrets exists (leave as is)"
else
    cp "$HOME/dotfiles/.secrets.example" "$HOME/.secrets" && chmod 600 "$HOME/.secrets"
    echo "  created ~/.secrets from template — FILL IN THE KEYS, then chmod 600"
fi

say "Python default (system interpreter via ~/.pybin shims)"
mkdir -p "$HOME/.pybin"
ln -sfn /usr/bin/python3 "$HOME/.pybin/python3"
ln -sfn /usr/bin/pip3 "$HOME/.pybin/pip3"
printf '#!/bin/sh\nexec -a python3 /usr/bin/python3 "$@"\n' > "$HOME/.pybin/python"
printf '#!/bin/sh\nexec -a pip3 /usr/bin/pip3 "$@"\n' > "$HOME/.pybin/pip"
chmod +x "$HOME/.pybin/python" "$HOME/.pybin/pip"
echo "  ~/.pybin: python/python3 -> /usr/bin/python3, pip/pip3 -> /usr/bin/pip3"

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
