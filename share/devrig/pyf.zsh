# devrig: make bare `python`/`pip` resolve to python3/pip3.
#
# Homebrew (and modern macOS) only ship the *3 names; this creates shims
# in a managed dir and appends it to PATH as a LAST resort, so:
#   - an active virtualenv's own python/pip always win (they're earlier on PATH)
#   - a real `python` from pyenv/conda/etc. still wins
#   - the shim only kicks in when nothing else provides the bare name
#
# Enable by adding to ~/.zshrc:
#   source "$(brew --prefix)/share/devrig/py-fallback.zsh"

_devrig_shim_dir="${DEVRIG_SHIM_DIR:-${EZENV_SHIM_DIR:-$HOME/.local/share/devrig/shims}}"
mkdir -p "$_devrig_shim_dir"

if command -v python3 >/dev/null 2>&1; then
  ln -sf "$(command -v python3)" "$_devrig_shim_dir/python"
fi
if command -v pip3 >/dev/null 2>&1; then
  ln -sf "$(command -v pip3)" "$_devrig_shim_dir/pip"
fi

# Append (not prepend) so real interpreters and venvs take precedence.
case ":$PATH:" in
  *":$_devrig_shim_dir:"*) ;;
  *) export PATH="$PATH:$_devrig_shim_dir" ;;
esac

unset _devrig_shim_dir
