# command-finder/ui/fzf.zsh

cf::fzf() {
  local header="
  ╭────────────────────────────••─────────────────────────────╮
  │  󰋚 History              Aliases             󰊕 Functions  │ 
  │  ENTER:insert • CTRL-E:expand alias • CTRL-Y:copy command │ 
  ╰────────────────────────────••─────────────────────────────╯
  "
  fzf \
    --ansi \
    --cycle \
    --height=80% \
    --prompt ' 󰘧 ' \
    --layout=reverse \
    --border=rounded \
    --delimiter=$'\t' \
    --with-nth=2 \
    --expect='ctrl-e,ctrl-y' \
    --preview '
      desc={4}
      type={5}
      usage={6}

      if [[ "$type" == "history" ]]; then
        echo ""
      elif [[ "$type" == "alias" ]]; then
        echo "$desc" | bat --language=zsh --style=plain --color=always
        [[ -n "$usage" ]] && echo -e "\033[38;2;98;114;164m󰙎  $usage\033[0m"
      else
        [[ -n "$usage" ]] && echo "$usage" | bat --language=zsh --style=plain --color=always
        [[ -n "$desc" ]]  && echo -e "\033[38;2;98;114;164m󰙎  $desc\033[0m"
      fi
    ' \
    --preview-window=down:3:wrap \
    --header "$header"
}

cf::render() {
  local width="$1"
  local alias_width="$2"

  awk -F '\t' -v w="$width" -v aw="$alias_width" '
  BEGIN {
    purple = "\033[38;2;189;147;249m"   # #bd93f9  history
    orange = "\033[38;2;255;184;108m"   # #ffb86c  alias
    green  = "\033[38;2;80;250;123m"    # #50fa7b  function
    pink   = "\033[38;2;255;121;198m"   # #ff79c6  arrow
    gray   = "\033[38;2;98;114;164m"    # #6272a4  desc
    reset  = "\033[0m"
  }
  {
    score=$1; name=$2; desc=$3; type=$4; usage=$5

    if (type == "alias") {
      color = orange
      icon  = " "
    } else if (type == "function") {
      color = green
      icon  = "󰊕 "
    } else {
      color = purple
      icon  = "󰋚 "
    }

    if (type == "history" && length(name) > aw) {
      name = substr(name, 1, aw - 1) "…"
    }

    if (desc == "") {
      if (type == "function") {
        display = sprintf("%s%s%s%-*s %s→ %sNo description%s", color, icon, reset, w, name, pink, gray, reset)
      } else {
        display = sprintf("%s%s%s%-*s%s", color, icon, reset, w, name, reset)
      }
    } else {
      display = sprintf("%s%s%s%-*s %s→ %s%s%s", color, icon, reset, w, name, pink, gray, desc, reset)
    }

    printf "%s\t%s\t%s\t%s\t%s\t%s\n", score, display, name, desc, type, usage
  }'
}