# ezenv: `envup` — export a .env file into the current shell.
#
#   envup                load ./.env
#   envup path/to/file   load a specific file
#
# Shorthand for `set -a; source <file>; set +a` — every assignment in the file
# is exported into your environment. Must run in your shell (that's why it's a
# sourced function, not an `ezenv` subcommand — a subprocess can't export back).
envup() {
  local f="${1:-.env}"
  if [[ ! -f "$f" ]]; then
    echo "envup: no such file: $f" >&2
    return 1
  fi
  set -a
  source "$f"
  set +a
}
