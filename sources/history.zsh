# command-finder/sources/history.zsh

(( ${+CF_HISTORY_MAX} )) || typeset -gi CF_HISTORY_MAX=1000

# One line per selection: epoch \t name (lines without an epoch count as unknown time)
cf::history_add() {
  emulate -L zsh
  setopt extendedglob
  zmodload -F zsh/datetime p:EPOCHSECONDS
  local file=$(cf::history_file)
  # Newlines and tabs would break the one-record-per-line format: turn them into spaces, then trim
  local cmd=${${1//[$'\t\n']/ }##[[:space:]]#}
  cmd=${cmd%%[[:space:]]#}
  [[ -z $cmd ]] && return

  # A separate lock file keeps its inode when history is atomically replaced; append and trim hold the same lock
  zmodload zsh/system || return 1
  local lock staged=''
  ( umask 077; mkdir -p "${file:h}" && : >> "$file.lock" ) || return 1
  zsystem flock -t 2 -i 0.01 -f lock "$file.lock" || return 1
  {
    ( umask 077; print -r -- "$EPOCHSECONDS"$'\t'"$cmd" >> "$file" ) || return 1
    local -i n=$(wc -l < "$file")
    if (( n > CF_HISTORY_MAX * 6 / 5 )); then
      staged=$(mktemp "$file.XXXXXX") || return 1
      tail -n $CF_HISTORY_MAX "$file" > "$staged" && command mv -f -- "$staged" "$file"
    fi
  } always {
    [[ -n $staged && -f $staged ]] && command rm -f -- "$staged"
    zsystem flock -u $lock
  }
}

# Frecency: recent selections weigh more (4 within a day, 2 within 7 days, 1 within 30 days, otherwise 0.5)
# Output: name \x1f score \x1f count \x1f last-epoch
cf::history_scores() {
  zmodload -F zsh/datetime p:EPOCHSECONDS
  local file=$(cf::history_file)
  [[ -f $file ]] || return 0

  $CF_AWK -v now=$EPOCHSECONDS -v sep=$CF_SEP '
  {
    i = index($0, "\t")
    if (i && substr($0, 1, i - 1) ~ /^[0-9]+$/) { ts = substr($0, 1, i - 1) + 0; cmd = substr($0, i + 1) }
    else                                         { ts = 0; cmd = $0 }
    age = (now - ts) / 86400
    w = (ts == 0) ? 0.5 : (age < 1) ? 4 : (age < 7) ? 2 : (age < 30) ? 1 : 0.5
    s[cmd] += w; c[cmd]++
    if (ts > l[cmd]) l[cmd] = ts
  }
  END { for (k in s) printf "%s%s%.2f%s%d%s%d\n", k, sep, s[k], sep, c[k], sep, l[k] }
  ' "$file"
}
