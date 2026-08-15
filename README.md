# dotfiles

Personal setup for macOS (zsh + bash). Shell config, CLI scripts, and a
bootstrap script. Everything in `~` is a symlink into this repo, so this
repo is the single source of truth — edit here, commit, and the live
files follow.

## Layout

| Path | Role |
|---|---|
| `setup.sh` | interactive, idempotent bootstrap |
| `.zshenv` | env for every zsh (sources `config/zsh/env.zsh`) |
| `.zprofile` | login shells: brew shellenv, then re-applies `~/.pybin` |
| `.env.sh` | `BASH_ENV` for non-interactive bash |
| `config/zsh/env.zsh` | **shared environment** for zsh + bash: PATH (idempotent), tool flags, keys |
| `.bash_aliases` | aliases/functions shared by zsh and bash |
| `bin/` | CLI scripts (chat-*, helpers); `~/bin` symlinks here |
| `.secrets.example` | template for `~/.secrets` — copy, fill, `chmod 600` |

The Python default is the system interpreter: `~/.pybin` shims shadow
Homebrew's `python3`/`pip3`. Keys live in `~/.secrets` (600), sourced by
`env.zsh` for every shell.

## First-time setup

Prerequisites: git, Homebrew (macOS). Keys are **never** in this repo.

```sh
cd ~
git clone https://github.com/deven367/dotfiles
chmod +x dotfiles/setup.sh
bash dotfiles/setup.sh
```

Then: `vim ~/.secrets` (fill in keys, `chmod 600`), open a new shell.

## Secrets policy

- Real API keys go in `~/.secrets` only — this repo is **public**.
- `~/.secrets` is git-ignored and 600-perm; `.secrets.example` is the committed template.
- Rotate any key that ever lands in a commit, PR, or issue.
