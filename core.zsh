# command-finder/core.zsh

(( ${+CF_HISTORY_ONLY_MAX} )) || typeset -gi CF_HISTORY_ONLY_MAX=50

# Merge all sources; command_finder sorts them per view
# Output: score \t order \t key \t type \t name \t desc \t detail \t file \t line \t uses \t insert
# - score: frecency from the selection history, 0 if never selected; order: alias 1 / function 2 / command 3 / history 4
# - key: lowercase name; key notes such as Ctrl-] get a ~ prefix so they sort last in their group
# - history entries that match no alias/function/command (e.g. with arguments) are listed separately, at most CF_HISTORY_ONLY_MAX
# - a catalog line that inserts exactly an alias or function name is a duplicate and is skipped
cf::collect() {
  setopt localoptions extendedglob
  zmodload -F zsh/datetime b:strftime
  local -A score uses known
  local -A order=( alias 1 function 2 command 3 history 4 )
  local n s c l d t name desc detail file line ins key

  cf::history_scores | while IFS=$CF_SEP read -r n s c l; do
    score[$n]=$s
    if (( l )); then
      strftime -s d '%Y-%m-%d' $l
      uses[$n]="selected ${c}× · last $d"
    else
      uses[$n]="selected ${c}×"
    fi
  done

  {
    { cf::source_alias; cf::source_function; cf::source_command } |
    while IFS=$CF_SEP read -r t name desc detail file line; do
      case $t in
        command)
          # Insert up to a [ or < placeholder (preceded by whitespace, so 'ether[20:2]' is kept); leave a space if arguments were cut
          ins=${name%%[[:space:]]##[\[<]*}
          (( $+known[$ins] )) && continue
          [[ $ins != $name ]] && ins+=' '
          ;;
        function)
          ins=$name
          [[ $detail == "$name "* ]] && ins+=' '
          ;;
        *) ins=$name ;;
      esac
      known[$name]=1
      key=${(L)name}
      [[ $name == Ctrl-* ]] && key="~$key"
      print -r -- "${score[$name]:-0}"$'\t'"$order[$t]"$'\t'"$key"$'\t'"$t"$'\t'"$name"$'\t'"$desc"$'\t'"$detail"$'\t'"$file"$'\t'"$line"$'\t'"$uses[$name]"$'\t'"$ins"
    done

    for n in ${(k)score}; do
      (( $+known[$n] )) && continue
      print -r -- "$score[$n]"$'\t'4$'\t'"${(L)n}"$'\t'history$'\t'"$n"$'\t\t\t\t\t'"$uses[$n]"$'\t'"$n"
    done | sort -t $'\t' -k1,1gr | head -n $CF_HISTORY_ONLY_MAX
  }
}

# List only the commands with one prefix, e.g. for a `net` entry point. Usage: cf::group <prefix> [keywords...]
cf::group() {
  # Prefix the keywords (net port → net-port) so name matches rank above description matches
  local q="${(j: :)@[2,-1]}"
  local CF_GROUP=$1 CF_QUERY=${q:+$1-$q}
  command_finder
}

command_finder() {
  emulate -L zsh

  # $WIDGET only exists inside a zle widget; when run as a command, use print -z
  local -i in_zle=${+WIDGET}
  (( in_zle )) && zle -R "  loading..."

  # One list per view; Ctrl-S / Ctrl-R reload the matching file
  # all: aliases, functions and commands (not history-only entries); history: every selected entry
  local dir t result
  dir=$(mktemp -d) || return 1
  {
  cf::collect > $dir/rows || { _ui_err 'cannot read the command catalog'; return 1; }
  # cf::group keeps only the <prefix>-* entries
  if [[ -n ${CF_GROUP-} ]]; then
    $CF_AWK -F '\t' -v p="$CF_GROUP-" 'index($5, p) == 1' $dir/rows > $dir/group
    command mv -f $dir/group $dir/rows
  fi
  # all: grouped alias → function → command, by name within a group (so git-* / net-* stay together)
  # history: selected entries by frecency, ties by type and name
  $CF_AWK -F '\t' '$4 != "history"' $dir/rows |
    LC_ALL=C sort -s -t $'\t' -k2,2n -k3,3 | cut -f4- | cf::render > $dir/all
  $CF_AWK -F '\t' '$10 != ""' $dir/rows |
    LC_ALL=C sort -s -t $'\t' -k1,1gr -k2,2n -k3,3 | cut -f4- | cf::render uses > $dir/history
  for t in alias function command; do
    $CF_AWK -F '\t' -v t=$t '$1 == t' $dir/all > $dir/$t
  done

  result=$(cf::fzf $dir < $dir/all)
  } always {
    command rm -rf -- "$dir"
  }

  # fzf --expect output: line 1 is the key, line 2 the selection
  local -a lines=( "${(@f)result}" )
  local key=$lines[1]
  local -a f=( "${(@ps:\t:)lines[2]}" )   # quotes + @ keep empty fields
  local type=$f[1] name=$f[2] detail=$f[4] cmd=$f[8]

  if [[ -z $name ]]; then
    (( in_zle )) && zle reset-prompt
    return 0
  fi

  # alias: Ctrl-E inserts / Ctrl-Y copies the expansion
  [[ $type == alias && $key == ctrl-[ey] ]] && cmd=$detail

  if [[ $key == ctrl-y ]]; then
    cf::copy "${cmd% }"
    (( in_zle )) && zle reset-prompt
    return 0
  fi

  cf::history_add "$name" || _ui_warn 'cannot record the selection history'

  if [[ $key == ctrl-x ]]; then
    # Run: replace the command line and accept it
    if (( in_zle )); then
      BUFFER=${cmd% }
      zle accept-line
    else
      print -s -- "${cmd% }"
      eval "${cmd% }"
    fi
  elif (( in_zle )); then
    LBUFFER+=$cmd
    zle reset-prompt
  else
    print -z -- "$cmd"
  fi
}
