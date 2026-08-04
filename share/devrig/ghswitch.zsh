# devrig: auto-switch gh's active account when you cd into a directory bound
# to an account with a recorded gh user (devrig account add ... --gh-user
# <username>).
#
# gh's "active account" is a single GLOBAL setting shared by every terminal
# and session on the machine — anything else using a different gh identity
# anywhere (another terminal, another agent session, a script) can silently
# flip it back. This corrects it for wherever you currently are, each time
# you cd, instead of leaving you to notice a confusing "Unauthorized" error
# and fix it by hand.
#
# Only acts entering a bound directory; leaving one does nothing on purpose —
# there's no sane "restore," since the active account is genuinely shared
# global state that this feature can only correct opportunistically, not own.
#
# Reads gh's own local hosts.yml directly (no network call) to see who's
# currently active, so a plain cd into an unrelated directory costs nothing;
# `gh auth switch` only runs when the account actually needs to change.
#
# Enable by adding to ~/.zshrc:
#   source "$(brew --prefix)/share/devrig/ghswitch.zsh"
#
# Unbound directories are bound AUTOMATICALLY, on evidence rather than a
# guess: the reason this feature exists at all is that the accounts differ in
# which repos they can reach, so "which of my accounts can actually push to
# this repo" is a checkable fact. The first account with push access is bound
# and reported, along with how to change it. Nothing happens when no account
# has push access (including every repo you merely have READ on, so a public
# repo you don't own is never auto-bound), or outside a GitHub repo.
#
# The access probe costs a network call per account, so it's gated hard: only
# for a directory already known to be unbound, only inside a git repo with a
# GitHub origin, and only once per directory per shell session.

typeset -gA _devrig_ghswitch_seen

_devrig_ghswitch() {
  command -v gh >/dev/null 2>&1 || return 0
  command -v devrig >/dev/null 2>&1 || return 0

  local want; want="$(devrig account _gh-for-dir "$PWD" 2>/dev/null)"
  if [[ -n "$want" ]]; then
    local hosts="${GH_CONFIG_DIR:-$HOME/.config/gh}/hosts.yml"
    local active; active="$(sed -n 's/^[[:space:]]*user:[[:space:]]*//p' "$hosts" 2>/dev/null | head -1)"
    [[ "$active" == "$want" ]] && return 0
    gh auth switch --user "$want" >/dev/null 2>&1
    return 0
  fi

  # Unbound: bind whichever account can actually push here. At most once per
  # directory per shell session — unlike the bound-path check above, this
  # probe hits the network, so it only runs once we already know there's no
  # binding, and never repeats for the same directory in this shell.
  [[ -n "${_devrig_ghswitch_seen[$PWD]:-}" ]] && return 0
  _devrig_ghswitch_seen[$PWD]=1
  local pick
  pick="$(devrig account _access-for-dir "$PWD" first 2>/dev/null)"
  [[ -n "$pick" ]] || return 0
  # Bind the repo ROOT, not $PWD: the identity belongs to the repository, so
  # binding a subdirectory you happened to be standing in would leave its
  # siblings unbound and re-probing.
  local root; root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  [[ -n "$root" ]] || return 0
  devrig account bind "$pick" "$root" >/dev/null 2>&1 || return 0
  print -u2 "devrig: bound ${root:t} to '$pick' (the account with push access here) — change it with: devrig account bind <name> ${root}"
}

autoload -U add-zsh-hook 2>/dev/null
add-zsh-hook chpwd _devrig_ghswitch
_devrig_ghswitch  # run once for the current directory
