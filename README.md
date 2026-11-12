# dotfiles

Personal setup for Omarchy Linux (Bash, with optional zsh). This branch is
`omarchy`; `main` retains the Mac configuration. Managed shell files in `~`
are symlinks into this repo. `~/.bashrc` stays local; setup adds PATH,
secrets, and alias loaders without replacing its existing configuration.

## Layout

| Path | Role |
|---|---|
| `setup.sh` | interactive, idempotent bootstrap |
| `.zshenv` | env for every zsh (sources `config/zsh/env.zsh`) |
| `.zprofile` | login zsh: reapplies the shared Linux PATH setup |
| `.env.sh` | `BASH_ENV` for non-interactive bash |
| `config/zsh/env.zsh` | shared environment for optional zsh and non-interactive Bash |
| `.bash_aliases` | aliases/functions shared by zsh and bash |
| `bin/` | CLI scripts (chat-*, helpers); `~/bin` symlinks here |
| `.secrets.example` | template for `~/.secrets` — copy, fill, `chmod 600` |
| `config/shell/path.sh` | shared POSIX PATH setup for shells and desktop applications |
| `config/uwsm/env.d/98-dotfiles-bash-env` | exports `BASH_ENV` to the desktop session |
| `config/uwsm/env.d/99-dotfiles-path` | applies PATH after packaged Omarchy/mise desktop setup |

Keys live in `~/.secrets` (600), sourced by `env.zsh` for zsh and for
non-interactive Bash through `BASH_ENV=~/.env.sh`, which `~/.bashrc` and the
UWSM hook export. Interactive Bash loads secrets directly from `~/.bashrc`.

## PATH

`~/.config/shell/path.sh` links to the tracked helper. It puts
`~/.local/bin` first, removes duplicate and empty entries, and removes the
installer spelling `~/.local/share/../bin`. Other entries retain their
order. Omarchy supplies mise shims; `~/bin` is appended when it exists.
The Linux configuration no longer injects macOS paths or Python shims.

Setup loads PATH before Bash's interactive guard and again after interactive
tool initialization. It removes the old uv-generated PATH source lines from
`.bashrc`, `.bash_profile`, and `.profile`, and installs the helper in login
profiles without creating a `.bash_profile` that would hide `.profile`.
The UWSM hook handles future desktop sessions.

For an existing shell, run `source ~/.config/shell/path.sh`; already-running
applications retain their inherited environment. New desktop sessions load
the UWSM hook automatically.

Check normalization and command precedence with `bash tests/test_path.sh`.

## Bash secrets

Secrets load in interactive and non-interactive Bash:

- **Interactive:** `setup.sh` appends a readable-file, interactive-only
  loader to `~/.bashrc`. Interactive Bash ignores `BASH_ENV`, so it needs
  this direct loader.
- **Non-interactive** (`bash -c`, scripts, agents): Bash reads only
  `$BASH_ENV`. `setup.sh` exports `BASH_ENV=~/.env.sh` above `~/.bashrc`'s
  interactive guard (login, TTY, and SSH shells) and links
  `config/uwsm/env.d/98-dotfiles-bash-env` for the desktop session. `.env.sh`
  sources `env.zsh`, which sources `~/.secrets`. Only the path enters the
  session environment; non-Bash GUI processes do not see the keys.

Setup preserves existing configuration and does not duplicate lines on reruns.

Use explicit `export` assignments in `~/.secrets` so child processes inherit
the keys. A missing secrets file is harmless.

For an existing installation, rerun `bash ~/dotfiles/setup.sh`, then open a
new Bash shell or run `source ~/.bashrc` in the current one. Log out and back
in so the desktop session picks up `BASH_ENV`. Check secrets
loading and setup idempotence with `bash tests/test_bash_secrets.sh`.

## First-time setup

Prerequisites: Omarchy, Bash, and git. Keys are **never** in this repo.

```sh
cd ~
git clone --branch omarchy https://github.com/deven367/dotfiles
chmod +x dotfiles/setup.sh
bash dotfiles/setup.sh
```

Then: `vim ~/.secrets` (fill in keys, `chmod 600`), open a new shell.

For Bash, setup appends a guarded `~/.bash_aliases` loader to `~/.bashrc`
without replacing existing configuration or duplicating it on reruns.
On Omarchy, its defaults load first, then your aliases. Existing sessions
can reload with `source ~/.bashrc`. Check setup and startup behavior with
`bash tests/test_bash_startup.sh`.

The Slurm queue shortcut is `sjobs` (`squeue --me --sort=+i`); use it on
a Slurm host. `jobs` stays the shell builtin required by prompt hooks.
If an existing shell still has the old alias, run
`unalias jobs; source ~/.bashrc` once.

## Quartz interactive jobs

Run on Quartz after sourcing `~/.bash_aliases`:

```sh
intq general 3          # CPU session for 3 hours
intq h100-single 1 3    # 1 H100 GPU for 3 hours
intq h100-debug 2 1     # 2 H100 GPUs for 1 hour
```

`intq <partition> <hours>` requests no GPUs. For `h100-single` and
`h100-debug`, use `intq <partition> <gpus> <hours>`. Hours and GPU counts
must be positive integers. Every request uses account `r00117`, one node,
10 tasks per node, and 64 GB RAM. `h100-debug` has a one-hour time limit;
Slurm enforces partition limits and resource availability.

This replaces `intqd`, `intqd2`, and `intqd4`; use `intq h100-debug <gpus> 1`.
Check invalid-input handling with `bash tests/test_intq.sh` or
`zsh tests/test_intq.sh`.

## Secrets policy

- Real API keys go in `~/.secrets` only — this repo is **public**.
- `~/.secrets` is git-ignored and 600-perm; `.secrets.example` is the committed template.
- Rotate any key that ever lands in a commit, PR, or issue.
