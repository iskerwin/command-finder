# command-finder/sources/function.zsh

cf::source_function() {
  local file="$HOME/.config/shell/functions.zsh"
  [[ -f "$file" ]] || return

  awk '
  /^[[:space:]]*#[[:space:]]*@desc:/ {
    sub(/^[[:space:]]*#[[:space:]]*@desc:[[:space:]]*/, "")
    desc = $0
    next
  }

  /^[[:space:]]*#[[:space:]]*@usage:/ {
    sub(/^[[:space:]]*#[[:space:]]*@usage:[[:space:]]*/, "")
    usage = $0
    next
  }

  /^[[:space:]]*#/ {
    next
  }

  /^[a-zA-Z0-9_-]+[[:space:]]*\(\)/ {
    name = $0
    sub(/[[:space:]]*\(.*/, "", name)
    printf "%s\t%s\t%s\n", name, desc, usage
    desc = ""; usage = ""
    next
  }

  /^function[[:space:]]+[a-zA-Z0-9_-]+/ {
    name = $0
    sub(/^function[[:space:]]+/, "", name)
    sub(/[[:space:]]*\(.*/, "", name)
    printf "%s\t%s\t%s\n", name, desc, usage
    desc = ""; usage = ""
    next
  }

  /^[^#]/ {
    desc = ""; usage = ""
  }
  ' "$file" |
  while IFS=$'\t' read -r name desc usage; do
    cf::format_row 1000 "$name" "$desc" "function" "$usage"
  done
}