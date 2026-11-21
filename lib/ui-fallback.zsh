# zsh-ui fallback v1 — https://github.com/iskerwin/zsh-ui
#
# Tools copy this file unchanged and source it. It defines each zsh-ui name only when that name is
# still missing, so zsh-ui wins whether it loads before or after the tool. Without zsh-ui, tools get
# this plain look: the same functions and arguments, no colors, fzf boxes in the terminal's colors.
# Update the copy by replacing it with the newer version from the zsh-ui repository.

(( $+functions[_ui_palette] )) || _ui_palette() {
    typeset -gA _ui=( r '' b '' it '' fg '' red '' grn '' ylw '' blu '' mag '' cyn '' gry '' )
}
(( $+functions[_ui_pad] )) || _ui_pad() {
    local e= n=$(( $2 - ${(m)#1} ))
    (( n < 1 )) && n=1
    REPLY="$1${(l:n:)e}"
}
(( $+functions[_ui_head] ))  || _ui_head()  { print -r -- "== $1${2:+ › $2} =="; }
(( $+functions[_ui_sect] ))  || _ui_sect()  { print; print -r -- "[$1]${2:+ $2}"; }
(( $+functions[_ui_kv] ))    || _ui_kv()    { _ui_pad "$1" ${_UI_KW:-10}; print -r -- "  $REPLY${2:--}"; }
(( $+functions[_ui_cmd] ))   || _ui_cmd()   { _ui_pad "$1" ${3:-28}; print -r -- "  $REPLY$2"; }
(( $+functions[_ui_ok] ))    || _ui_ok()    { print -r -- "✓ $*"; }
(( $+functions[_ui_step] ))  || _ui_step()  { print -r -- "› $*"; }
(( $+functions[_ui_hint] ))  || _ui_hint()  { print -r -- "  $*"; }
(( $+functions[_ui_warn] ))  || _ui_warn()  { print -ru2 -- "! $*"; }
(( $+functions[_ui_err] ))   || _ui_err()   { print -ru2 -- "✗ $*"; }
(( $+functions[_ui_usage] )) || _ui_usage() { print -ru2 -- "usage: $1${2:+ ${(j: :)@[2,-1]}}"; }
(( $+functions[_ui_confirm] )) || _ui_confirm() {
    local ans
    read -r "ans?? $1 [y/N] " || return 1
    [[ $ans == [yY] ]]
}
(( $+functions[_ui_bar] )) || _ui_bar() {
    local -i p=$1 w=${2:-20} n=$(( $1 * ${2:-20} / 100 ))
    local e=
    (( n > w )) && n=$w
    REPLY="${(l:n::#:)e}${(l:w-n::-:)e} ${(l:3:)p}%"
}
(( $+functions[_ui_size] )) || _ui_size() {
    local -F v=$1
    local -a u=( B K M G T )
    local i=1
    while (( v >= 1024 && i < $#u )); do (( v /= 1024, i++ )); done
    if (( i == 1 )); then printf -v REPLY '%dB' $v; else printf -v REPLY '%.1f%s' $v $u[i]; fi
}

(( ${+_ui_fzf_look} )) || typeset -ga _ui_fzf_look=(
    --cycle --height=80% --reverse --info=inline-right
    --input-border=rounded --list-border=rounded --preview-border=rounded
    --input-label-pos=3 --list-label-pos=3:bottom --preview-label-pos=-3:bottom
    --bind='ctrl-/:toggle-preview,change:first'
)
(( ${+_ui_fzf_inline} )) || typeset -ga _ui_fzf_inline=( --info=inline-right )
(( ${+_ui_fzf_opts} )) || typeset -ga _ui_fzf_opts=(
    "${_ui_fzf_look[@]}"
    --ansi --header= --no-preview --preview-window=default,nowrap
    --input-label= --list-label= --preview-label=
)
(( $+functions[_ui_fzf_label] )) || _ui_fzf_label() { REPLY=" $2 "; }
(( $+functions[_ui_fzf_tabs] )) || _ui_fzf_tabs() {
    local v out=" $2 "
    for v in "${@[4,-1]}"; do
        if [[ $v == $3 ]]; then out+="[$v] "; else out+=" $v  "; fi
    done
    REPLY=$out
}
(( $+functions[_ui_fzf_keys] )) || _ui_fzf_keys() {
    local out=
    shift
    while (( $# >= 2 )); do out+=" $1 $2 "; shift 2; done
    REPLY=$out
}
