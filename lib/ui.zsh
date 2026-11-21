# command-finder/lib/ui.zsh
#
# Messages and fzf look. When the host shell defines the matching _ui_* helpers
# (_ui_err, _ui_warn, _ui_fzf_opts, _ui_fzf_label, _ui_fzf_tabs, _ui_fzf_keys),
# those are used so command-finder matches the rest of the shell; otherwise the
# built-in fallbacks below are used. The choice is made at call time, so the
# helpers may be loaded before or after this plugin.

typeset -gA CF_UI=(
  r $'\e[0m' b $'\e[1m' grn $'\e[32m' blu $'\e[34m' mag $'\e[35m' cyn $'\e[36m' gry $'\e[90m'
)

# Fallback fzf options; set CF_FZF_OPTS before sourcing the plugin to replace them
(( ${+CF_FZF_OPTS} )) || typeset -ga CF_FZF_OPTS=(
  --cycle --height=80% --reverse
  --border=none --margin=0 --padding=0 --no-separator
  --input-border=rounded --list-border=rounded --preview-border=rounded
  --input-label-pos=3 --list-label-pos=3:bottom --preview-label-pos=-3:bottom
  --highlight-line --pointer='▌' --marker='✓' --prompt='❯ ' --info=inline-right
  --color='input-border:green,list-border:blue,preview-border:cyan,label:-1,info:bright-black'
  --color='hl:blue,hl+:blue,prompt:green,pointer:magenta,marker:magenta,header:bright-black'
  --bind='ctrl-/:toggle-preview,change:first'
  --ansi --header= --no-preview --preview-window=default,nowrap
  --input-label= --list-label= --preview-label=
)

cf::err() {
  if (( $+functions[_ui_err] )); then _ui_err "$@"; else print -ru2 -- "command-finder: $*"; fi
}

cf::warn() {
  if (( $+functions[_ui_warn] )); then _ui_warn "$@"; else print -ru2 -- "command-finder: $*"; fi
}

# fzf options → $reply
cf::fzf_opts() {
  if (( ${+_ui_fzf_opts} )); then reply=( "${_ui_fzf_opts[@]}" ); else reply=( "${CF_FZF_OPTS[@]}" ); fi
}

# Border title ┐text┌: cf::fzf_label <color> <title> → $REPLY (colors: grn, blu, cyn)
cf::fzf_label() {
  (( $+functions[_ui_fzf_label] )) && { _ui_fzf_label "$@"; return; }
  REPLY="$CF_UI[$1]┐$CF_UI[r]$CF_UI[b]$2$CF_UI[r]$CF_UI[$1]┌$CF_UI[r]"
}

# View tabs after the title, current one highlighted: cf::fzf_tabs <color> <title> <current> <views...> → $REPLY
cf::fzf_tabs() {
  (( $+functions[_ui_fzf_tabs] )) && { _ui_fzf_tabs "$@"; return; }
  local c=$1 cur=$3 v out
  cf::fzf_label $c "$2"
  out=$REPLY
  for v in "${@[4,-1]}"; do
    if [[ $v == $cur ]]; then
      out+="$CF_UI[$c]┐$CF_UI[r]$CF_UI[b]$CF_UI[$c]$v$CF_UI[r]$CF_UI[$c]┌$CF_UI[r]"
    else
      out+="$CF_UI[$c]┐$CF_UI[r]$CF_UI[gry]$v$CF_UI[r]$CF_UI[$c]┌$CF_UI[r]"
    fi
  done
  REPLY=$out
}

# Key hints ┐key label┌…: cf::fzf_keys <color> <key> <label> [<key> <label>...] → $REPLY
cf::fzf_keys() {
  (( $+functions[_ui_fzf_keys] )) && { _ui_fzf_keys "$@"; return; }
  local c=$1 out=
  shift
  while (( $# >= 2 )); do
    out+="$CF_UI[$c]┐$CF_UI[r]$CF_UI[b]$CF_UI[mag]$1$CF_UI[r] $2$CF_UI[$c]┌$CF_UI[r]"
    shift 2
  done
  REPLY=$out
}
