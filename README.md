# ezenv

Opt-in shell environment helpers for a fresh Mac. Small zsh features you enable
à la carte — no dotfile spelunking, just `brew install` and one command per
feature you want.

Basically, I don't like typing `3` after `python` or `pip`, and I especially don't
like typing `source .venv/bin/activate`. Let's skip that step.

## Install

```bash
brew tap raocow/tap      # once
brew install ezenv
```

Then enable the features you want (this writes a line to your `~/.zshrc` — an
extra step by design, since you may not want auto-venv in every repo):

```bash
ezenv enable autovenv        # per-repo .venv auto-activation
ezenv enable pyf             # bare python/pip -> python3/pip3
ezenv enable                 # everything
exec zsh                     # apply to the current shell
```

`ezenv status` shows what's enabled; `ezenv disable <feature>` turns one off;
`ezenv doctor` shows the resolved python/pip/venv. (`install`/`uninstall` still
work as aliases for `enable`/`disable`.)

<details>
<summary>Manual / advanced</summary>

`ezenv enable` just appends a `source` line. To wire it up yourself instead:

```sh
eval "$(ezenv init autovenv)"                      # in ~/.zshrc
source "$(brew --prefix)/share/ezenv/ezenv.zsh"    # or source directly (all features)
```
</details>

## Features

| Feature | What it does |
|---|---|
| `autovenv` | On every `cd`, activates the nearest `.venv` found walking up from the current dir, and deactivates on leaving. Opt-in by presence of a `.venv`, so it only fires in repos where you created one. The current directory wins: leaving every `.venv` scope deactivates whatever is active — including a venv auto-activated by your editor. **On `enable`, it offers to turn off VSCode/Cursor's own terminal venv auto-activation** (`python.terminal.activateEnvironment`, user-level) so autovenv is the sole manager and no venv leaks into dirs that have none; `disable` offers to undo it. Edits are backed up (`.ezenv-bak`). |
| `pyf` | Symlinks `python`→`python3` and `pip`→`pip3` in a managed shim dir appended to `PATH`. Real interpreters and active virtualenvs always take precedence. (Formerly `py-fallback`, still accepted as an alias.) |
| `dotenv` | Adds a `dotenv` command that exports a `.env` into the current shell — `dotenv` loads `./.env`, `dotenv path/to/file` a specific one. Shorthand for `set -a; source <file>; set +a`. (A sourced function, not an `ezenv` subcommand — a subprocess can't export back into your shell.) |

## Disable / uninstall

```bash
ezenv disable autovenv    # turn off one feature
ezenv disable all         # remove all ezenv lines from ~/.zshrc
brew uninstall ezenv
```

A feature (or `all`) is required — a bare `ezenv disable` won't wipe everything
by accident. `ezenv disable pyf` also removes its shim dir
(`~/.local/share/ezenv/shims`, override with `EZENV_SHIM_DIR`), leaving nothing behind.

## License

MIT
