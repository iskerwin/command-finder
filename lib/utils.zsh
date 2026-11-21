# command-finder/lib/utils.zsh

# awk is only used for parsing; display widths are computed in zsh with (m), so CJK alignment does not need gawk
typeset -g CF_AWK=awk
(( $+commands[gawk] )) && CF_AWK=gawk

# Sources separate fields with \x1f: tab is IFS whitespace, so read would merge empty fields
typeset -g CF_SEP=$'\x1f'

cf::history_file() {
  print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/command-finder/history"
}

# Every *.zsh under the CF_PATHS directories, plus CF_PATHS entries that are files (deduplicated)
cf::files() {
  local -aU files
  local d
  for d in $CF_PATHS; do
    if [[ -f $d ]]; then
      files+=( $d )
    else
      files+=( $d/**/*.zsh(N.) )
    fi
  done
  print -rl -- $files
}

# Clipboard: clip-copy if available, then the platform tools, then OSC 52 (works over SSH in most terminals)
cf::copy() {
  if (( $+commands[clip-copy] )); then
    print -rn -- "$1" | clip-copy
  elif (( $+commands[pbcopy] )); then
    print -rn -- "$1" | pbcopy
  elif [[ -n ${WAYLAND_DISPLAY-} ]] && (( $+commands[wl-copy] )); then
    print -rn -- "$1" | wl-copy
  elif [[ -n ${DISPLAY-} ]] && (( $+commands[xclip] )); then
    print -rn -- "$1" | xclip -selection clipboard
  elif [[ -n ${DISPLAY-} ]] && (( $+commands[xsel] )); then
    print -rn -- "$1" | xsel --clipboard --input
  else
    print -rn -- $'\e]52;c;'"$(print -rn -- "$1" | base64 | tr -d '\n')"$'\a' > /dev/tty
  fi
}
