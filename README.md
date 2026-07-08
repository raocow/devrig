# ezenv

Opt-in shell environment helpers for a fresh Mac. Small zsh features you enable
à la carte from your `~/.zshrc` — no dotfile spelunking, just `brew install` and
a `source` line for each feature you want.

## Install

```bash
brew tap raocow/tap      # once
brew install ezenv
```

Then add the features you want to `~/.zshrc` (an extra step by design — you may
not want auto-venv in every repo):

```sh
source "$(brew --prefix)/share/ezenv/autovenv.zsh"     # per-repo .venv auto-activation
source "$(brew --prefix)/share/ezenv/py-fallback.zsh"  # bare python/pip -> python3/pip3
```

Or enable everything:

```sh
source "$(brew --prefix)/share/ezenv/ezenv.zsh"
```

`ezenv init <feature>` prints the exact line; `ezenv doctor` shows current status.

## Features

| Feature | What it does |
|---|---|
| `autovenv` | On every `cd`, activates the nearest `.venv` found walking up from the current dir, and deactivates on leaving. Opt-in by presence of a `.venv`, so it only fires in repos where you created one. Never touches a venv you activated by hand. |
| `py-fallback` | Symlinks `python`→`python3` and `pip`→`pip3` in a managed shim dir appended to `PATH`. Real interpreters and active virtualenvs always take precedence. |

## Uninstall / disable

Remove the `source` lines from `~/.zshrc`, then `brew uninstall ezenv`.
`py-fallback` shims live in `~/.local/share/ezenv/shims` (override with `EZENV_SHIM_DIR`).

## License

MIT
