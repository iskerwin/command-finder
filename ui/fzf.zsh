# command-finder/ui/fzf.zsh

# 16 ANSI colors, so the list follows the terminal theme
# The list is written to files before fzf reads it, so it is always colored
typeset -gA CF_C=(
  reset  $'\e[0m'
  fg     $'\e[39m'
  purple $'\e[34m'
  pink   $'\e[35m'
  green  $'\e[32m'
  orange $'\e[33m'
  cyan   $'\e[36m'
  dim    $'\e[90m'
)
# Font Awesome icons, present in every Nerd Font
typeset -gA CF_ICON=( alias $'' function $'' command $'' history $'' )
typeset -gA CF_COLOR=( alias orange function green command cyan history purple )

# Second column: alias expansion or function usage; in the history view, selection count and last date
cf::render_col2() {
  if [[ $1 == uses ]]; then
    REPLY=$f[7]
  else case $f[1] in
    alias)    REPLY=$f[4] ;;
    function) REPLY=${${f[4]#$f[2]}# } ;;
    *)        REPLY='' ;;
  esac fi
}

# Truncate to $2 columns with …, then pad to the display width (CJK counts as 2)
cf::fit() {
  if (( ${(m)#1} > $2 )); then REPLY="${(mr:$2-1:)1}…"; else REPLY=${(mr:$2:)1}; fi
}

# Input: type \t name \t desc \t detail \t file \t line \t uses \t insert (sorted)
# Output: the same fields + \t display
# Columns: icon · name · expansion/usage (dim) · description (last, truncated by fzf)
# fzf only searches display, which holds all three, so each of them is searchable
# $1 = uses: history view, the second column shows the selection count and last date
cf::render() {
  local mode=$1
  local -a rows=( "${(@f)$(cat)}" ) f
  local -i wn=0 wd=0
  local r name col2 desc
  # Column widths follow the longest value, capped; history entries can be long and do not set the name width
  for r in $rows; do
    f=( "${(@ps:\t:)r}" )
    cf::render_col2 $mode
    (( ${(m)#REPLY} > wd )) && wd=${(m)#REPLY}
    [[ $f[1] == history ]] && continue
    (( ${(m)#f[2]} > wn )) && wn=${(m)#f[2]}
  done
  (( wn > 20 )) && wn=20
  (( wn < 12 )) && wn=12
  (( wd > 32 )) && wd=32

  for r in $rows; do
    f=( "${(@ps:\t:)r}" )
    cf::fit "$f[2]" $wn; name=$REPLY
    cf::render_col2 $mode
    col2=''
    (( wd )) && { cf::fit "$REPLY" $wd; col2="  $CF_C[dim]$REPLY$CF_C[reset]"; }
    desc=${f[3]:+$CF_C[fg]$f[3]}
    [[ -z $desc && $f[1] == function ]] && desc="$CF_C[dim]No description"
    print -r -- "$r"$'\t'"$CF_C[$CF_COLOR[$f[1]]]$CF_ICON[$f[1]]$CF_C[reset]  $CF_C[fg]$name$CF_C[reset]$col2${desc:+  $desc$CF_C[reset]}"
  done
}

# Preview card: ▍name › type, source and selection history, description, [section] expansion/usage (highlighted by bat)
typeset -g CF_PREVIEW='
t={1}; name={2}; desc={3}; detail={4}; file={5}; line={6}; uses={7}; ins={8}
R="\033[0m"; B="\033[1m"; BL="\033[34m"; M="\033[35m"; C="\033[36m"; G="\033[90m"
hl() { if command -v bat >/dev/null 2>&1; then bat --language=zsh --style=plain --color=always --paging=never; else cat; fi | sed "s/^/  /"; }
section() { printf "\n${M}[%s]${R}\n" "$1"; }
case $t in
  alias) label=alias ;; function) label=function ;; command) label=command ;; *) label=history ;;
esac
printf "${BL}${B}▍%s${R} ${G}›${R} ${C}%s${R}\n" "$name" "$label"
[ -n "$file" ] && printf "  ${G}%s:%s${R}\n" "$(printf %s "$file" | sed "s|^$HOME|~|")" "$line"
[ -n "$uses" ] && printf "  ${G}%s${R}\n" "$uses"
[ -n "$desc" ] && printf "\n  %s\n" "$desc"
case $t in
  alias)    section "expands to"; printf "%s\n" "$detail" | hl ;;
  function) [ -n "$detail" ] && { section usage; printf "%s\n" "$detail" | hl; } ;;
  command)  section inserts; printf "%s\n" "$ins" | hl ;;
esac
'

# Ctrl-O: open the definition in an editor; files managed by chezmoi open their source file,
# otherwise the next apply would overwrite the edit
# Editor: $VISUAL / $EDITOR, else the first of zed, code, cursor, vi
typeset -g CF_OPEN='
f={5}; l={6}; [ -n "$f" ] || exit 0
s=$(chezmoi source-path "$f" 2>/dev/null) && [ -f "$s" ] && f=$s
ed=${VISUAL:-$EDITOR}
if [ -z "$ed" ]; then
  for c in zed code cursor vi; do command -v $c >/dev/null 2>&1 && { ed=$c; break; }; done
fi
case $ed in
  *code*|*cursor*) $ed -g "$f:$l" ;;
  *subl*|*zed*)    $ed "$f:$l" ;;
  *)               $ed +"$l" "$f" ;;
esac
'

# $1: temporary directory with one list per view (all / alias / function / command / history)
cf::fzf() {
  local dir=$1 v
  # View tabs in the top border: one label per view, swapped together with the list
  local -a views=( All Aliases Functions Commands History )
  # cf::group lists one prefix: the title shows the prefix, without tabs
  for v in $views; do
    if [[ -n ${CF_GROUP-} ]]; then
      _ui_fzf_label grn " $CF_ICON[command]  $CF_GROUP"
    else
      _ui_fzf_tabs grn " $CF_ICON[command]  Command Finder" $v $views
    fi
    print -rn -- "$REPLY" > $dir/label-$v
  done
  # Ctrl-S cycles the type views, Ctrl-R toggles the history view; the prompt records the current view
  # change-input-label goes last in the colon form, so the label needs no escaping
  local cycle='case "$FZF_PROMPT" in
    All*) n=Aliases f=alias ;; Aliases*) n=Functions f=function ;;
    Functions*) n=Commands f=command ;; *) n=All f=all ;;
  esac
  printf "change-prompt(%s ❯ )+reload(cat '"$dir"'/%s)+change-input-label:%s" "$n" "$f" "$(cat '"$dir"'/label-$n)"'
  local hist='case "$FZF_PROMPT" in
    History*) n=All f=all ;; *) n=History f=history ;;
  esac
  printf "change-prompt(%s ❯ )+reload(cat '"$dir"'/%s)+change-input-label:%s" "$n" "$f" "$(cat '"$dir"'/label-$n)"'
  _ui_fzf_keys blu '↵' Insert '^X' Run '^E' Expand '^Y' Copy '^S' Type '^R' History
  local keys=$REPLY
  _ui_fzf_keys cyn '^O' Source '^/' Hide
  local pkeys=$REPLY

  fzf "${_ui_fzf_opts[@]}" --no-hscroll \
    --input-label="$(<$dir/label-All)" \
    --list-label="$keys" \
    --preview-label="$pkeys" \
    --prompt='All ❯ ' \
    --query="${CF_QUERY-}" \
    --ghost='name, description or expansion' \
    --delimiter=$'\t' --with-nth=9 \
    --tiebreak=begin,index \
    --expect=ctrl-e,ctrl-y,ctrl-x \
    --bind="ctrl-s:transform:$cycle" \
    --bind="ctrl-r:transform:$hist" \
    --bind="ctrl-o:execute:$CF_OPEN" \
    --preview="$CF_PREVIEW" \
    --preview-window='right,45%,wrap,<100(down,45%,wrap)' \
    --preview-wrap-sign='   '
}
