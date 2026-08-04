# devrig

Opt-in shell environment helpers for a fresh Mac. Small zsh features you enable
à la carte — no dotfile spelunking, just `brew install` and one command per
feature you want.

Basically, I don't like typing `3` after `python` or `pip`, and I especially don't
like typing `source .venv/bin/activate`. Let's skip that step.

## Install

```bash
brew tap raocow/tap      # once
brew install devrig
```

Then enable the features you want (this writes a line to your `~/.zshrc` — an
extra step by design, since you may not want auto-venv in every repo):

```bash
devrig enable autovenv        # per-repo .venv auto-activation
devrig enable pyf             # bare python/pip -> python3/pip3
devrig enable                 # everything
exec zsh                     # apply to the current shell
```

`devrig status` shows what's enabled; `devrig disable <feature>` turns one off;
`devrig doctor` shows the resolved python/pip/venv. (`install`/`uninstall` still
work as aliases for `enable`/`disable`.)

<details>
<summary>Manual / advanced</summary>

`devrig enable` just appends a `source` line. To wire it up yourself instead:

```sh
eval "$(devrig init autovenv)"                      # in ~/.zshrc
source "$(brew --prefix)/share/devrig/devrig.zsh"    # or source directly (all features)
```
</details>

## Features

| Feature | What it does |
|---|---|
| `autovenv` | On every `cd`, activates the nearest `.venv` found walking up from the current dir, and deactivates on leaving. Opt-in by presence of a `.venv`, so it only fires in repos where you created one. The current directory wins: leaving every `.venv` scope deactivates whatever is active — including a venv auto-activated by your editor. **On `enable`, it offers to turn off VSCode/Cursor's own terminal venv auto-activation** (`python.terminal.activateEnvironment`, user-level) so autovenv is the sole manager and no venv leaks into dirs that have none; `disable` offers to undo it. Edits are backed up (`.devrig-bak`). |
| `pyf` | Symlinks `python`→`python3` and `pip`→`pip3` in a managed shim dir appended to `PATH`. Real interpreters and active virtualenvs always take precedence. (Formerly `py-fallback`, still accepted as an alias.) |
| `envup` | Adds an `envup` command that exports a `.env` into the current shell — `envup` loads `./.env`, `envup path/to/file` a specific one. Shorthand for `set -a; source <file>; set +a`. (A sourced function, not an `devrig` subcommand — a subprocess can't export back into your shell. Named `envup`, not `dotenv`, to avoid shadowing the python-dotenv CLI.) |
| `ghswitch` | On every `cd`, switches the GitHub CLI's (`gh`) active account to match whichever [account](#accounts) is bound to the directory you're in (needs `--gh-user` set on that account — see below). `gh`'s active account is a single setting shared by *every* terminal and session on the machine, so anything else using a different identity anywhere can silently flip it out from under you; this corrects it each time you `cd`, instead of leaving you to hit a confusing "Unauthorized" error and fix it by hand. Reads `gh`'s own local config directly (no network call), so a plain `cd` elsewhere costs nothing. **Not included in `devrig enable` (bare or `all`)** — unlike the other three, it's global cross-session state, not a local shell convenience, so it's opt-in by name: `devrig enable ghswitch`. |

## Accounts

Two git accounts — yours and an employer's — normally means remembering to set
`user.email` per clone and juggling ssh keys by hand. Set it up once per account
and it's automatic per directory after that:

```bash
devrig account add work --email me@work.com --dir ~/code/work
# paste the printed key into that host account, then clone via the alias:
git clone git@github.com-work:acme/api.git ~/code/work/api
devrig account check     # confirm it actually applies
```

Every repo under `~/code/work` now commits as `work` and reaches the host with
`work`'s key. Nothing is sourced into your shell — git reads `includeIf` and ssh
reads the `Host` alias on their own, so this is just config plus a keypair.
devrig only ever *appends*, wrapped in `BEGIN`/`END` sentinel comments, and never
clobbers an existing key, host block, or identity file.

| Command | What it does |
|---|---|
| `account add <name> --email <e>` | Keypair + ssh `Host <host>-<name>` alias + `~/.gitconfig-<name>`. `--name` sets the git name (default: account name), `--host` the host (default: `github.com`), `--dir` binds in the same step, `--gh-user <username>` pairs it with a `gh` CLI login for the `ghswitch` feature. Prints the public key to paste into the host. |
| `account bind <name> <dir>` | Use that identity in `<dir>` and below. The directory doesn't have to exist yet. If you're standing inside it and the account has a `--gh-user`, `ghswitch`'s effect applies immediately instead of waiting for the next `cd`. |
| `account list` | Accounts, emails, and bound directories. |
| `account key <name>` | Reprint the public key — for pasting into the host, or authorizing it against an SSO-enforcing org. |
| `account check` | **The one worth running.** Verifies every binding still applies (plus, for any account with `--gh-user`, that it's actually logged in to `gh`); non-zero exit if not. |

`check` earns its keep because the main failure mode is silent: rename or move a
bound directory and its `includeIf` points at a path that's gone, so git quietly
falls back to your global identity and the wrong name lands on every commit with
no error anywhere. Where a repo exists under a binding, `check` proves end to end
that git really resolves the expected address.

Keys are generated without a passphrase — this is a convenience tool, and a
passphrase would need agent plumbing on every clone. They're protected by file
permissions only. Overrides for testing: `DEVRIG_SSH_CONFIG`, `DEVRIG_GITCONFIG`,
`DEVRIG_SSH_KEY_DIR`.

## Disable / uninstall

```bash
devrig disable autovenv    # turn off one feature
devrig disable all         # remove all devrig lines from ~/.zshrc
brew uninstall devrig
```

A feature (or `all`) is required — a bare `devrig disable` won't wipe everything
by accident. `devrig disable pyf` also removes its shim dir
(`~/.local/share/devrig/shims`, override with `DEVRIG_SHIM_DIR`), leaving nothing behind.

## License

MIT
