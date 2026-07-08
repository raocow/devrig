# ezenv

Opt-in shell environment helpers for a fresh Mac. Small zsh features you enable
à la carte — no dotfile spelunking, just `brew install` and one command per
feature you want.

## Install

```bash
brew tap raocow/tap      # once
brew install ezenv
```

Then enable the features you want (this writes a line to your `~/.zshrc` — an
extra step by design, since you may not want auto-venv in every repo):

```bash
ezenv install autovenv       # per-repo .venv auto-activation
ezenv install py-fallback    # bare python/pip -> python3/pip3
ezenv install                # everything
exec zsh                     # apply to the current shell
```

`ezenv status` shows what's enabled; `ezenv uninstall <feature>` removes it;
`ezenv doctor` shows the resolved python/pip/venv.

<details>
<summary>Manual / advanced</summary>

`ezenv install` just appends a `source` line. To wire it up yourself instead:

```sh
eval "$(ezenv init autovenv)"                      # in ~/.zshrc
source "$(brew --prefix)/share/ezenv/ezenv.zsh"    # or source directly (all features)
```
</details>

## Features

| Feature | What it does |
|---|---|
| `autovenv` | On every `cd`, activates the nearest `.venv` found walking up from the current dir, and deactivates on leaving. Opt-in by presence of a `.venv`, so it only fires in repos where you created one. Never touches a venv you activated by hand. |
| `py-fallback` | Symlinks `python`→`python3` and `pip`→`pip3` in a managed shim dir appended to `PATH`. Real interpreters and active virtualenvs always take precedence. |

## Uninstall / disable

```bash
ezenv uninstall            # remove all ezenv lines from ~/.zshrc
brew uninstall ezenv
```

`py-fallback` shims live in `~/.local/share/ezenv/shims` (override with `EZENV_SHIM_DIR`).

## License

MIT
