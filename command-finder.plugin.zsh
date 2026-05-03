# command-finder/command-finder.plugin.zsh

(( $+commands[fzf] )) || return

source "${0:A:h}/lib/utils.zsh"
source "${0:A:h}/lib/format.zsh"
source "${0:A:h}/sources/history.zsh"
source "${0:A:h}/sources/alias.zsh"
source "${0:A:h}/sources/function.zsh"
source "${0:A:h}/ui/fzf.zsh"
source "${0:A:h}/core.zsh"

alias af='command_finder'

if [[ -n $ZLE ]]; then
  zle -N command_finder_widget command_finder
  bindkey '^F' command_finder_widget
fi