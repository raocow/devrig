# devrig: enable all features at once.
#
#   source "$(brew --prefix)/share/devrig/devrig.zsh"
#
# Prefer sourcing the individual feature files if you only want some.

_devrig_dir="${${(%):-%x}:A:h}"
source "$_devrig_dir/autovenv.zsh"
source "$_devrig_dir/pyf.zsh"
source "$_devrig_dir/envup.zsh"
unset _devrig_dir
