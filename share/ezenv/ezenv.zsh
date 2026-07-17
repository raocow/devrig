# ezenv: enable all features at once.
#
#   source "$(brew --prefix)/share/ezenv/ezenv.zsh"
#
# Prefer sourcing the individual feature files if you only want some.

_ezenv_dir="${${(%):-%x}:A:h}"
source "$_ezenv_dir/autovenv.zsh"
source "$_ezenv_dir/pyf.zsh"
source "$_ezenv_dir/envup.zsh"
unset _ezenv_dir
