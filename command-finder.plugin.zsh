# command-finder/command-finder.plugin.zsh

(( $+commands[fzf] )) || return

# Files and directories to scan (directories: every *.zsh below them) for aliases,
# functions with a "# @desc:" comment, and catalog comment lines. Set before sourcing to override.
(( ${#CF_PATHS} )) || typeset -ga CF_PATHS=( ${ZDOTDIR:-$HOME}/.zshrc ${XDG_CONFIG_HOME:-$HOME/.config}/zsh )

() {
  local f
  for f in lib/utils lib/ui-fallback sources/history sources/alias sources/function sources/command ui/fzf core; do
    source "$1/$f.zsh"
  done
} "${0:A:h}"

# Ctrl-G by default; set CF_BINDKEY before sourcing to change it, or CF_BINDKEY='' to bind nothing
if [[ -o interactive && -n ${CF_BINDKEY-^G} ]]; then
  zle -N command_finder
  bindkey "${CF_BINDKEY-^G}" command_finder
fi
