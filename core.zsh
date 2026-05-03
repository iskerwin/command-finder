# command-finder/core.zsh

command_finder() {
  emulate -L zsh

  if [[ -n $ZLE ]]; then
    zle -R "  loading..."
  fi

  local input result cmd
  input=$(
    cf::source_history
    cf::source_alias
    cf::source_function
  )

  local sorted width alias_width
  sorted=$(print -r -- "$input" | sort -t $'\t' -k1,1nr)

  alias_width=$(print -r -- "$sorted" | awk -F '\t' '
    $4 == "alias" { l=length($2); if(l>m) m=l }
    END { print m }
  ')

  width=$(print -r -- "$sorted" | awk -F '\t' -v aw="$alias_width" '
    {
      name = $2
      if ($4 == "history" && length(name) > aw) name = substr(name, 1, aw)
      l = length(name)
      if (l > m) m = l
    }
    END { print m }
  ')

  input=$(print -r -- "$sorted" | cf::render "$width" "$alias_width")

  result=$(print -r -- "$input" | cf::fzf)
  [[ -z "$result" ]] && return

  local key=$(print -r -- "$result" | head -1)
  local selected=$(print -r -- "$result" | tail -1)

  cmd=$(print -r -- "$selected" | cut -f3)
  local type=$(print -r -- "$selected" | cut -f5)
  local desc=$(print -r -- "$selected" | cut -f4)

  if [[ "$key" == "ctrl-e" ]]; then
    if [[ "$type" == "alias" ]]; then
      cmd="$desc"
    else
      return
    fi
  elif [[ "$key" == "ctrl-y" ]]; then
    if [[ "$type" == "alias" ]]; then
      cmd="$desc"
    fi
    print -r -- "$cmd" | pbcopy
    return
  fi

  cf::history_add "$cmd"

  if [[ -n $ZLE ]]; then
    LBUFFER+="$cmd"
  else
    print -z "$cmd"
  fi
}