# ezenv: auto-activate the nearest .venv when you cd into a project.
#
# Opt-in by presence of a .venv — it only activates in repos where you
# actually created one, and deactivates again when you leave. It never
# touches a venv you activated yourself by hand.
#
# Enable by adding to ~/.zshrc:
#   source "$(brew --prefix)/share/ezenv/autovenv.zsh"

autoload -U add-zsh-hook 2>/dev/null

_ezenv_autovenv() {
  # Walk up from $PWD looking for the nearest .venv/bin/activate.
  local d="$PWD" venv=""
  while [[ -n "$d" ]]; do
    if [[ -f "$d/.venv/bin/activate" ]]; then venv="$d/.venv"; break; fi
    [[ "$d" == "/" ]] && break
    d="${d:h}"
  done

  if [[ -n "$venv" ]]; then
    if [[ "$VIRTUAL_ENV" != "$venv" ]]; then
      # Swap out only a venv we auto-activated; leave manual ones alone.
      [[ -n "$_EZENV_AUTO_VENV" ]] && deactivate 2>/dev/null
      source "$venv/bin/activate"
      _EZENV_AUTO_VENV="$venv"
    fi
  elif [[ -n "$_EZENV_AUTO_VENV" ]]; then
    deactivate 2>/dev/null
    _EZENV_AUTO_VENV=""
  fi
}

add-zsh-hook chpwd _ezenv_autovenv
_ezenv_autovenv  # run once for the current directory
