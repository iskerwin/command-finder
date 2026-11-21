# command-finder/command-finder.plugin.zsh

# cf-doctor and the plain look load first, so cf-doctor works even when fzf is missing or too old
() { local f; for f in lib/utils lib/ui-fallback lib/doctor; do source "$1/$f.zsh"; done; } "${0:A:h}"

# fzf is required: without it, say so in interactive shells and load nothing else
if (( ! $+commands[fzf] )); then
  if [[ -o interactive ]]; then
    cf::install_hint fzf
    print -ru2 -- "command-finder: needs fzf — $REPLY (cf-doctor checks everything)"
  fi
  return
fi

# Files and directories to scan (directories: every *.zsh below them) for aliases,
# functions with a "# @desc:" comment, and catalog comment lines. Set before sourcing to override.
(( ${#CF_PATHS} )) || typeset -ga CF_PATHS=( ${ZDOTDIR:-$HOME}/.zshrc ${XDG_CONFIG_HOME:-$HOME/.config}/zsh )

() {
  local f
  for f in sources/history sources/alias sources/function sources/command ui/fzf core; do
    source "$1/$f.zsh"
  done
} "${0:A:h}"

# fzf 0.58+ (input / list / preview boxes); newer options are added only when present
if ! _ui_fzf_since 0.58; then
  if [[ -o interactive ]]; then
    _ui_fzf_ver
    print -ru2 -- "command-finder: needs fzf 0.58 or newer, found $(( REPLY / 1000000 )).$(( REPLY / 1000 % 1000 )).$(( REPLY % 1000 )) — ${${commands[brew]:+brew upgrade fzf}:-https://github.com/junegunn/fzf/releases} (cf-doctor checks everything)"
  fi
  return
fi

# Ctrl-G by default; set CF_BINDKEY before sourcing to change it, or CF_BINDKEY='' to bind nothing
if [[ -o interactive && -n ${CF_BINDKEY-^G} ]]; then
  zle -N command_finder
  bindkey "${CF_BINDKEY-^G}" command_finder
fi
