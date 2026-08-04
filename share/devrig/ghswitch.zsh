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
# Unbound directories: SUGGESTS, never auto-binds. If a directory isn't tied
# to any devrig account but one or more of your already-logged-in gh accounts
# are candidates, a one-line hint is printed (once per directory per shell
# session, not on every cd back into it) naming them — you still run the
# bind yourself, and pick which one if there's more than one. Auto-picking
# would mean silently switching git/gh identity on a guess, which is exactly
# the mistake this feature exists to prevent; with zero candidates it says
# nothing at all.

typeset -gA _devrig_ghswitch_suggested

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

  # Unbound: suggest at most once per directory per shell session — this
  # calls `gh auth status`, which isn't free like the bound-path check above,
  # so it only runs at all once we already know there's no binding.
  [[ -n "${_devrig_ghswitch_suggested[$PWD]:-}" ]] && return 0
  _devrig_ghswitch_suggested[$PWD]=1
  local -a candidates
  candidates=(${(f)"$(devrig account _suggest-for-dir "$PWD" 2>/dev/null)"})
  (( ${#candidates[@]} == 0 )) && return 0
  if (( ${#candidates[@]} == 1 )); then
    print -u2 "devrig: '$PWD' isn't bound to any account, but ${candidates[1]} is logged into gh — bind it? devrig account bind ${candidates[1]} ."
  else
    print -u2 "devrig: '$PWD' isn't bound to any account. Logged into gh: ${(j:, :)candidates} — bind one? devrig account bind <name> ."
  fi
}

autoload -U add-zsh-hook 2>/dev/null
add-zsh-hook chpwd _devrig_ghswitch
_devrig_ghswitch  # run once for the current directory
