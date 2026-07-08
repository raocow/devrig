# ezenv: auto-activate the nearest .venv when you cd into a project.
#
# The current directory is the source of truth: cd into a tree that contains
# a .venv and it activates; leave every .venv scope and whatever is active is
# deactivated — including a venv activated elsewhere (e.g. auto-activated by
# your editor). So the venv that's live always matches where you are.
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
    # In a .venv scope — activate it, replacing any other venv that's active.
    if [[ "$VIRTUAL_ENV" != "$venv" ]]; then
      [[ -n "$VIRTUAL_ENV" ]] && deactivate 2>/dev/null
      source "$venv/bin/activate"
    fi
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    # Outside every .venv scope — nothing should stay active, whoever set it.
    deactivate 2>/dev/null
  fi
}

add-zsh-hook chpwd _ezenv_autovenv
_ezenv_autovenv  # run once for the current directory
